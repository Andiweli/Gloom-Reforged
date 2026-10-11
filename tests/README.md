# Stabilization regressions (host only)

`updater_http_test.c` links the production `source/updater/http.c` against a
fake TLS transport. Compile with a C11 compiler and run the resulting program.
On MSVC: `cl /std:c11 /W4 /WX /Isource/updater tests/updater_http_test.c source/updater/http.c`.

`asm_regression.py` executes the real assembled game and benchmark instructions
using Musashi, with Amiga library calls explicitly stubbed. It requires Python 3,
vasm (Motorola syntax, m68k backend) and Musashi sources. External tools are not
vendored or included in production builds. Tested: vasm 2.0f and Musashi commit
313ebf1 (MIT), MSVC 19.51, Python 3.12, CPU models 68020/68030/68040.

Build Musashi's `m68kmake.c`, run it from the Musashi source directory, then
compile `m68kcpu.c`, generated `m68kops.c`, `softfloat/softfloat.c` and this
folder's `musashi_memory.c` into a shared library. Include the Musashi directory.
On Windows use `/LD /D_CRT_SECURE_NO_WARNINGS`; on Unix use `-shared -fPIC -lm`.
Keep all tool sources and build outputs outside the tracked repository.

For each program, create an external wrapper with two lines:

```asm
 include "GloomReforged_Modular.s" ; or GloomBench.s
 opt debug
```

From `source/`, assemble that wrapper using:

```text
vasmm68k_mot -Fhunkexe -kick1hunks -devpac -m68020 -nocase -o game.hunk wrapper.s
```

Run the Python harness from the repository root, passing the external paths:

```text
python tests/asm_regression.py /path/to/musashi_test.dll /path/to/game.hunk /path/to/bench.hunk
python tests/stability_invariants.py
```

Adjust paths for external outputs. `opt debug` exports labels for the harness;
it does not alter game instructions. Tests assert register reloads, allocation
failure, ownership, stack balance and selected malformed inputs. They do not
validate AmigaOS, AmiSSL, Picasso96 drivers, DMA or hardware performance.

`stability_invariants.py` verifies 19 unchanged render/gameplay modules, the
remaining presentation code, benchmark measurement blocks, shared corrected
routines, the active include list and every current manifest hash. Run it from
any directory inside a clone containing the audited Git commit.
