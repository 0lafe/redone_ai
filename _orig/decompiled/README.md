# Decompiled sources — Reworked Enemy AI (RedFlame)

The shipped `*.lua` files (now in `_orig/bytecode/`) are **not obfuscated**; they are
stripped LuaJIT 2.1 bytecode dumps:

    1B 4C 4A 02 02   ->  "\x1bLJ", version 2 (LuaJIT 2.1), flags = BCDUMP_F_STRIP

i.e. produced with `luajit -b -s file.lua out.lua` (or `string.dump(f, true)`).
Stripping removes local variable names and line numbers only; every string,
number, global/field name, upvalue and the full control flow survives.

The files in this folder are the raw decompiler output (the cleaned, renamed versions live in `lua/`), recovered with
`tools/luajit-decompiler/luajit-decompiler-v2.exe` (marsinator358, release
Mar_24_2024) and all 38 parse as valid Lua. `copbase.lua` was already plain
text and is copied unchanged.

Naming convention in the output (from the decompiler, since names were lost):
`arg_F_N` = parameter N of function F, `var_F_N` = local, `iter_F_N` = loop
variable, `var_0_N` = file-level local (e.g. `var_0_0 = math.lerp`). `arg_F_0`
in a method is `self`.

Note: `mod.txt` hooks `copactionshoot.lua` and `coplogicattack.lua`, which are
not present in the distributed mod (BLT silently skips missing hook scripts).
