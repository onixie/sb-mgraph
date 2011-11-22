sb-mgraph shows SBCL's internal memory structure in a visualized way.


2011/11/22 O.Nixie <onixie@gmail.com>
TODO:
  1. Add more primitive objects' memory usage information in the graph
     a. thread object (stack related first)
     b. primitives in readonly/dynamic/static spaces

  2. Refactor code to create a structuralized object tree to record each 
     space/object info and their relationship.

  3. Refactor code to automatic generate drawings by analyzing the object
     tree.

  4. Isolate stylish drawing code out and configurable.
