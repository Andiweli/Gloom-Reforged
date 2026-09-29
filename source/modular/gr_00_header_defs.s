; v2.2 / c87b80p: consolidate hardware-tested renderer and native menu fixes.
; Bayer lookup, low-resolution scaling, period palettes, native screen/audio
; separation, menu strip release and live-menu WaitBlit boundaries. No logging.
; c87b80o / RC5 GenAmFix1: GenAm 3.18 branch-range fix only.
;                            The failed-OpenWindow path in windowtask now
;                            uses a nearby inverted short branch plus an
;                            immediate RTS instead of the out-of-range
;                            BEQ.S to the routine tail. The old tail RTS
;                            is removed, so code size after windowtask is
;                            unchanged. No runtime behaviour is changed.
;==============================================================================
; c87b80n / RC5: Harden native/P96 pointer ownership and the direct CLUT
;                FPS overlay. Native AGA/ECS focus loss now detaches input
;                immediately but delays restoring the OS pointer for four VBlanks;
;                queued ACTIVEWINDOW/INACTIVEWINDOW messages are collapsed so a
;                transient focus pulse cannot flash the pointer. The native window
;                task now follows WaitPort with GetMsg before replying each IDCMP
;                message. A complete 16x16 blank chip pointer replaces the former
;                one-line/one-pixel pointer on native and P96 windows. P96 CLUT FPS
;                digits use the palette-aware whitest-neutral source pen instead
;                of assuming exact RGB565 $FFFF exists in every gameplay LUT.
;                RC4 requester/preferences and wall DIVS overflow fix unchanged.
;==============================================================================
; c87b80m / RC4: Integrate the hardware-confirmed GloomBench requester into
;                the full game: saved validated P96 ModeID, left-Shift startup
;                override, optional Low Bandwidth publishing, final classic
;                layout, latched Screenmode selection with explicit OK, and
;                IDCMP_REFRESHWINDOW redraw. Restore original Gloom2 DIVS
;                overflow handling before wall endpoint X-scaling to address
;                intermittent wall disappearance while turning.
;==============================================================================
; c87b80f / RC3: Replace p96BestModeIDTagList availability probing with
;                  authoritative p96AllocModeListTagList scanning. pVision
;                  exposes valid CLUT8 modes in the list but returns INVALID_ID
;                  from BestModeID. The selected first validated ModeID is used
;                  directly; P96MODEID remains the explicit alternate selector.
; c87b80e: Second release-candidate source hardening pass. Remove the
;          permanently dormant GLOOMBENCH2 automation harness, result
;          writer and audio/loading gates from the assembled program.
;          The normal build fixed g2bench2_enabled at zero and no live
;          callsite referenced any benchmark entry. Active renderer
;          optimizations originally developed during benchmarking, all
;          P96/RGB565/CLUT ownership, AGA/ECS paths and gameplay logic
;          remain unchanged. Public marker advances to RC2.
; c87b80d: First release-candidate hardening pass. Remove the permanently
;          disabled ECS DH3 stage logger and ECS asset-log writer from the
;          assembled program. Their compile-time switch was fixed at zero:
;          stage calls entered immediate RTS stubs and asset validation always
;          branched around the file writer. Core ECS asset validation, the
;          visible missing-EHB warning, AGA/ECS rendering and every confirmed
;          P96/RGB565/CLUT ownership path remain functionally unchanged.
; c87b80c: Remove unreachable implementation tails behind 24 public P96
;          compatibility trampolines. Each retained entry already performs an
;          unconditional JMP to its released successor; the superseded body
;          below that JMP could never execute but still occupied code space.
;          Callers, active targets, RGB565 ownership, CLUT publishing, mode
;          requesters and native AGA/ECS paths are otherwise unchanged.
; c87b80b: Conservative post-rollback P96 dead-compatibility audit. Remove only
;          globally unreferenced routines and state left behind by superseded
;          menu-cache, ABOUT-shortcut, direct-VRAM and palette-apply experiments.
;          The active RGB565 transition/ScreenBuffer blanking, compatibility
;          publisher, static/menu/gameplay LUTs, reverse maps and WIDE shading
;          are deliberately unchanged. Native AGA/ECS code is unchanged.
; c87b80a: Regression rollback after c87b79z/z1. Real P96 hardware showed an
;          immediate return to Workbench when ONE PLAYER or TWO PLAYER entered
;          gameplay. Restore the fully hardware-confirmed c87b79y1 ownership:
;          RGB565 remains responsible for transition/double-buffer blanking and
;          compatibility publishing, while live gameplay and the direct title/
;          menu path keep their proven CLUT implementations. This deliberately
;          removes every c87b79z runtime redirect as one atomic regression unit;
;          no AGA/ECS code or active c87b79y1 P96 cleanup is changed.
; c87b79y: Complete the conservative P96 legacy-altpath audit after the
;          confirmed planar-page/materializer removal. Delete unreferenced
;          pre-release ModeID/screen/window/static probes, RGB222 calibration,
;          retired aliases and the old whole-menu planar/RGB565 presenter.
;          Remove all unused planar/chatfont menu-row renderers plus remaining
;          P96 calls to the now-inert planar row recomposer. Direct Bigfont
;          glyph/page/row caches are now the only P96 menu publication path;
;          cache/target failure is a bounded no-op, never a planar fallback.
;          g2p96_set_target_mode patches only live persistent-screen fields.
;          Native AGA/ECS menu, blitter and planar code is unchanged. Internal
;          RGB565 colour LUTs/reverse maps/WIDE shading remain intentionally.
; c87b79x: Remove the two compact planar show/draw compatibility pages from
;          DISPLAY=P96. initdisplay now leaves bitmaps/bitmaps2/showbitmap/
;          drawbitmap and bmapmem at zero for P96, while native AGA and ECS/EHB
;          retain their original allocations. Generic copy/clear/swap/db helpers
;          are hard-gated before touching those pointers. TITLE, ABOUT, optional
;          title brushes, Intermission text and menus use only the authoritative
;          320x240 direct index page plus the established CLUT row/page caches.
;          printmess2 bypasses the Amiga blitter under P96 and forwards glyphs
;          straight to the indexed typewriter compositor. The former index-to-
;          planar materializer is retired to an empty compatibility entry; no
;          reachable P96 path reconstructs bitplanes. Internal RGB565 LUT/staging
;          keys remain intentionally unchanged. Native AGA/ECS are unchanged.
; c87b79w: Finish the direct P96 initmenu/menu-strip path. Once the exact
;          Bigfont cache and staged CLUT target are both valid, initmenu no
;          longer copies/swaps planar show/draw pages, allocates or snapshots
;          planar menustrips, or publishes the completed menu through db. The
;          direct Fast-RAM page/row caches remain the sole P96 menu source.
;          Native AGA/ECS and every failed P96 probe retain the old path.
; c87b79v: Remove the PiStorm-visible TITLE/ABOUT slowdown introduced by c87b79u.
;          The direct 8-bit CLUT TITLE/ABOUT source remains authoritative, but the
;          expensive full 320x240 index-to-planar reconstruction is no longer run
;          after each static P96 publication (base title, ABOUT and title brush).
;          Planar compatibility pages are materialised only if the proven native
;          P96 Bigfont/menu target is unavailable and initmenu must really enter
;          its legacy planar fallback. The normal P96 title/menu path therefore
;          avoids the repeated 614400-bit tests and writes to two planar pages.
;          c87b79t TWO PLAYER WIDE and c87b79r intermission ownership are unchanged.
; c87b79u: Second controlled planar-source removal phase for P96 static screens.
;          TITLE and ABOUT now decode into the authoritative 320x240 Fast-RAM
;          index page without clearing or mirroring the compact planar pages.
;          The optional title brush follows the same direct-only CLUT source
;          contract. Because the mature title-menu setup still allocates and
;          copies planar row strips, the final direct picture is materialised
;          once, only after a completed P96 title/ABOUT publication. This keeps
;          the old menu fallback exact while removing all normal dual-decode
;          writes from TITLE/ABOUT. Intermission direct ownership from c87b79r,
;          gameplay, TWO PLAYER WIDE c87b79t, native AGA and ECS/EHB are unchanged.
; c87b79t: Final focused retry for P96 TWO PLAYER WIDE RESOLUTION projection.
;          Built directly from the hardware-confirmed c87b79r baseline; the
;          ineffective c87b79s experiment is not part of this source. The real
;          split renderer owns a row-major 428-byte source through
;          g2kalms_linear_active, while common WIDE projection helpers key their
;          native 428-pixel branches from p96gameplay_linear_active. In compact
;          2x1/1x2/2x2 halves that second owner was false, so the helpers fell
;          through to the legacy 320-to-428 scaling path and produced the visible
;          STRETCH impression. Each compact P96 WIDE half now temporarily publishes
;          both the native RESOLUTION geometry and the proven row-major P96 linear
;          owner. The previous value is restored before HUD drawing/presentation.
;          Standard, 5:4, AGA/ECS and 1x1 TWO PLAYER paths are unchanged.
; c87b79r: First planar-source removal phase for P96 static screens. Intermission
;          base pictures and overlays are decoded directly into the authoritative
;          320x240 Fast-RAM index composition without writing the compact planar
;          show/draw source pages on the normal CLUT path. A guarded, on-demand
;          index-to-planar materializer exists only for the mature text fallback;
;          successful direct typewriter/intermission presentation never invokes it.
;          Title/ABOUT still keep their proven dual direct+planar builder in this phase.
;          Native AGA/ECS, menus, gameplay and the released CLUT runtime contract are unchanged.
; c87b79q: Enforce the released P96 backend as an 8-bit CLUT-only runtime contract.
;          The persistent screen open and capability checks now reject any non-CLUT
;          or non-8-bit state before Intuition/P96 resources are touched. Dormant
;          RGB565 visible-bitmap publishers and old 16-bit requester validators are
;          removed; RGB565 remains only as an internal colour/compositor key format.
;          Native AGA/ECS and the confirmed CLUT pixel paths are unchanged.
; c87b79p: Hard P96 presenter gate. DISPLAY=P96 now bypasses doc2p centrally,
;          routes every generic db swap directly to the P96 RAM-source endpoint,
;          and routes every pokepal2 transaction directly to the P96 palette-source
;          endpoint instead of trusting legacy native dispatch pointers. The old grey
;          menu/C2P helpers are explicitly native-only, and P96 scriptplay no longer
;          depends on an external/native C2P routine being available. Native AGA/ECS
;          retain their original doc2p/db/pokepal paths. No visible P96 renderer,
;          geometry, palette contract, ONE/TWO PLAYER or static presenter is changed.
; c87b79o: Remove the last automatic native AGA/ECS display fallback after a selected P96
;          screen/window fails to open. P96 open failure now shows one clear requester,
;          marks a fatal P96 startup/runtime error and exits through the normal cleanup path.
;          The OCS/ECS preflight also aborts instead of silently switching to ECS/EHB.
;          Explicit Use AGA / native ECS selection in the first requester remains available.
;          No renderer, palette, geometry, ONE/TWO PLAYER or native AGA/ECS code is changed.
; c87b79n: Remove the historical P96 offscreen-bridge state flag and make DISPLAY=P96
;          the direct owner of the planar RAM source backend. initmain selects P96 source-only
;          db/palette dispatch directly; initdisplay and finitdisplay test g2display_mode=2
;          instead of consulting a duplicate bridge lifetime flag. The planar bitmaps remain
;          internal source pages for static/menu compatibility, but no legacy Intuition screen
;          is opened for P96. The guarded native-display fallback is retained only for an actual
;          persistent P96 screen-open failure. Native AGA/ECS and all visible P96 paths are unchanged.
; c87b79m: Change the first P96 requester's footer to the final three-line CLUT wording requested
;          for Gloom Reforged 2.0. Remove the remaining one-shot 256-entry P96 palette-map
;          dump from RAM:gloom_basic.log, including its private strings, checksum helpers and
;          formatter loop. Compact STARTUP/TITLE/GAME/P96 snapshots and P96MODEID output remain.
;          No renderer, palette, mode-selection, AGA, ECS or P96 presentation behaviour changes.
; c87b79l: first-requester punctuation cleanup and P96 TWO PLAYER live FLOOR/CEILING menu refresh.
;          All six P96 geometries redraw both split views immediately and the QUIT row
;          is restored after the trigger-release wait in every native P96 menu mode.
;          Restore EVEN after the remaining Bigfont cache/scratch name strings
;          so g2p96_menu_glyph_mode_active starts on an even 680x0 address.
;          No renderer, palette, P96, AGA or ECS behaviour changes.
; c87b79i: Remove the permanently disabled legacy P96 diagnostic file writers,
;          their private messages/buffers and all dead call sites. The useful
;          RAM:gloom_p96_modeid.txt and compact RAM:gloom_basic.log outputs stay.
;          Simplify the embedded release marker: no CPU/optimization suffix and
;          no trailing padding spaces. Renderer, palette, AGA/ECS and all P96
;          gameplay/display behaviour remain unchanged.
; c87b79h: Public version advanced to Gloom Reforged 2.0. Removes obsolete
;          BRIDGE naming from the now-native P96 title, menu and intermission
;          ownership states, presenters, row caches and gated static helpers.
;          This is a symbol/comment cleanup only: renderer code, palette
;          contract, CLUT/RGB565 backends, double buffering, transitions,
;          ONE/TWO PLAYER and all six P96 geometries are unchanged.
; c87b79g: Remove the permanently disabled historical Workbench/P96 preview-overlay subsystem.
;           No palette, gameplay, menu, intermission, mode or RGB565 fallback behaviour changes.
; c87b79f: Roll back only the c87b79e direct-original-palette experiment.
;          Static P96 pages do not have one universal palette owner: title,
;          About and intermission builders deliberately select lastpal, picpal,
;          gloompal or g2inter_exact_palette_ptr according to their established
;          lifetime. c87b79e bypassed that selection and could install an all-
;          black CLUT base while the separately overlaid menu font pens remained
;          visible. Restore the proven c87b79d RGB565-derived LoadRGB32 contract
;          unchanged. Rendering remains direct indexed; only CLUT colour-source
;          ownership is rolled back. ONE/TWO PLAYER, all six modes, WIDE and
;          transition blanking are unchanged.
; c87b79d: GenAm 3.18 range-only build fix for c87b79c. Replaces one
;          out-of-range PC-relative word load with the already established
;          absolute symbol form, and widens one branch to .done from BRA.S
;          to BRA.W. No renderer, transition, ONE PLAYER or TWO PLAYER
;          behavior is changed.
;
; c87b79c: Completes direct-indexed P96 TWO PLAYER for the true WIDE
;          geometries 428x240 and 854x480. Each split half is rendered at a
;          real 428-pixel source width (not a stretched 320-pixel picture),
;          including both HUDs and all four RESOLUTION settings. 854x480 uses
;          the established exact 1+426*2+1 horizontal mapping and 2x vertical
;          expansion. Also fixes the brief stale-frame flash when a second game
;          is started from the title menu: the new-game handoff now blacks both
;          P96 ScreenBuffers and suppresses the one eager presenter update that
;          previously copied the previous game's chunky page before the next
;          intermission picture was ready. The confirmed ONE PLAYER and four
;          non-WIDE TWO PLAYER modes remain unchanged.
;
; c87b79b: Fixes the ONE PLAYER vertical-stripe regression introduced by
;          c87b79a. The new TWO PLAYER HiRes helper saved/restored a6,
;          but its generic fallback contract must return a6=coloffs to
;          the established ONE PLAYER row presenter. Restoring the old
;          entry value after setting coloffs made the presenter read its
;          per-column source offsets through an invalid base address.
;          The helper now restores its registers first and only then
;          establishes a6=coloffs and d0=hite on the unhandled path. The
;          confirmed TWO PLAYER 320/640 paths are functionally unchanged.
;
; c87b79a: Extends the user-confirmed packed direct-indexed TWO PLAYER path
;          from 320x240/320x256 to the exact 640x480 and 640x512 P96/CLUT
;          modes. The complete linear 320x240 or 320x256 split page (both
;          players and both HUDs) is expanded 2x2 entirely in Fast RAM, then
;          published by the established short LockBitMap/CopyMem/UnlockBitMap
;          transfer. No doc2p/db or RGB565 round trip is used on success.
;          The confirmed low-resolution TWO PLAYER path, all ONE PLAYER modes,
;          WIDE/static/intermission/menu fixes and native AGA/ECS remain unchanged.
;          TWO PLAYER WIDE 428x240/854x480 remains deliberately deferred.
;
; c87b78z: Removes the obsolete 400x240 and 800x480 pseudo-wide P96 modes.
;          Every P96 WIDE owner now resolves exclusively to the true 16:9-class
;          428x240 or 854x480 geometry; the old legacy probe slots no longer
;          request 400/800 and the renderer has no 400-pixel source fallback.
;          TWO PLAYER stage 1 adds an explicit packed direct-indexed fast path
;          for 320x240 and 320x256 P96/CLUT: the already linear split frame
;          (120+120 or 128+128 rows, both HUDs included) is copied as one Fast-
;          RAM page to the CLUT stage and published without doc2p/db. High-res
;          and WIDE TWO PLAYER remain on the generic direct presenter for now
;          and are not yet declared final. ONE PLAYER and c87b78y's confirmed
;          WIDE/intermission/menu behaviour are unchanged.
;
; c87b78y: Restores the exact c87b78u intermission font-colour contract while
;          retaining c87b78w's corrected continuous WIDE edge extension and
;          collision-free title/about/in-game menu pens. Intermission only
;          again installs the original fixed Bigfont palette entries 0..3 and
;          writes glyph levels directly as indices 1..3, exactly as in the
;          user-confirmed c87b78u path. TWO PLAYER remains unchanged.
;
; c87b78w: GenAm build fix for c87b78v; uses an explicit $5c backslash byte literal.
; c87b78v: Fixes two CLUT regressions in the newly released WIDE path.
;          Static title/intermission side extensions now quantise the established
;          four-level pulled-edge wash to the nearest installed palette pen, so
;          non-palette RGB565 shades can no longer fall through to pen 0 and look
;          like missing image strips. Menu/font colours no longer overwrite fixed
;          indices 0..3: exact colours are reused, otherwise only currently unused
;          pens are borrowed, with safe source-colour redirection for later menu
;          refreshes. Ordinary direct intermission glyphs consume the selected
;          dynamic pens. TWO PLAYER is deliberately unchanged.
;
; c87b78u: Completes the native 8-bit P96/CLUT backend for the exact
;          428x240 and 854x480 WIDE modes. Gameplay was already direct
;          indexed; static title/intermission artwork now receives the
;          established horizontal edge wash as final CLUT pens in Fast RAM.
;          Title/About, in-game menus, row caches and intermission glyphs use
;          centred logical 320x240 coordinates at X=54/X=107. OCS/ECS hosts
;          now expose all six validated P96 geometries. obsolete pseudo-wide compatibility modes were not part of this release.
;
; c87b78t: Extends the confirmed native 8-bit P96/CLUT backend to the
;          exact 320x256 and 640x512 5:4 modes. Gameplay keeps its true
;          256-row indexed renderer. Static 320x240 artwork is centred at
;          Y=8/Y=16 and receives the established quarter/half/three-quarter
;          top/bottom edge wash as final palette pens in Fast RAM. Title,
;          About, in-game menus, row caches and intermission typewriter use
;          the same centred logical 320x240 coordinates without RGB565 VRAM
;          output. OCS/ECS hosts now expose both standard and 5:4 modes; WIDE
;          428x240/854x480 remains deliberately filtered and not test-ready.
;
; c87b78s: Enables the already validated standard 8-bit P96/CLUT backend on
;          OCS/ECS hosts with RTG. Only DISPLAY=AGA remains hardware-gated.
;          The P96 chooser's chipset fallback is host-aware (AGA on AGA, ECS
;          on OCS/ECS), including labels and no-library/no-mode messages. An
;          ECS-host chooser is restricted to the completed 320x240/640x480
;          standard modes. A pre-init OpenScreen/OpenWindow preflight verifies
;          the selected P96 ModeID before any game buffers/assets are initialized;
;          failure returns safely to the native ECS/EHB renderer rather than
;          ever attempting an AGA screen on non-AGA hardware. The active P96
;          renderer, palette, 320x240/640x480 CLUT paths and AGA/ECS renderers
;          are otherwise unchanged.
;
; c87b78r: Extends the confirmed direct indexed P96/CLUT composition to the
;          exact 640x480 standard P96 screen mode. Gameplay and static
;          screens were already direct indexed; title/About, in-game menu,
;          menu row caches, planar-delta updates and intermission typewriter
;          now keep logical 320x240 coordinates while writing final 2x2 CLUT
;          pixels in Fast RAM. Completed byte rectangles alone are copied under
;          the short official bitmap lock. 320x240 remains unchanged; WIDE and
;          5:4 geometries retain the confirmed fallback and are not test-ready.
;
; c87b78q: Direct indexed 320x240 P96/CLUT title/About menus and intermission typewriter.
;          TITLE_BRIDGE menu rows now restore and compose from the clean one-byte
;          p96clut_stage_ptr.  The intermission typewriter updates the authoritative
;          static index page and CLUT stage directly, then publishes a completed
;          10-row indexed band under the established short bitmap lock.  RGB565,
;          WIDE, 5:4 and all non-320x240 paths retain the confirmed fallback.
;
; c87b78p: Direct indexed 320x240 P96/CLUT in-game-menu composition.
;          The paused gameplay frame remains authoritative in the one-byte
;          p96clut_stage_ptr. Menu batch/row caches copy indices directly,
;          glyph pens are written as bytes and completed rectangles are
;          published without an RGB565 round-trip. Other geometries retain
;          the confirmed c87b78o/RGB565 fallback.
;
; c87b78o: First-open P96 CLUT in-game-menu backdrop synchronisation for the
;          confirmed 320x240 standard mode. Direct indexed gameplay no longer
;          updates the legacy RGB565 staging page every frame, while the menu
;          compositor still uses that page as its clean background source.
;          Immediately before GAMEPLAY becomes MENU_BRIDGE, the current packed
;          8-bit CLUT frame is converted once in Fast RAM through the exact
;          gameplay source LUT into p96static_rgbbufptr. The first menu opening
;          therefore uses the same paused frame as the visible screen instead
;          of a stale title/older gameplay cache. No bitmap lock, VRAM read or
;          visible redraw is performed. Other geometries deliberately retain
;          the confirmed fallback until separately validated.
; c87b78n: Direct-indexed native P96 static-screen publication for RGBFB_CLUT.
;          Title and intermission pictures already maintain an authoritative
;          320x240 Fast-RAM palette-index composition. For standard aspect
;          targets this buffer is now scaled directly into the packed 8-bit
;          CLUT stage and copied under the official short bitmap lock, avoiding
;          the RGB565 -> reverse-map -> index round trip at presentation time.
;          The proven RGB565 page is still built in parallel because title,
;          About, in-game menu and typewriter caches currently source it. WIDE
;          edge shading, 5:4 border washes, invalid direct compositions and all
;          RGB565/AGA paths deliberately retain the established fallback.
; c87b78m: Native direct-indexed P96 gameplay for RGBFB_CLUT. Normal CLUT
;          gameplay now scales/copies the renderer's existing 8-bit source bytes
;          straight into the packed Fast-RAM CLUT stage; the former per-pixel
;          source-byte -> RGB565 -> reverse-map -> pen round trip is bypassed.
;          The exact source-byte keyed LoadRGB32 contract remains unchanged.
;          FPS digits are composed directly in indexed RAM using the same black/
;          white reverse keys as before. In-game-menu backdrop generation stays
;          on the proven one-frame RGB565 stage while the menu owns the display.
;          RGB565 screens and all static/menu/intermission paths are unchanged.
; c87b78l: GenAm 3.18 build fix for c87b78j. The now out-of-range
;          gore(pc) address load uses the established absolute relocatable
;          form, and the diagnostic window probe routes a missing guarded
;          CLUT runtime through its existing no-usable-mode exit. No P96,
;          palette, rendering or fallback behaviour is changed.
; c87b78l: CLUT menu/font recovery fix. Font palette updates deliberately mark
;          the active CLUT contract dirty; title/about/in-game menu overlays now
;          reinstall the correct staged base LUT before patching font pens 0..3,
;          preventing unmapped glyph RGB565 keys from falling back to black index 0.
; c87b78j: Guarded native P96 8-bit CLUT backend. Exact 8-bit P96 modes are
;          preferred per supported geometry; the proven 16-bit RGB565 modes
;          remain the automatic fallback. All existing renderers still compose
;          complete RGB565 frames/rectangles in Fast RAM. For a CLUT target the
;          finished RAM data is converted, before any bitmap lock, through an
;          exact 65536-entry RGB565-to-pen map into a packed 8-bit Fast-RAM
;          stage. p96LockBitMap is then held only for CopyMem/CopyMemQuick.
;          LoadRGB32 is generated from the exact active gameplay/static/menu
;          LUT, so gameplay invpal mapping, fades, title palettes and font
;          overlays remain tied to the same colours used by the compositor.
;          CLUT allocation/format/lock failures leave the established RGB565/
;          AGA rollback paths intact.
; c87b78i: GenAm-safe absolute calls for the c87b78h palette contract
; c87b78h: P96 palette ownership foundation and generation-cached RGB565
;          conversion. Every valid P96 pokepal2 update is registered as one
;          explicit palette transaction (pointer, safe entry count, AGA/ECS
;          precision and monotonically increasing generation). A complete raw
;          256-colour shadow is maintained cheaply in program RAM; a guarded
;          LoadRGB32 builder/apply helper is ready for the later CLUT switch
;          and remains dormant while RGB565 is selected.
;          The gameplay source LUT now rebuilds only when palette generation,
;          inverse-palette generation, RGB format, palette pointer or AGA/ECS
;          precision actually changes. No screen mode, visible colour, menu,
;          intermission, RESOLUTION or AGA/ECS fallback behaviour is changed.
;
; c87b78g: P96 intermission typewriter staged-glyph publication. Each Bigfont
;          character is composed only into the linear index page and completed
;          Fast-RAM RGB565 page. The former per-pixel write to the visible P96
;          bitmap and its direct BitMap.Planes[0]/BytesPerRow target discovery
;          are removed. After one character is complete, only its physical row
;          band is published atomically through the proven short
;          p96LockBitMap()/CopyMem()/p96UnlockBitMap rectangle helper.
;          Typewriter timing, ENTER/SPACE/ESC/mouse skip, all P96 geometries,
;          RGB565 mode selection and AGA/ECS fallbacks remain unchanged.
;
; GLOOM_REFORGED_V1_10_0_EHB_ESC_ONLY
; c87b78f: P96 static full-screen staged lock/copy publication. Title, About
;          and intermission frames are still composed completely in the
;          existing Fast-RAM RGB565 page, but their final full-screen present
;          no longer reads BitMap.Planes[0] or BitMap.BytesPerRow. The packed
;          RAM page is published through the same short RenderInfo-based
;          p96LockBitMap()/CopyMem()/p96UnlockBitMap rectangle helper proven
;          by c87b78d/e. Gameplay, menu glyph composition, palettes, double
;          buffering and all four RESOLUTION modes remain unchanged.
; c87b78e: P96 menu staged-rectangle X-position fix. The locked-copy
;          helper now preserves the calculated destination X byte offset
;          while validating destination height. c87b78d accidentally
;          replaced that offset with p96target_height immediately before
;          address generation, shifting title/about and in-game menu
;          backgrounds plus glyphs together to the right.
; c87b78d: Native P96 menu/title staged-rectangle presenter. Menu and title
;          rows are now composed entirely in Fast RAM from the clean staged
;          RGB565 page. Row and full-menu caches no longer read or write
;          BitMap.Planes[]/BytesPerRow directly. Finished RAM rectangles are
;          published through a short p96LockBitMap()/CopyMem()/unlock helper.
;          Gameplay, intermission typewriter, RGB565 mode selection and all
;          four RESOLUTION modes remain unchanged.
; c87b78c: Native P96 staged lock/copy/unlock presenter. Gameplay now builds
;          the complete RGB565 output frame in the existing Fast-RAM staging
;          buffer. Only after conversion and FPS overlay are complete is the
;          safe offscreen ScreenBuffer locked with p96LockBitMap(), copied by
;          CopyMemQuick when the rows are contiguous (otherwise row-wise
;          CopyMem), immediately unlocked, and then flipped. The gameplay
;          presenter no longer reads BitMap.Planes[0] or BytesPerRow directly.
;          RGB565 modes, all four RESOLUTION modes, menu/static bridges and the
;          established AGA rollback remain unchanged.
; c87b78b: First native-P96 bootstrap patch. The pre-opened P96 gameplay
;          owner now enables the linear Fast-RAM chunky layout immediately,
;          without waiting for twelve legacy/AGA presents or requiring one
;          confirmed legacy-layout copy. While the P96 owner is opened from
;          the gameplay pre-open hook, the old current frame is never sent to
;          AGA: the RTG screen remains black until the first complete linear
;          gameplay frame is copied and flipped. Existing RGB565 transfer,
;          ScreenBuffer double buffering, all four RESOLUTION modes and the
;          established failure rollback remain unchanged in this first step.
; c87b78a: Isolated NASTY blood-performance test based on stable c87b76a.
;          Blood and persistent-gore pools are reduced from 128 to 96 entries.
;          Near-camera raster caps are reduced from 64/16/64 to 32/8/32 rows
;          for floor pools, satellite droplets and wall-stain ovals. World
;          size, seed, position, shape profile and attachment remain unchanged.
; c87b76a: The final invisibility warning never removes the weapon. Its five
;          30-tick phases now alternate 50-percent checkerboard and normal
;          opaque rendering, ending with a permanently opaque weapon.
; c87b75a: During the final 150 invisibility ticks the 50-percent weapon
;          overlay follows five 30-tick phases: visible, hidden, visible,
;          hidden, visible. Existing pickup/status messages are drawn briefly
;          at the upper screen centre through the chunky top-HUD renderer.
; c87b74a-GenAmFix1: The normal fractional muzzle loop now reaches its
;                     shared exit with BGE.W instead of out-of-range BGE.S.
;                     No rendering or gameplay behaviour is changed.
; c87b74a: Invisibility renders the first-person weapon, recoil frame and
;          muzzle flash through a stable 1x1 checkerboard, exposing roughly
;          50 percent of the already-rendered background. Dead players still
;          hide the weapon completely. GenAm short-branch range is fixed.
; c87b73a: Invisibility now hides the complete first-person weapon overlay,
;          including recoil frame and muzzle flash, while leaving the HUD
;          and all accepted c87b72a fixes unchanged.
; c87b72a: Hearts four pixels nearer to LIVES. Wall-reflection fade now
;          keeps the uncut desired tail as its denominator, preventing
;          lower-edge columns from fading at different vertical rates.
;          Moving-wall ownership is accepted only when the candidate polygon
;          matches the actually visible wall depth and rendered texture.
; c87b71a-fix1: GenAm 3.18 range fix only. Seven data operands in the
;                 appended heart helper now use absolute relocatable
;                 addressing instead of out-of-range PC-relative forms.
;                 Runtime logic and all c87b71a features are unchanged.
; c87b71a: Replace LIVES skulls with an original-Gloom-style heart HUD icon;
;          keep near wall reflections geometrically one-to-one when clipped
;          by the lower screen edge; attach permanent wall blood stains to
;          their owning polygon so translating doors carry the stain along.
; GLOOM_REFORGED_PATCH11_GENAM_FIX1_BENCH_CONTINUATIONS
; GLOOM_REFORGED_PATCH11_040060_RELEASE_INTEGRATION
; Patch 8 flat split + corrected Patch 10 DITHER4 + Patch 11 aligned MOVE16
; Benchmark control is removed from every normal runtime/hot path.
; PATCH11_GENAM_FIX1_RAW_MOVE16
; PATCH11_040060_ALIGNED_MOVE16_CLEAR
; PATCH10_GENAM_FIX1_ABSOLUTE_RANGES
; PATCH10_040060_WALL_DITHER4
;c87b70s: Keep the classic P96 chooser at its fixed six-mode window height.
;         Place the Next/AGA/CANCEL group at the six-row position so systems
;         with fewer modes leave their spare space before Next, not below the
;         action buttons. Fill the upper information panel with the white pen.
;c87b70r: Reflow the classic P96 chooser vertically from the actual number
;         of available screen modes. Use full Topaz-8 line gaps between the
;         warning box, Select text, mode buttons, Next text and AGA/CANCEL.
;c87b70q: Correct the classic P96 chooser's vertical geometry for real
;         Intuition client areas: move the footer/action group upward,
;         guarantee a clear bottom margin above the window frame, and
;         use exact half-line gaps based on the Topaz 8 text cell.
;c87b70p: Polish the classic P96 chooser layout: complete info-panel border,
;         keep all bottom actions inside the client area, vertically center every
;         button label and codify half-line spacing around button groups.
;c87b70o: Rebuild the first P96 chooser with a real classic Intuition title bar,
;         fixed Topaz 8 body font, one full-width left-aligned mode button per
;         row and only AGA/CANCEL actions at the bottom. Keep direct centering.
;c87b70n: First P96 requester mode labels now use a comma and one space
;         between the resolution and its description. Includes c87b70m's
;         GenAm 3.18 branch-range buildfix; all P96MODEID, rendering, palette,
;         fire-rate and mouse-autofire behaviour is otherwise unchanged.
;c87b70m: GenAm 3.18 branch-range buildfix for c87b70l. The early DOS-base
;         failure branch in g2basic_log_reset now uses the normal word-displacement
;         conditional branch instead of the out-of-range short form. P96MODEID,
;         single-screen P96, requester styling, Classic palette, 80-percent fire
;         rate and mouse autofire are otherwise unchanged.
;c87b70l: Add validated P96MODEID=$xxxxxxxx ToolType/CLI override. A valid
;         supported 16-bit RGB565 ModeID configures its exact geometry and
;         skips both P96 requesters; invalid/stale IDs fall back to the normal
;         chooser. The active copy-ready ToolType is written prominently to
;         RAM:gloom_p96_modeid.txt and near the top of gloom_basic.log.
;         Rendering is unchanged: the existing framebuffer-zero test already
;         acts as an early floor/ceiling stencil before texture sampling.
;c87b70k: P96 opens only its one real custom screen. Remove the two obsolete
;         startup OpenScreen probes and keep the legacy planar title/menu buffers
;         strictly offscreen while DISPLAY=P96, so tools such as NewMode no
;         longer see three throwaway/custom bridge screens before the real RTG
;         screen. AGA/ECS screen handling is unchanged.
;c87b70j: Restyle the pre-centered P96 chooser with a colour title bar,
;         light information panel and native raised 3D buttons. All title,
;         explanatory, footer and button text is now font-aware and centered.
;         Visible requester labels use "Widescreen" instead of "Wide".
;         c87b70i branch-range buildfix, Classic palette, 80-percent fire rate
;         and mouse autofire remain unchanged.
;c87b70h: Replace the stage-1 BuildEasyRequestArgs/MoveWindow sequence with
;         a small native Intuition selection window whose final LeftEdge/TopEdge
;         are calculated from the locked public Screen before OpenWindow. The
;         first P96 chooser therefore appears centered in its first visible
;         frame, without the brief upper-left EasyRequester flash. Filtering,
;         warning text, Use AGA, CANCEL and the official stage-2 P96 requester
;         are unchanged. Gloom Classic palette and 80-percent fire rate remain.
;c87b70g: GenAm buildfix, centered first P96 requester and Classic-Gloom
;         gameplay palette rebuild. The two out-of-range player1/player2 reads
;         in predrawall now use absolute relocatable addressing. Stage-1 P96
;         selection is built with BuildEasyRequestArgs, centered on its actual
;         public screen with MoveWindow, then handled by SysReqHandler. For
;         profile 1 only, the live map_rgbs pool now replaces the embedded
;         Gloom-Deluxe palette/remap after every map load; AGA/P96 receive the
;         256-entry RGB12 palette layout, ECS the native packed palette layout,
;         and a complete nearest-colour RGB12 remap is generated for shading.
;         c87b70f's exact 80-percent fire rate and mouse autofire are unchanged.
;c87b70f: Player fire rate restored to exactly 80 percent of the original Gloom
;         long-term rate. The original interval (ob_reload+1) is multiplied by
;         5/4 with a per-player 2-bit fractional accumulator, so half/quarter
;         timing is distributed across consecutive shots instead of rounded.
;         KEYBMOUSE held-button autofire remains unchanged. Palette behaviour
;         is intentionally unchanged in this fire-rate-only test build.
;c87b70e: P96 palette test build. The gameplay RGB565 source LUT now uses
;         lastpal (the palette actually installed by pokepal) first and falls
;         back to planar_palette only when no active palette exists. The basic
;         log reads one central build-version string and appends palette source,
;         pointers, checksums/difference count plus a complete one-shot 256-entry
;         P96 palette mapping. No per-frame logging is added.
;c87b70d: Disable every legacy individual P96 RAM diagnostic writer.
;         c87b79i later removes those writers entirely. RAM:gloom_basic.log remains
;         active as the single compact runtime log; renderer, requesters,
;         screen probing, mode selection and P96 presentation are unchanged.
;c87b70c: P96 5:4 (320x256 and 640x512) now re-arms the persistent
;         direct-linear gameplay owner after an in-game RESOLUTION change,
;         exactly like the confirmed WIDE live-switch fix. Font rendering is
;         intentionally unchanged pending a mode-by-mode hardware comparison.
;c87b70b: Add a separate CANCEL gadget beside Use AGA in the first P96
;         requester. Use AGA keeps the planar fallback; CANCEL closes the
;         passive P96 library and aborts startup cleanly before initmain.
;c87b79k: First filtered requester describes the final native CLUT output.
;c87b70: P96 now opens a two-stage filtered screen-mode requester. The first
;         requester lists only available supported output sizes; the official
;         Picasso96 requester then shows only exact 16-bit RGB565 modes for
;         that size. WIDE, STRETCH, HIRES and 5:4 tokens are retired.
	;c87b69i: Rebuild wall-reflection length closer to ZGloom while keeping
	;          the confirmed c87b69g/h safe mirror contract. Desired source depth
	;          is now 45 percent of the visible wall height, clamped to 4..48
	;          rows. If the wall foot leaves fewer floor rows near the lower edge,
	;          the complete desired source span is proportionally sampled into the
	;          available destination rows: no source row is repeated, the target
	;          still begins directly below the real wall foot, and nothing shifts
	;          upward. Distance and normalized tail position control Bayer density.
	;c87b69h: Rebuild wall reflections on the confirmed c87b69g rollback,
	;          using ZGloom's safe one-source-row/one-target-row mirror geometry.
	;          Desired height now depends only on vd_z and grows monotonically
	;          from one row near four texture widths to sixteen rows point-blank.
	;          The result is clipped only to genuinely available source-wall and
	;          destination-floor rows; it is never shifted upward and no source
	;          row is repeated. Palette indices and the proven Bayer fade remain.
	;c87b69g: Roll back only the c87b69f wall-reflection rewrite after it
	;          produced vertical/longitudinal colour streaks. The exact stable
	;          c87b69e wall-column mirror path is restored: destination starts
	;          directly below the real wall foot, source rows mirror one-to-one,
	;          and available source/floor height clips the tail normally. The
	;          confirmed c87b69f live ONE PLAYER P96 WIDE RESOLUTION re-arm is
	;          retained unchanged. No other renderer/menu/config logic changed.
	;c87b69f: Fix live ONE PLAYER P96 WIDE RESOLUTION changes and rebuild the
	;          wall-reflection depth curve. Leaving the in-game menu after a
	;          RESOLUTION change now re-arms the already-open P96 WIDE linear
	;          owner before predrawall, so the new raster is used immediately.
	;          Wall reflections now grow monotonically from a two-row trace just
	;          inside four texture widths to twenty rows at point-blank distance. The
	;          complete tail is shifted upward at the lower edge instead of being
	;          shortened, and source sampling clamps safely at the wall top.
	;c87b69e: Fix ONE PLAYER P96 WIDE RESOLUTION and near reflection shrink.
	;          Native WIDE now keeps its full 428-pixel field of view while
	;          RESOLUTION renders a compact 200/214-pixel X raster, and all
	;          WIDE/5:4 projection helpers use the saved native dimensions.
	;          Enemy and projectile/upgrade reflections no longer lose visible
	;          height when their projected floor anchor approaches the lower
	;          safety edge; the complete prepared tail is shifted upward to fit.
	;c87b69d: Rename the third VIOLENCE MODE from BLOODY to NASTY.
	;          The visible menu field remains exactly 20 characters by
	;          retaining one trailing space, preserving binary alignment.
	;          Mode value, gameplay logic, STOCK lock and effects are unchanged.
	;c87b69c: Fix TWO PLAYER 2x2 aspect/projection. The five shared Y-scale
	;          helpers still used the former LOW/TURBO encoding and halved Y
	;          only for mode 2. In the new RESOLUTION encoding, both 1x2 (2)
	;          and 2x2 (3) need half-height projection. Modes 2 and 3 now take
	;          the same split-local Y scale/unscale path; 1x1/2x1 are unchanged.
	;c87b69b: GenAm 3.18 buildfix only. Early gun/clear helpers had grown
	;          beyond the signed 16-bit PC-relative range to the late data
	;          block. Twenty-one affected/borderline data operands now use
	;          absolute relocatable addressing. Runtime logic is unchanged.
	;c87b69a: GenAm 3.18 buildfix only. Two alignment directives that
	;          accidentally started in label column are indented correctly.
	;          Runtime logic and all c87b69 features are unchanged.
	;gloombench2 baseline: current Gloom Reforged engine with automatic
	;                     map1_1 257-frame reference flight. No FastRAM or
	;                     texture-rendering experiments are enabled.
	;c87b69: Final Gloombench 3O integration and RESOLUTION menu redesign.
	;         Removes WINDOW SIZE/FULL SCREEN and the LOW/TURBO ToolTypes/CLI.
	;         Adds saved 1x1/2x1/1x2/2x2 world resolution for ECS, AGA and
	;         P96 (plain/STRETCH/WIDE/5:4), in ONE PLAYER and TWO PLAYER.
	;         Weapon, muzzle flash, HUD, menus, FPS and final output stay native.
	;         Integrates FLAT4, CLEAR16 and WALL2; 020/030 use GEN C2P,
	;         040/060 use K040 C2P. STOCK now locks NASTY out and bypasses
	;         every Reforged-only fog/reflection/shadow/decal/tint calculation.
	;         The temporary 32-item STOCK budgets are removed: classic MEATY/
	;         MESSY object and gore processing remains unrestricted.
	;c87b68b: Fix STOCK blood/gore budgets. The c87b68 reverse-list walkers
	;          could re-enter the old forward loop and clobber live render
	;          state. Budgets now use the proven forward traversal with a
	;          simple 32-item counter. Enemies, gun and projectiles untouched.
	;c87b68a: GenAm 3.18 buildfix only. Eight newly out-of-range PC-relative
	;          accesses in panel/weapon/object code use absolute relocatable
	;          addressing. Runtime logic and STOCK behaviour are unchanged.
	;c87b68: STOCK now also removes the remaining reflection preparation/calls,
	;         skips NASTY floor pools and wall stains, and limits submitted
	;         flying blood particles and resting gore chunks to 32 per view.
	;         Violence mode and all saved gloom.cfg choices remain unchanged.
	;c87b67: STOCK is now a pure runtime override and never rewrites the saved
	;         BLOB SHADOWS, REFLECTIONS or VISIBILITY choices in gloom.cfg.
	;         The loaded values are preserved separately; gameplay/menu still
	;         stay locked to NO / NO / DEFAULT for the complete STOCK session.
	;c87b66: STOCK now also permanently locks VISIBILITY to DEFAULT.
	;         Loaded ADVANCED values are overridden after cfg load and the
	;         in-game visibility row cannot re-enable ADVANCED while STOCK runs.
	;c87b65: STOCK now permanently locks BLOB SHADOWS and REFLECTIONS to OFF.
	;         Loaded gloom.cfg values are overridden after load, both in-game
	;         menu rows remain NO and their toggle actions cannot re-enable them.
	;c87b64: Extend STOCK to restore the original Gloom distance-shade table.
	;         The Reforged one-step dark boost and stronger 4..8-width fog
	;         ramp are skipped when STOCK is active. Original distance shading,
	;         clipping and disabled-flat/void filling remain intact.
	;c87b62a: GenAm buildfix only: first TWO PLAYER player-null branch changed
	;          from short to word range. Runtime logic is unchanged.
	;c87b63: Add bare ToolType/CLI token STOCK. STOCK disables ordered Bayer
	;         shade blending on floors, ceilings and solid walls. Reflection
	;         renderers keep their normal geometry/colour but bypass Bayer
	;         masks, allowing a focused performance comparison on 68060 AGA.
		;c87b62: Integrate the existing LOW and TURBO tokens into planar TWO PLAYER
	;         FULLSCREEN without adding new ToolTypes. Each split half keeps the
	;         established 320x120 presentation and native HUD: LOW renders the
	;         3D world at 160x120, TURBO at 160x60, then expands in place.
	;         Smaller 2P WINDOW SIZE, P96 and incompatible layouts retain c87b40.
	;c87b61: Clean release based directly on stable c87b43. Adds optional bare
	;         ToolType/CLI token TURBO for a 160x120 3D world expanded 2x2
	;         before native-width weapon/HUD/C2P. Keeps existing LOW.
	;         No PROFILE2, early-outs, FASTRAM, sprite reciprocal, decal budget,
	;         inner-loop unroll or direct-planar C2P experiment.
	;c87b43: Optional bare ToolType LOW renders the planar one-player
	;         FULLSCREEN 3D world at 160x240, expands it in-place to
	;         320x240, then draws weapon and HUD at native width.
	;c87b40: Enable the CPU-selected Kalm C2P for planar TWO PLAYER.  Both
	;         split views now render into one true linear 320x240 chunky frame;
	;         centred per-player WINDOW SIZE crops and full-width HUD passes
	;         rebuild coloffs according to the active linear/legacy owner.
	;         P96 and every incompatible layout retain the proven fallback.
	;c87b39: GenAm range fix for g2render_center_x; REFLECTIONS remains NO/WEAPON/ALL.
	;         WEAPON draws fired-shot and weapon-upgrade reflections only;
	;         ALL additionally enables enemy/player and wall reflections.
	;         Historic saved value +1 remains ALL; new WEAPON uses +2.
	;c87b34: Integrated Kalm's CPU-selected planar C2P path. 68020 uses GEN,
	;         68030 uses the 030 SMC converter, and 68040/68060 use the 040
	;         converter. Unsupported/non-contiguous passes retain the proven
	;         BlackMagic-compatible fallback.
	;c87b33: Zombie Massacre ECS title uses an offline-precomposed Fast-EHB
	;         main title plus a separate clean title_base for ABOUT.  The slow
	;         runtime g3-dc decode/remap is no longer entered on ECS.
	;c87b32: Gloom3/Zombie Massacre ECS intermission palettes are embedded
	;         directly into fixed 128-byte storage at every pict_ command,
	;         including commands processed while START LEVEL skips episodes.
	;         No temporary AllocMem palette buffer is required, so low/free
	;         memory after later episodes cannot leave picpal NULL or reuse an
	;         older picture palette.  draw_ uses only the matching fixed cache.

	;c87b29: Gloom3/Zombie Massacre ECS reload the exact generated .pal file
	;         immediately before every visible draw_.  Superseded by c87b31.

	;c87b28a: GenAm buildfix only: one out-of-range viewport reference made absolute.
	;c87b28: Gloom3/Zombie Massacre ECS intermission palettes are copied to
	;         private stable 128-byte storage whenever pict_ loads or reloads
	;         them.  scriptdraw no longer depends on a mutable loadfile buffer
	;         across gameplay, episode/START LEVEL changes or allocator reuse.

	;c87b27: Zombie Massacre Fast-EHB title brush is fully opaque on ECS.
	;         Source index 0 stays black instead of restoring the title below it.
	;         The obsolete RAM:gloom_p96_glyphcache.txt writer was later removed;
	;         RAM:gloom_basic.log remains the single compact diagnostic log.

	;c87b26a: GenAm buildfix only: startup exit branch changed from short to word range.

	;c87b26: Add compact RAM:gloom_basic.log snapshots for startup, title,
	;         gameplay and P96 linear activation.  Logs selected mode/profile,
	;         target/render/view geometry and source image dimensions.
	;c87b25: NASTY floor pools and stored wall splashes now use the shared
	;         distance/darktable fog mapping.  Mobile blood already used this
	;         path; world decals now fade consistently with geometry and actors.
	;c87b24: Zombie Massacre Fast-EHB loads pixs_ehb/g3-dc as a separate
	;         title/menu brush.  The brush is drawn at the lower title edge and
	;         remains absent from ABOUT, matching the AGA/P96 presentation.
	;c87b23: ECS Gloom3/ZM correction.  Intermissions keep their generated EHB
	;         palette instead of selecting the embedded AGA palette.  Zombie
	;         Massacre can be detected by pixs_ehb/title in ECS mode and accepts
	;         optional palette_6/remap_6 fallbacks below pixs_ehb or stuf.
	;c87b22a: GenAm buildfix only: one out-of-range short profile-detection branch.
	;c87b22: Enable editor-generated Fast-EHB packages for Gloom3 and Zombie Massacre.
	;         Gloom3 uses pics_ehb, Zombie Massacre uses pixs_ehb; their direct
	;         six-plane titles need neither title_base nor a runtime title overlay.
	;c87b18b: GenAm buildfix: seedrnd2 long call.
