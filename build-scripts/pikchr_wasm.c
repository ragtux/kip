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

/* Import protocol functions from Typst environment */
#define PROTOCOL_FUNCTION __attribute__((import_module("typst_env"))) extern

PROTOCOL_FUNCTION void
wasm_minimal_protocol_send_result_to_host(const uint8_t *ptr, size_t len);

PROTOCOL_FUNCTION void
wasm_minimal_protocol_write_args_to_buffer(uint8_t *ptr);

/**
 * Typst plugin function to render Pikchr diagrams
 * Takes: input_len (length of pikchr markup text)
 * Returns: 0 on success, 1 on error
 */
EMSCRIPTEN_KEEPALIVE
int32_t typst_pikchr(size_t input_len) {
    /* Allocate buffer for input */
    uint8_t *input = (uint8_t *)malloc(input_len + 1);
    if (!input) {
        return 1;
    }

    /* Get the input data from Typst */
    wasm_minimal_protocol_write_args_to_buffer(input);
    input[input_len] = '\0'; /* Null terminate */

    /* Call pikchr to generate SVG */
    int width, height;
    unsigned int flags = 0;
    char *svg = pikchr((const char *)input, "pikchr", flags, &width, &height);

    free(input);

    if (!svg) {
        /* Return error */
        const char error_msg[] = "Pikchr rendering failed";
        wasm_minimal_protocol_send_result_to_host(
            (const uint8_t *)error_msg,
            sizeof(error_msg) - 1
        );
        return 1;
    }

    /* Send SVG result to Typst */
    size_t svg_len = strlen(svg);
    wasm_minimal_protocol_send_result_to_host((const uint8_t *)svg, svg_len);

    free(svg);
    return 0;
}
