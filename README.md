# Lua2Exe
Pure Lua command-line utilities to convert pure Lua 5.3 source with possible Lua library dependencies to a single file, C, or EXE

Note: Non-Lua (e.g., C language) dependencies are not supported.

* `onelua` converts a pure Lua 5.3 source to a single Lua file without external dependencies.
* `lua2c` does the same as `onelua` but also converts the resulting file to a single file C source ready for compilation.
* `lua2exe` does the same as lua2c but also compiles the resulting C source to an EXE under Windows.

(`cli` and `one` are library dependencies used by the above utililies.)

The utilities have been tested only under Windows, and may require changes for use under Linux.
Standard Lua environment variables will be used unless the `-E` option is used.