;c87b18a: GenAm buildfix for two invalid EOR memory-source operands.
;c87b21b: GenAm buildfix only: one out-of-range palettes access made absolute.
;c87b21a: GenAm buildfix only: five newly out-of-range PC-relative data accesses.
;c87b21: Adaptive world-decal rasterisation for true visual size scaling.
;         Physical size/anchors remain fixed; floor and wall sampling density
;         now follows projected screen size instead of a fixed point count.
;c87b20a: Safe near-perspective correction based on stable c87b19a.
;          The faulty c87b20 subpixel/clamped-endpoint renderer is removed.
;          Near plane lowered carefully; off-screen points are rejected.
;c87b19a: GenAm buildfix only: eight out-of-range PC data references and
;          one short branch changed to range-safe forms.
;c87b19: World-fixed NASTY decals. Floor pools use a seed-fixed world
;         orientation and true endpoint projection; nearby wall splashes
;         receive a permanent world/wall anchor when the gore settles.
;c87b18: Restore the original compact irregular pool style, but project it
;         row-by-row on the floor plane. Per-column wall depth clipping
;         converts only adjacent overlap into vertical wall splashes.
;c87b17: Add NASTY VIOLENCE MODE and true distance-scaled blood pools.
;         MEATY=no gore, MESSY=classic gore, NASTY=gore plus pools.
;c87b16a: GenAm buildfix only: replace eight newly out-of-range PC/BSR references.
;c87b16: MESSY-only procedural ground blood-pool test for resting gore chunks.
;         Deterministic irregular oval plus small side splatters; no external art.
;c87b14: Fast-EHB runtime contract: precomposed title, title_base ABOUT,
	;         reserved font indices and no ECS runtime picture/brush remapping.
	;c87b12: ECS test-release menu/static-screen performance and refresh fixes.
	;c87b11: public release v1.8; internal version ID advanced from c87b10.
	;ECS9b_NO_DH3_LOGGING: disable persistent ECS stage/asset file writes
	;while retaining core asset validation, visible missing-file warning,
	;A600 ECS path and the proven Gloom3/Zombie Massacre preflight guard.

	;ECS8_ATOMIC_TITLE_BRUSHMAP: preserve the brush source-colour count
	;outside the RGB-distance return register, and defer the ECS title-font
	;palette change until the prepared menu bitmap has reached VBlank.

	;ECS7_EXACT_FONT_TRANSPARENT_BRUSH: exact Bigfont colours without a
	;preliminary blitter glyph, remap picture indices 1..3/33..35 before
	;font palette activation, preserve brush index 0 as transparency, and
	;match brush colours against all 64 visible EHB title indices.

	;ECS6_TITLE_BRUSH_FONT: load pics_ehb/gloom.pal, remap the ECS brush
	;to title.pal after planar decode, and draw title-menu glyphs without
	;overwriting title palette entries 0..3 or injecting ECS separator dots.

	;ECS5_BLACKMAGIC_BRUSH: restore original shared six-plane BlackMagic image,
	;use ECS-only palette, draw non-P96 brushes through direct planar decode,
	;and log the optional ECS title brush without treating it as a core failure.

	;ECS4_STATIC_SCREENS: matching pics_ehb/blackmagic image+palette, ECS title brush loading/drawing,
	;and isolated intermission glyph colours without modifying picture palette entries 0..3.

	;ECS3_CLASSIC_PATHS_STAGELOG: Classic ECS paths fixed, Classic BlackMagic skipped until a matching EHB pair exists,
	;both ECS bitmaps cleared before screen visibility; DH3 diagnostics disabled in ECS9b.
