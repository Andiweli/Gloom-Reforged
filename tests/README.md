# Stabilization regressions (host only)

`updater_http_test.c` links the production `source/updater/http.c` against a
fake TLS transport. Compile with a C11 compiler and run the resulting program.
On MSVC: `cl /std:c11 /W4 /WX /D_CRT_SECURE_NO_WARNINGS /Isource/updater
tests/updater_http_test.c source/updater/http.c source/updater/buffer.c
source/updater/common.c` (keep object/executable output outside the repository).

`asm_regression.py` executes the real assembled game and benchmark instructions
using Musashi, with Amiga library calls explicitly stubbed. It requires Python 3,
vasm (Motorola syntax, m68k backend) and Musashi sources. External tools are not
vendored or included in production builds. Tested: vasm 2.0f and Musashi commit
313ebf1 (MIT), MSVC 19.51, Python 3.12, CPU models 68020/68030/68040.

Build Musashi's `m68kmake.c`, run it from the Musashi source directory, then
compile `m68kcpu.c`, generated `m68kops.c`, `m68kdasm.c`, `softfloat/softfloat.c` and this
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

`stability_invariants.py` verifies 18 complete modules unchanged from master,
three additional complete Phase 1 modules, the presentation code outside six
cold entry stubs, 71 measurement blocks, eight shared routines, 37 active
includes, 39 manifest hashes and 18 unchanged distinct INCBIN files. Run it from
any directory inside a clone containing commits c223cf5 and d825e91.

Phase 2 uses the same DLL and debug hunks. Build external debug reference hunks
from d825e91 with the same assembler/options. Keep the current checkout on
audit; an external directory exported with `git archive d825e91` is suitable.
The baseline game provides the original CrM decoder and normalization oracle.
Run from the current repository root:

```text
python tests/phase2_resources.py DLL baseline-game.hunk game.hunk bench.hunk
python tests/phase2_events_scripts.py DLL game.hunk bench.hunk
python tests/phase2_palettes.py DLL game.hunk bench.hunk
python tests/phase2_config_recovery.py DLL game.hunk bench.hunk
python tests/phase2_med.py DLL game.hunk bench.hunk
python tests/phase2_p96.py DLL game.hunk bench.hunk
python tests/phase2_allocations.py DLL game.hunk bench.hunk
python tests/phase2_kernel_compare.py DLL baseline-game.hunk game.hunk baseline-bench.hunk bench.hunk
```

The focused suites run CPU models 68020/030/040 for both programs. CrM includes
byte comparisons against the original decoder for repository and compiled
resources, in-place decoding, guarded input/output and seeded malformed data.
Event/script tests cover incomplete operands, references, cycles without a
yield, text wrapping and bounded destinations. Palette tests include alternate
IFF profiles, font DMA spans/height/planes, fixed HUD/gun/actor frame consumers,
signed animation column offsets, CLUT and SFX extents. Config tests simulate
interruption at each replacement step and restart with a different task address.
MED fixtures now accept only the MMD1 raw-sample cases consumed by this binary;
other old positive framing fixtures are rejected. They do not certify every
playback state. External executable C2P bytes are trusted code: only required
entrypoint extent is checked.

Allocation tests use actual initmain and scriptplay loading instructions on a
68020 model with repository profile data. They stop before gameplay. Graphics,
libraries, interrupts, audio and DOS are explicitly simulated. For each binary,
42 maps are loaded twice in AGA and P96 CLUT fixtures, followed by the production
ownership cleanup calls. Every successful AGA startup allocation position is
also failed once. Counts describe private AllocMem requests, not all OS/driver
allocations or a real hardware boot. MEMF_PUBLIC placement is not guaranteed
Fast RAM. The P96 missing-reply suite observes 100,000 instruction steps per
case and confirms retained ownership; it does not prove eventual termination.

Kernel comparison checks ten assembled spans per binary. Absolute relocation
fields are normalized. For the scene/wall spans, changed PC displacements are
checked against unchanged opcodes/layout and corresponding symbol+offset
destinations. The remaining eight spans compare byte for byte after relocation
normalization. This is not whole-executable identity or an FPS measurement.
Also assemble both entrypoints without `opt debug` and compare the relocated
CODE/BSS returned by `asm_regression.load_hunk`; symbols must not change code.

Actual Phase 2 counts, tool versions, limitations and hardware work remaining
are recorded in ../AUDIT-STABILIZATION-2.4.0.txt. Build/test outputs belong
outside the repository; released executables are not replaced by this audit.

Phase 3 continues from f568087, including all five Phase 2 commits. Export
that commit to an external directory and assemble debug reference hunks with
the same options. The CrM suite still uses d825e91 as its original decoder
oracle; render and music comparisons use f568087. Rebuild the Musashi DLL from
the current musashi_memory.c: its opt-in beam/MMIO model is needed by the MED
tests. CPU models 4/6/9 mean 68020/030/040; no 68060 execution is claimed.

```text
python tests/phase3_med.py DLL game.hunk bench.hunk
python tests/phase3_legacy_resources.py DLL game.hunk bench.hunk
python tests/phase3_config.py DLL game.hunk bench.hunk
python tests/phase3_player_compare.py DLL phase2-game.hunk game.hunk bench.hunk
python tests/phase3_profiles.py DLL game.hunk bench.hunk DATA_ROOT profiles.json
python tests/phase3_profile_music.py DLL phase2-game.hunk game.hunk bench.hunk DATA_ROOT music.json
```

DATA_ROOT contains the supplied gloom, deluxe, gloom3 and massacre directories.
These suites only read them. No original assets are committed. The profile
suite compares 650 resource records for both executables, records controlled
rejections, and runs 16 actual initmain/free prefixes in modelled AGA/P96 modes.
It does not simulate full campaigns or missing ECS/EHB artwork. The music suite
runs eight supplied songs on three binaries for 30,000 ticks each. It compares
MMIO write streams and checks each published Paula span against the owned
module or chipzero in a numeric two-MiB Chip model. No DMA engine, actual audio,
CIA latch timing or asynchronous OS interrupt dispatch is emulated. Reaching
some sequence positions is bounded coverage, not proof of every state/effect.

The config suite copies the DLL twice into a temporary directory so two CPUs
have independent Musashi globals. It requires a writable system temp directory.
The two tasks share a modelled DOS directory with fail-if-target-exists Rename.
It checks interrupted/interleaved writers and corrupt-backup loading; it proves
neither serialisability nor physical filesystem durability.

phase3_evidence.json records actual build hashes and counts for this run.
phase3_original_profiles.json and phase3_original_music.json contain original
asset metadata and observed results, without game data. These are evidence
snapshots, not substitutes for running the tests with the recorded inputs.
The report explicitly retains the unresolved MED graph/aliasing, Gloom 3 actor,
P96 reply and filesystem limits. F004 is not fully closed.
