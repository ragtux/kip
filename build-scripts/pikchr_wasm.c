/*
** WASM wrapper for pikchr to work as a Typst plugin
** Using the wasm-minimal-protocol
*/

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "emscripten.h"

/* Forward declaration of the pikchr function */
char *pikchr(
  const char *zText,
  const char *zClass,
  unsigned int mFlags,
  int *pnWidth,
  int *pnHeight
);

/* Flag bits for pikchr()'s mFlags argument (must match pikchr.h) */
#define PIKCHR_PLAINTEXT_ERRORS 0x0001
#define PIKCHR_DARK_MODE        0x0002

/* Import protocol functions from Typst environment */
#define PROTOCOL_FUNCTION __attribute__((import_module("typst_env"))) extern

PROTOCOL_FUNCTION void
wasm_minimal_protocol_send_result_to_host(const uint8_t *ptr, size_t len);

PROTOCOL_FUNCTION void
wasm_minimal_protocol_write_args_to_buffer(uint8_t *ptr);

static int32_t send_error(const char *msg) {
    wasm_minimal_protocol_send_result_to_host((const uint8_t *)msg, strlen(msg));
    return 1;
}

/**
 * Read the Pikchr markup from Typst, render it with the given flags and
 * send the SVG back.
 * Returns: 0 on success, 1 on error (the result is then the error message)
 */
static int32_t render(size_t input_len, unsigned int flags) {
    /* Allocate buffer for input */
    uint8_t *input = (uint8_t *)malloc(input_len + 1);
    if (!input) {
        return send_error("Pikchr: out of memory");
    }

    /* Get the input data from Typst */
    wasm_minimal_protocol_write_args_to_buffer(input);
    input[input_len] = '\0'; /* Null terminate */

    /* Call pikchr to generate SVG. On a syntax error pikchr() still returns
    ** text, but it is an error message and the width is negative. */
    int width = 0, height = 0;
    char *out = pikchr((const char *)input, "pikchr",
                       flags | PIKCHR_PLAINTEXT_ERRORS, &width, &height);

    free(input);

    if (!out) {
        return send_error("Pikchr rendering failed");
    }

    wasm_minimal_protocol_send_result_to_host((const uint8_t *)out, strlen(out));
    free(out);
    return width < 0 ? 1 : 0;
}

/**
 * Typst plugin function to render Pikchr diagrams
 * Takes: input_len (length of pikchr markup text)
 */
EMSCRIPTEN_KEEPALIVE
int32_t typst_pikchr(size_t input_len) {
    return render(input_len, 0);
}

/**
 * Same as typst_pikchr(), but with colors inverted for dark backgrounds
 */
EMSCRIPTEN_KEEPALIVE
int32_t typst_pikchr_dark(size_t input_len) {
    return render(input_len, PIKCHR_DARK_MODE);
}