; Gloom Reforged v1.8 - internal source revision c87b27 - ToolType 5:4
; c87p3: true P96 5:4 TWO PLAYER 128+128 rows; restore QUIT after FLOOR/CEILING.
; c87p2: fix P96 5:4 menu Y mapping without moving existing labels.
; Cache origins own +8/+16; direct writes and title restores apply it once.
; c87p1: P96-only 5:4 mode: true 320x256 / 640x512 vertical rendering and centred static art.
;c87w6: redraw QUIT through the proven navigation path after FLOOR/CEILING release completes.
;c87w4: after FLOOR/CEILING live redraw, explicitly restore and redraw the final QUIT row once.
;        Uses the proven single-row path; all existing WIDE/2P/AGA behaviour remains unchanged.
;c87w3: fix ONE PLAYER native-WIDE in-game menu row restore; restore the full 428 source row
;        (and exact 854-pixel 2x output) before redrawing the centred menu glyphs. TWO PLAYER unchanged.
;c87w2: GenAm build fix for WIDE1; only out-of-range branches/data references changed.
;c87w1: fresh native P96 widescreen rebuilt directly from confirmed c87b10.

 	;*********
	;* GLOOM *
	;*********
	;
	;planar, 020+ version.
	;v190hy: cleanup build from stable v190hx12, old RAM:gloom.log diagnostics removed.
	;v190hy2: keep Gloom3 intermission picture palette; skip font palette override there.
	;gloom2p96_c21: restore readable tonal pens with stronger contrast, no palette init.
	;gloom2p96_c25: expand each 160-byte preview row into a 320-byte linebuffer before runfill.
	;gloom2p96_c26: mirror expanded 320x192 rows into a full linear framebuffer.
	;gloom2p96_c28: keep the throttled 320x192 mirror and draw one tiny proof stripe from that mirror.
	;gloom2p96_c32: compact non-overlapping framebuffer readback window at the bottom.
	;gloom2p96_c33: draw the main preview from the 320x192 framebuffer mirror, bottom probe disabled.
	;gloom2p96_c37: fix old fallback mask so palette path can really use pens 1..63.
	;gloom2p96_c43: prepare a real 24-bit RGB linebuffer from true RGB12 samples.
	;gloom2p96_c49: rollback c48 RGB24 bottom buffer; keep c47 RGB12 dense bottom probe.
	;gloom2p96_c50: direct RGB24 linebuffer bottom probe, no extra bottom buffer.
	;gloom2p96_c51: taller 48px direct RGB24 bottom probe, no extra bottom buffer.
	;gloom2p96_c59: re-enable P96 after two-player fixes; keep P96 skipped during TWO PLAYER.
	;gloom2p96_c60b: safe rollback from c60/c60a static ARGB startup probe crash; back to c59 P96 path.
	;gloom2p96_c86zc7: rollback to c86zc4 enemy reflections, wall reflections off, no dark remap; less dither/more stable pixels near the floor seam.
	;gloom2_c86zcn: clean c86zc7 enemy-reflection behaviour restored; keep only TWO PLAYER player1/player2 mirror reflections.
	;gloom2_c86zco: conservative wall reflections re-enabled, using the same mirrored-column/Bayer logic family as enemy/player reflections.
	;gloom2_c86zct: rollback of c86zcp/c86zcq/c86zcr/c86zcs pickup/upgrade reflection experiments; keep c86zco enemy/player/wall reflections only.
	;gloom2_c86zcu: keep c86zct/no-pickup base, but draw projectile/weapon-upgrade glow reflections before their owning bitmap again.
	;gloom2_c86zcv: cleanup non-working non-weapon token reflection branches; keep projectiles, weapon upgrades, bouncy upgrade, enemy/player/wall reflections.
	;gloom2_c86zcw: wall reflections no longer require FLOOR YES; they draw over disabled-floor fog like projectile/weapon reflections.
	;gloom2_c86zdc: rollback fallback to 1.3.2 plus only grey-screen/mouse-pointer startup guards for failed OpenScreen/OpenWindow; no depth-click experiments.
	;gloom2_c86zde: move 1.3.3 ASCII release marker directly behind startup jump so it appears near the start of the executable.
	;gloom2_c86zdh: projectile/weapon-upgrade reflections keep their stable width, but get a thicker vertical oval centre when close.
