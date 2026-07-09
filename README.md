# Gloom Reforged

![OS](https://img.shields.io/badge/OS-AmigaOS%203%2B-blue)
![AI Assisted Coding](https://img.shields.io/badge/AI-Assisted%20Coding-white)
![Controls](https://img.shields.io/badge/Controls-Keyboard%20%2F%20Mouse%20%2F%20Joypad-green)

This project aims to build an enhanced Amiga version of Gloom, based on the original, unmodified source code published at [earok/GloomAmiga](https://github.com/earok/GloomAmiga).

That repository serves as the clean reference base from which this project is being ported, reorganized, fixed, and carefully extended.

The goal is *not* to turn Gloom into a completely different engine, but to modernize and improve it where it makes sense on real Amiga hardware, while preserving the look, feel, speed, atmosphere, and gameplay identity of the classic release.

> [!WARNING]
> - **AGA only**, so if you try on other than A1200/A4000 it won't work. I heard some people wondered it doesn't work on A500 🙂  
> - If you expect AAA PC shadows and reflections you might be disappointed, we are still talking about Gloom, the Engine is the same as in the 90s. It has optional blob-shadows and "reflection-ish" colored dots on the floor *(see screenshot 4 and 5)*. If you want PC-quality-Gloom try [ZGLOOM](https://github.com/Andiweli?tab=repositories&q=ZGLOOM&type=&language=&sort=).  
> - And of course it needs more power than the old one because of the changes. So don't expect it works better than original Gloom or even fullscreen on 68020.  
> - And this is only compatible and tested with PiStorm32 and Amiga OS 3.2.3 - it might/might not work on other hardware/software constellations.

## Planned scope includes

- [x] Bug fixes for the original source code in gloom2.s as only the gloom.s code was 99% complete
- [x] Improved keyboard and mouse controls for a smoother FPS-style experience
- [x] Improved render depth for far areas (including Bayer-dithering to avoid banding)
- [x] Integrating new options in the ingame-menu (cheats, subtle reflections and blob-shadows)
- [x] Integrating an universal health/weapon-bar 
- [x] Maintaining the original Gloom gameplay structure, assets and atmosphere as the foundation
- [x] Compatibility to Gloom Deluxe, Gloom 3 and Zombie Massacre *(Gloom has other assets, no gun, other statusbar, etc)*
- [x] Keeping compatibility with real Amiga systems as a priority, not only emulators
- [x] Graphicscard/P96 compatibility (basic functionality)
- [ ] Graphicscard/P96 full renderpath

The project will proceed step by step, with stability and authenticity taking priority over feature creep. Each improvement should feel like something that could have belonged in a polished Amiga-era enhanced edition of Gloom.

## Most critical changes so far

1. **Made `gloom2.s` bootable again**
   Fixed startup/Guru issues and turned it into a usable standalone source base, some issues are still persistent.
2. **Fixed wrong colors caused by bitplane/stride issues**
   The incorrect 256-line stride approach was discarded; the compact 240-line plane span is the correct path.
3. **Restored correct texture rendering**
   Wall and level graphics now render properly in the `gloom2.s` path, without distortion or wrong colors.
4. **Fixed menu/ESC behavior**
   The menu now opens cleanly with a single ESC press instead of causing repeated or broken behavior.
5. **Reworked weapon, muzzleflash, and HUD handling**
   Weapon placement, gunbob, projectile origin, muzzleflash size, status bar elements, and health bar alignment were improved.
6. **Improved blood splatter / messy effects**
   Blood splatter effects work again and were moved closer to the intended original look.
7. **Reworked distance fog / far rendering**
   Current focus: smoother distance darkening, fewer harsh shading steps, stronger fade-out after roughly six texture widths, and dark far corridors instead of fully black gaps.
8. **Reworked renderer**
    Bayer dithering was added to the hard transitions between lighter and darker shading for softer transitions.

## Known issues

- TWO PLAYER COMBAT crashes when used more than once in a gaming session (worked only on gloom.s but not gloom2.s)
- REMOTE LINK OPTIONS crashes when selected after a game (not when started fresh)
- Display or loading errors on specific hardware configurations

## Screenshots

<p align="center">
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/9798e255-de1e-4cf4-8de6-82639863d55a" />
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/63560c87-a0ca-4136-bca9-5e43aa91043f" />
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/d1441ec6-9a27-436b-8421-62e479a04205" />
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/43d3c228-81cf-4844-bb5c-053d2616e79c" />
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/544b011a-02b5-41ec-bfee-0858a7f4df2b" />
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/de284e60-e5aa-4d4a-a2e0-eda331296848" />
<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/b30aaffe-983b-449c-bae6-619b5711af32" />

</p>

## Release

Look at the [Release section](https://github.com/Andiweli/GloomReforged/releases).

## Legal / Source Code Notice

This project is based on the publicly available original source code of **Gloom**. All original rights, trademarks, names, graphics, audio, game data and related assets remain the property of their respective owners.

This repository is intended for preservation, research, learning and non-commercial development purposes. It does not claim ownership of the original game, its assets or intellectual property.

Only source code and project files that are legally available or newly created for this project should be included in this repository. Original commercial game data, copyrighted assets or files from the retail release are not distributed here and must be provided by the user where required.
