# Gloom Reforged 2.5.0 – final free version

2.5.0 is the last free release of Gloom Reforged. It combines 2.4.0 with the
stabilization audit and a set of bug fixes. It adds no new features; new
features are only in the itch.io version (3.0 and later).

## Stability (2.4.0 audit)

- Every loaded file is checked before use: pictures, palettes, maps, scripts,
  animations, textures, compressed files and MED music.
- Safer MED music start/stop and CIA timer ownership.
- Settings are written so that an interrupted save never destroys the old file.
- Incomplete initialization is aborted cleanly and only owned resources are freed.
- Details: `AUDIT-STABILIZATION-2.4.0.txt`.

## Bug fixes

- Menus no longer flicker: ESC menu, option changes (FLOOR, CEILING,
  RESOLUTION, BAYER …) and CONTINUE show no black or wrongly coloured frame
  on AGA/ECS; on P96 option changes appear in one step and rows no longer
  blank out before they are redrawn.
- P96: QUIT GAME no longer disappears after a full menu redraw.
- P96: characters of the large font keep their right outline (the glyph
  cache was one pixel too narrow).
- P96: no stray blitter access when the menu glyph cache is unavailable.
- Gloom 3 / Zombie Massacre: the original intermission pictures no longer
  stop a new game.
- Gloom 3: monsters with fewer animation frames (baldy, lizard, troll,
  demon) no longer stop the first level; their missing attack frames repeat
  the last available frame.

## Build

Assemble `source/GloomReforged_Modular.s` from `source/` (Devpac/GenAm
compatible, `-m68020 -nocase`). See `source/modular/MODULARIZATION.txt`.