;gloom2_c86zdi: stronger near vertical oval, whole projectile/upgrade reflection Bayer-dithered, weapon-upgrade floor-touch pulse.
	;gloom2_c86zdj: smooth weapon-upgrade pulse up to 2x and rounder vertical oval profile without T-shaped centre.
	;gloom2_c86zdo: projectile/upgrade far fade kept; weapon-upgrade pulse capped at 1.5x with edge-only oval swell.
	;gloom2_c86zdp: weapon-upgrade pulse now redraws scaled oval columns instead of stamping edge pixels.
	;gloom2_c86zdq: weapon-upgrade true scaled pulse extended to about 1.8x, with a slightly longer envelope; release marker v1.4.
	;gloom2_c86zdr: weapon-upgrade reflections keep near height, but are vertically thinner from about 2 texture widths outward.
	;gloom2_c86zdu: restrict Zombie-Massacre pre-dispon title overlay to profile 2; restore c86zc7 post-dispon brush timing for Classic Gloom/Gloom Deluxe.
	;c86zhz: ignore disabled icon ToolTypes in parentheses, e.g. (DISPLAY=P96).
	;c86zjg: keep c86zjf stable doublebuffer/menu bridge and decode static planar screens row-wise for faster P96 title/intermission presents.
	;c86zjn: restore P96 intermission typewriter with direct cached Bigfont glyph writes; ENTER skips immediately; add ScreenBuffer lifecycle diagnostic.
	;c86zjl: direct P96 trimmed-IFF decoder writes planar compatibility data and a linear 320x240 index composition buffer in one pass; static presents no longer read the planar bitmap back.
	;c86zjm: diagnostic only: log gameplay memory placement/types and free/largest public, fast and chip blocks once when linear P96 gameplay activates.
	;c86zjh: decode real Bigfont menu rows and saved planar backgrounds once per row, then write only deltas directly into the existing P96 RAM batch.
	;c86zji: P96 menu blink and up/down navigation reuse cached real-Bigfont rows directly; no live Amiga blitter or printmess2 calls on the navigation cadence.
	;c86zjj: build one exact 40-glyph Bigfont cache, then compose first P96 menus, blink, navigation and dynamic rows directly from linear glyph indices.
	;c86zjf: keep c86zje gameplay ScreenBuffer double buffering, but bind Window.RPort
	;to the actually visible ScreenBuffer while menu/title/intermission bridges draw.
	;c86zje: P96 gameplay ScreenBuffer double-buffer probe on confirmed linear chunky source.
	;c86zjq: trap right mouse button in every P96 window so Intuition cannot reveal/switch screens.
	;c87a7: optional true presented-FPS counter selected by bare FPS ToolType.
	;No in-game menu entry and no gloom.cfg persistence.  The counter shows
	;exactly two white 5x7 digits.  It measures every real gameplay present,
	;but latches each displayed value for at least one full second.
	;c86zkm: clean display ToolType/CLI selector on the stable c86zjr base.
	;Accept only bare AGA/ECS/P96/HIRES/STRETCH/WIDE/FPS tokens; legacy DISPLAY=
	;and =YES/=NO forms are no longer parsed.  Default is hardware based:
	;AGA on AGA, ECS on ECS.  ECS is safely gated until its renderer exists.
	;c86zjc: confirmed P96 RGB565 format autoswap: RGBFB_R5G6B5PC ($04) swaps bytes,
	;RGBFB_R5G6B5 ($0A) stays native; all RAM diagnostic log calls disabled.
	;c86zjd: first guarded linear-chunky P96 gameplay probe.  After one confirmed
	;legacy-layout P96 frame, coloffs becomes 0..319 for direct row-major rendering.
	;AGA, TWO PLAYER, title/intermission and any P96 failure restore C2P coloffs.
	;c86zhk: reset P96 gameplay startup delay and clear RTG again when a new game starts,
	;so an old gameplay frame can not be presented before the next intermission.
	;c86zhj: clear stale P96 frames on title/intermission handoff and hard-gate P96 row hooks for AGA blink.
	;c86zhf: add targeted P96 BlackMagic startup bridge and intermission text present; keep remote-link crash parked.
	;c86zhe: keep c86zhd speed/disabled-row fix, but rollback unsafe ABOUT cache and rebuild title cache before qmenu after gameplay.
	;c86zhb: rollback c86zha title speed path; safe P96 qmenu background restore only.
	;gloom2_c86zdw: add safe P96 library probe after DISPLAY selection; log to DH3; no ModeID/screen/window/output yet.
	;gloom2_c86zdx: add passive 320x240 ModeID probe; no screen/window/output.
	;gloom2_c86zdz: add passive P96 custom-screen borderless-window probe; close immediately, log only.
	;gloom2_c86zec: P96 menu/input probe on custom screen/window; closes by IDCMP or fire/mouse.
	;gloom2_c86zei: visible gameplay stripe diagnostic after c86zeh grey-screen result.
	;c86zfb: P96 gameplay-primary lifecycle fix.
	;c86zfc: Intermission/script lifecycle restore fix.
	;c86zfd: Real-hardware smoke-test anchor, no feature expansion after c86zfc.
	;Open P96 immediately on gameplay entry to hide the short AGA handoff, keep the
	;confirmed c86zex/c86zey delayed copy before skipping AGA, hide the P96 mouse
	;pointer, and force-close P96 again when ESC/menu/title/exit paths take over.
	;c86zfo: clear the P96 bitmap to black before lifecycle close to avoid stale
	;render stills between level teleport and intermission, and overlay the right
	;80px HUD area 1:1 in 240p widescreen so life heads are not pushed/cropped.
	;c86zgb: buildfix only: removed zero-distance bra.s in menu backdrop path
	;c86zga: rollback rejected dim/black-rect menu overlay attempts; P96 in-game
	;menu now overlays text over a paused gameplay backdrop, restores menu rows
	;from gameplay, and hides HUD through the chunky source before P96 copy.
	;c86zgs: keep c86zgq slow P96-only Bigfont blink, add navigation guard
	;selected-row blink without optoff/opton rebuilds every few frames.
	;c86zgh: batch-cache the complete P96 in-game menu text area and flush it
	;linearly once, so initial open and FLOOR/CEILING refresh no longer reveal
	;row-by-row/glyph-by-glyph construction on real RTG hardware.
	;c87b4: prefer exact 428x240/854x480 STRETCH modes, remove title-menu
	;combat/remote-link rows while retaining ONE PLAYER level selection, and
	;limit static-picture palette reads to the source image depth (64/128/256).
	;c87b5: ignore gloomgame completely.  It is neither loaded nor saved and
	;does not create CONTINUE FROM entries.  Gloom3 profile detection now uses
	;stable game-data probes instead of the presence/absence of gloomgame.
	;c86zgi: turbo P96 menu text path.  Initial menu draw uses compact cached
	;native glyph output instead of scanning the planar menu bitmap pixel-by-pixel.
	;FLOOR/CEILING no longer rebuilds the paused gameplay backdrop/menu page; it
	;updates only the changed selected row while the menu stays visible.
	;
	;6 bitplanes for ECS, 8 for AGA
	;
	;error codes
	;
	;red - allocmem failed
	;yel - freemem failed
	;orange - unknown script command
	;purp - unknown event command
	;cyn - can't open file in loadfile
	;blu - ran out of remap colours!

