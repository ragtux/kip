#import "lib.typ": kip

#set page(width: 600pt, height: auto, margin: 2cm)

= Kip Plugin Working Examples

== Simple Box and Circle

#kip(```
box "Start"
arrow
circle "End" fit
```)

== Arrow Diagram

#kip(```
arrow right 200% "Markdown" "Source"
box rad 10px "Markdown" "Formatter" fit
arrow right 200% "HTML+SVG" "Output"
```)

== Shapes

#kip(```
box "Box"
move
circle "Circle" fit
move
ellipse "Ellipse" fit
```)

== State Machine

#kip(```
circle "Idle" fit
arrow right 150% "start" above
circle "Active" fit
arrow right 150% "finish" above
circle "Done" fit
```)

Success! The Kip plugin for Typst is working correctly.