; ECS1: aga_ is only the initial value of the runtime variable 'aga'.
; It is not a DevPac conditional-assembly switch.
aga_	equ	-1
os_	equ	-1

testw	equ	128
testh	equ	128

; c87w1: maximum native P96 WIDE source geometry.
g2render_max_width	equ	428
g2render_height_const	equ	256

cd32	equ	0	;cd32 version?
combatok	equ	-1	;include combat game?
ok	equ	750+125	;overkill level!
cy	equ	166

pl_eyey	equ	110
pl_firey	equ	60
pl_gutsy	equ	64

debugser	equ	0
debugmem	equ	0
	;
ireload	equ	5	;initial reload val.
maxobjects	equ	256	;max objects in game
maxdoors	equ	16	;max doors opening at once
maxblood	equ	96	; c87b78a: lower active droplet ceiling
maxgore	equ	96	; c87b78a: lower persistent gore/decal ceiling
maxrotpolys	equ	32	;max rotating thingys.
	;
focshft	equ	7
grdshft	equ	8
darkshft	equ	7	;smaller=smaller range=faster!
maxz	equ	16<<darkshft	;16*128=2048*8=16384
g2deffogfar	equ	8<<grdshft	; v190fc: shared darktable cap; DEFAULT keeps original range, ADVANCED scales to it
g2advviewfar	equ	16<<grdshft	; v190fc: ADVANCED actual view/fog range = 16 texture widths
g2advshapez	equ	16<<grdshft	; v190fc: ADVANCED strips/objects match the 16-width range
	;
exshft	equ	3
exone	equ	1<<exshft
exhalf	equ	exone>>1

	jmp	entrypoint
	; v2.2: public release marker; ECS/AGA/P96 remain official runtime paths.
g2release_marker	dc.b	'Gloom Reforged v2.2 (c87b80p) by Andreas ',39,'Andiweli',39,' Stuermer',0
	even

	rsreset
	;
	;rotpoly details...
	;
rp_next	rs.l	1
rp_prev	rs.l	1
	;
rp_speed	rs.w	1
rp_rot	rs.w	1
rp_flags	rs.w	1	;what to do?
	;
rp_cx	rs.w	1	;only for rot
rp_cz	rs.w	1
rp_first	rs.l	1	;pointer to first!
rp_num	rs.w	1
	;
rp_vx	rs.w	0
rp_lx	rs.w	1
rp_vz	rs.w	0
rp_lz	rs.w	1
rp_ox	rs.w	0
rp_na	rs.w	1
rp_oz	rs.w	0
rp_nb	rs.w	1
	;
rp_more	rs.b	8*31	;=32 max verts!
	;
rp_size	rs.b	0

	rsreset
	;
	;sfx channel info
	;
fx_status	rs.w	1
fx_priority	rs.w	1
fx_sfx	rs.l	1
fx_vol	rs.w	1
fx_offset	rs.w	1
fx_dma	rs.w	1
fx_int	rs.w	1
	;
fx_size	rs.b	0

	rsreset
	;
	;blood!
	;
bl_next	rs.l	1
bl_prev	rs.l	1
bl_x	rs.l	1
bl_y	rs.l	1
bl_z	rs.l	1
bl_xvec	rs.l	1
bl_dest	rs.l	0
bl_yvec	rs.l	1
bl_zvec	rs.l	1
bl_color	rs.l	1	;colour and!
	;
bl_size	rs.b	0

	rsreset
	;
	;a texture
	;
te_pal	rs.l	1
	;
te_size	rs.b	0

	rsreset
	;
	;an opening/closing door!
	;
do_next	rs.l	1
do_prev	rs.l	1
do_poly	rs.l	1	;door polygon
do_lx	rs.w	1
do_lz	rs.w	1
do_rx	rs.w	1
do_rz	rs.w	1
do_frac	rs.w	1
do_fracadd	rs.w	1
	;
do_size	rs.b	0

	rsreset
	;
	;wall list...
	;
wl_next	rs.l	1
wl_lsx	rs.w	1	;leftmost screen X
wl_rsx	rs.w	1	;rightmost screen X
wl_nz	rs.w	1	;near Z!
wl_fz	rs.w	1	;far Z!
wl_lx	rs.w	1
wl_lz	rs.w	1
wl_rx	rs.w	1
wl_rz	rs.w	1
wl_a	rs.w	1
wl_b	rs.w	1
wl_c	rs.l	1
wl_sc	rs.w	1
wl_open	rs.w	1	;0=door shut, $4000=open!
wl_t	rs.b	8	;textures
	;
wl_size	rs.b	0

	rsreset
	;
	;a zone...
	;
zo_done	rs.w	1
zo_lx	rs.w	1
zo_lz	rs.w	1
zo_rx	rs.w	1
zo_rz	rs.w	1
	;
zo_a	rs.w	1
zo_b	rs.w	1
zo_na	rs.w	1
zo_nb	rs.w	1
zo_ln	rs.w	1
	;
zo_t	rs.b	8	;8 textures
	;
zo_sc	rs.w	1	;scale (how many txts on wall)
zo_open	rs.w	0	;for wall polys...
zo_ev	rs.w	1	;for events...
	;
zo_size	rs.b	0	;32!

	rsreset
	;
	;a shape to draw!
	;
sh_next	rs.l	1
sh_prev	rs.l	1
sh_x	rs.w	1
sh_y	rs.w	1
sh_z	rs.w	1
sh_shape	rs.l	1
sh_scale	rs.w	0
sh_strip	rs.l	1
sh_render	rs.l	1	;drawobjnorm or drawobjinvs
	;
sh_size	rs.b	0

	rsreset
	;
	;gore...body parts lying around!
	;
go_next	rs.l	1
go_prev	rs.l	1
go_x	rs.w	1
go_z	rs.w	1
go_shape	rs.l	1
; c87b16: optional deterministic procedural blood pool.
; A zero seed means no pool; non-zero is used only by NASTY mode.
go_pool_seed	rs.w	1
go_pool_size	rs.w	1
; c87b19: optional wall stain, generated once at rest and stored in world space.
go_pool_wall	rs.w	1
go_pool_wallx	rs.w	1
go_pool_wallz	rs.w	1
go_pool_walltx	rs.w	1
go_pool_walltz	rs.w	1
; c87b71a: moving-wall ownership. The relative X/Z offset is measured from
; the owning polygon's live left endpoint, so sliding doors carry decals.
go_pool_wallpoly	rs.l	1
go_pool_wallrelx	rs.w	1
go_pool_wallrelz	rs.w	1
	;
go_size	rs.b	0

	rsreset
	;
	;an object in the game (player/alien etc...)
	;
ob_next	rs.l	1
ob_prev	rs.l	1
ob_x	rs.l	1
ob_y	rs.l	1
ob_z	rs.l	1
ob_rot	rs.l	1
	;
	;start of info load by prog.
ob_info	rs.b	0
	;
ob_rotspeed	rs.l	1
ob_movspeed	rs.l	1
ob_shape	rs.l	1
ob_logic	rs.l	1
ob_render	rs.l	1
ob_hit	rs.l	1	;routine to do when damaged
ob_die	rs.l	1	;routine to do when killed
ob_eyey	rs.w	1	;eye height
ob_firey	rs.w	1	;where bullets come from
ob_gutsy	rs.w	1
ob_mega	rs.w	0
ob_othery	rs.w	1
ob_colltype	rs.w	1
ob_collwith	rs.w	1
ob_cntrl	rs.w	1
ob_damage	rs.w	1
ob_hitpoints	rs.w	1
ob_think	rs.w	1
ob_frame	rs.l	1	;anim frame
ob_framespeed	rs.l	1	;anim frame
ob_base	rs.w	1
ob_range	rs.w	1
ob_weapon	rs.w	1	;weapon meter (0...4)
ob_reload	rs.b	1	;weapon reload timer
ob_reloadcnt	rs.b	1	;counter
ob_hurtpause	rs.w	1
ob_firerate	rs.w	0
ob_punchrate	rs.w	1
ob_bouncecnt	rs.w	1	;how many times my bullets bounce!
ob_firecnt	rs.w	0
ob_something	rs.w	1
ob_scale	rs.w	1	;scale factor for drawing
ob_lastbut	rs.w	1
ob_blood	rs.w	1	;color AND for blood
ob_ypad	rs.w	1
	;
ob_oldlogic	rs.l	1
ob_oldlogic2	rs.l	1
ob_oldhit	rs.l	1
ob_olddie	rs.l	1
ob_oldrot	rs.w	1
ob_newrot	rs.w	1
ob_yvec	rs.l	1
ob_xvec	rs.l	1
ob_zvec	rs.l	1
ob_radsq	rs.l	1	;radius squared
ob_rad	rs.w	1
ob_delay	rs.w	1
ob_delay2	rs.w	0
ob_bounce	rs.w	1
ob_hurtwait	rs.w	1
	;
ob_washit	rs.l	1	;flag for un-hit coll detect!
ob_window	rs.l	1	;pointer back to window!
ob_nxvec	rs.w	0	;normalized X vec
ob_lives	rs.w	1
ob_nzvec	rs.w	0	;normalized z vec
ob_infra	rs.w	1
ob_thermo	rs.w	1
ob_invisible	rs.w	1
ob_hyper	rs.w	1
ob_update	rs.w	1	;update stats!
ob_mess	rs.l	1	;message
ob_messlen	rs.w	1
ob_messtimer	rs.w	1	;timer for messages
ob_palette	rs.l	1	;palette for window
ob_paltimer	rs.w	1	;timer before back to normal
ob_pixsize	rs.w	1
ob_pixsizeadd	rs.w	1
ob_telex	rs.w	1
ob_telez	rs.w	1
ob_telerot	rs.w	1
ob_chunks	rs.l	1
	;
ob_size	rs.b	0

	rsreset
	;
	;solid wall draw data
	;
vd_z	rs.w	1	;current Z
vd_pal	rs.w	1	;palette# (0...15)
vd_y	rs.w	1
vd_h	rs.w	1
vd_data	rs.l	1
vd_ystep	rs.l	1
	;
vd_size	rs.b	0

	rsreset
	;
	;palette file...
	;
pa_numcols	rs.w	1	;how many colours
pa_cols	rs.w	256	;the colours!

	rsreset
	;
	;anim file...
	;
an_rotshft	rs.w	1
an_frames	rs.w	1
an_maxw	rs.w	1
an_maxh	rs.w	1
an_pal	rs.l	1
	;
an_size	rs.b	0

	rsreset
	;
	;window
	;
wi_slice	rs.l	1	;slice window appears in!
wi_nslice	rs.l	1	;next slice to disp.
wi_x	rs	1
wi_y	rs	1
wi_w	rs	1	;how many chixels across
wi_h	rs	1	;how many down
wi_pw	rs	1	;width of 1 chixel
wi_ph	rs	1	;hite of 1 chixel
	;
wi_bw	rs	1	;bitmap width
wi_bh	rs	1	;bitmap height
	;
wi_bmapmem	rs.l	1
wi_copmem	rs.l	1
wi_bmap	rs.l	1
wi_cop	rs.l	1
wi_cop1	rs.l	1
wi_cop2	rs.l	1
wi_chunkymodw	rs.w	1
	;
wi_strip	rs.l	1
wi_iff	rs.l	1	;show iff instead!
wi_pal	rs.l	1	;palette for IFF!
	;
wi_size	rs.b	0

key	macro
	btst	#\1&7,\1>>3(a0)
	endm

keya1	macro
	btst	#\1&7,\1>>3(a1)
	endm

qkey	macro
	move.l	rawtable,a0
	key	\1
	endm

freemem	macro
	;
	ifne	debugmem
	lea	.fmem\@,a0
	jsr	freemem_
	bra	.fmemskip\@
.fmem\@	dc.b	'\1',0
	even
.fmemskip\@	;
	elseif
	jsr	freemem_
	endc
	;
	endm

allocmem	macro
	;
	ifne	debugmem
	;
	lea	.amem\@,a0
	jsr	allocmem_
	bra	.amemskip\@
.amem\@	dc.b	'\1',10,0
	even
.amemskip\@	;
	elseif
	;
	jsr	allocmem_
	;
	endc
	;
	endm

allocmem2	macro
	;
	ifne	debugmem
	;
	lea	.amem\@,a0
	jsr	allocmem2_
	bra	.amemskip\@
.amem\@	dc.b	'\1',10,0
	even
.amemskip\@	;
	elseif
	;
	jsr	allocmem2_
	;
	endc
	;
	endm

alloclist	macro	;alloclist listname,maxitems,itemsize
	;
	move.l	\2,d0
	move.l	\3,d1
	lea	\1(pc),a2
	jsr	k_alloclist
	bra.s	alskip\@
	;
\1	dc.l	0	;0
\1_last	dc.l	0	;4
	dc.l	0	;8
\1_free	dc.l	0	;12
alskip\@	;
	endm

k_alloclist	;a2=address of 'first' pointer
	;d0=max items, d1=item size
	;
	move.l	a2,8(a2)	;clear out used list
 	lea	4(a2),a0
	clr.l	(a0)
	move.l	a0,(a2)
	movem.l	d0-d1,-(a7)
	mulu	d1,d0
	move.l	#$10001,d1
	allocmem	alloclist
	move.l	d0,a0
	lea	12(a2),a2
	movem.l	(a7)+,d0-d1
	subq	#1,d0
.loop	move.l	a0,(a2)
	move.l	a0,a2
	add	d1,a0
	dbf	d0,.loop
	rts

addnext	macro
	;
	;addnext 'listname'
	;add after a5
	;return eq if none available else a0
	;
	move.l	\1_free,d0
	beq.s	.anskip\@
	move.l	d0,a0
	move.l	(a0),\1_free
	move.l	(a5),a1
	move.l	a1,(a0)
	move.l	a0,4(a1)
	move.l	a0,(a5)
	move.l	a5,4(a0)
.anskip\@	;
	endm

addfirst	macro
	;
	;addfirst 'listname'
	;return eq if none available else a0
	;
	move.l	\1_free,d0
	beq.s	.afskip\@
	move.l	d0,a0
	move.l	(a0),\1_free
	move.l	\1,a1	;current first
	move.l	a1,(a0)
	move.l	a0,4(a1)
	move.l	a0,\1
	move.l	#\1,4(a0)
.afskip\@	;
	endm

addlast	macro
	;
	;addlast 'listname'
	;return eq in none available else a0
	;
	move.l	\1_free,d0
	beq.s	.alskip\@
	move.l	d0,a0
	move.l	(a0),\1_free
	;
	move.l	\1_last+4,a1	;current last
	move.l	a0,(a1)
	move.l	a1,4(a0)
	move.l	a0,\1_last+4
	move.l	#\1_last,(a0)
.alskip\@	;
	endm

killitem	macro
	;
	;killitem listname
	;a0=item to kill, return a0=previous item.
	;
	move.l	(a0),a1	;next of me!
	move.l	4(a0),4(a1)
	move.l	4(a0),a1	;prev of me
	move.l	(a0),(a1)
	move.l	\1_free,(a0)
	move.l	a0,\1_free
	move.l	a1,a0
	endm
	
clearlist	macro
	;
	;clearlist listname
	;
.clloop\@	move.l	\1,a0
	tst.l	(a0)
	beq	.cldone\@
	killitem	\1
	bra	.clloop\@
.cldone\@	;
	endm

zerolist	macro	listname,size of item
	;
	;fill all list items with 0!
	;
	clearlist	\1
.zlloop\@	addlast	\1
	beq	.zlskip\@
	lea	8(a0),a1
	moveq	#0,d0
	move	#(\2-8)/2-1,d1
.zlloop2\@	move	d0,(a1)+
	dbf	d1,.zlloop2\@
	bra	.zlloop\@
.zlskip\@	clearlist	\1
	;
	endm

bwait	macro
	;
.bwait\@	btst	#6,$dff002
	beq.s	.bwait2\@
	bra.s	.bwait\@
.bwait2\@	;
	endm

printlong	macro
	move.l	\1,-(a7)
	jsr	printlong_
	endm

check	macro
	list
check	set	*-\1
	nolist
	endm

push	macro
	movem.l	d2-d7/a2-a6,-(a7)
	endm

pull	macro
	movem.l	(a7)+,d2-d7/a2-a6
	endm

col	macro
	move	#0,$dff106
	move	\1,$dff180
	endm

warn	macro
	move	d0,-(a7)
	move	#-1,d0
.wloop\@	col	\1
	dbf	d0,.wloop\@
	move	(a7)+,d0
	endm

tempfile	ds.b	64

wbmess	dc.l	0	;workbench message!

