# Gloom Reforged

![OS](https://img.shields.io/badge/OS-AmigaOS%203%2B-blue)
![AI Assisted Coding](https://img.shields.io/badge/AI-Assisted%20Coding-white)
![Controls](https://img.shields.io/badge/Controls-Keyboard%20%2F%20Mouse%20%2F%20Joypad-green)

This project aims to build an enhanced Amiga version of Gloom, based on the original, unmodified source code published at [earok/GloomAmiga](https://github.com/earok/GloomAmiga).

That repository serves as the clean reference base from which this project is being ported, reorganized, fixed, and carefully extended.

The goal is *not* to turn Gloom into a completely different engine, but to modernize and improve it where it makes sense on real Amiga hardware, while preserving the look, feel, speed, atmosphere, and gameplay identity of the classic release.

## Planned scope includes

- [x] Bug fixes for the original source code in gloom2.s
- [x] Integrating the health/weapon-bar and gun/muzzleflash graphics
- [x] Improved keyboard and mouse controls for a smoother FPS-style experience
- [x] Integrating new options in the ingame-menu
- [x] Improved render depth for far areas (to possibly avoid banding)
- [ ] Faster and cleaner loading behaviour compared to the current source build
- [ ] Optional visual enhancements such as muzzle flashes, atmospheric effects and subtle dynamic lighting
- [ ] Keeping compatibility with real Amiga systems as a priority, not only emulators
- [x] Maintaining the original Gloom gameplay structure, assets and atmosphere as the foundation

The project will proceed step by step, with stability and authenticity taking priority over feature creep. Each improvement should feel like something that could have belonged in a polished Amiga-era enhanced edition of Gloom.

## Most critical changes so far

1. **Made `gloom2.s` bootable again**
   Fixed startup/Guru issues and turned it into a usable standalone source base.
2. **Fixed Devpac/assembler issues**
   Corrected branch range problems, oversized `bsr` jumps, and other build errors.
3. **Centered the screen output properly**
   The game screen is now correctly centered; screen position 40 became the good anchor.
4. **Fixed wrong colors caused by bitplane/stride issues**
   The incorrect 256-line stride approach was discarded; the compact 240-line plane span is the correct path.
5. **Restored correct texture rendering**
   Wall and level graphics now render properly in the `gloom2.s` path, without distortion or wrong colors.
6. **Made the level playable again**
   Movement, collision, and the main gameplay path are working again in the new `gloom2.s` version.
7. **Fixed menu/ESC behavior**
   The menu now opens cleanly with a single ESC press instead of causing repeated or broken behavior.
8. **Reworked weapon, muzzleflash, and HUD handling**
   Weapon placement, gunbob, projectile origin, muzzleflash size, status bar elements, and health bar alignment were improved.
9. **Improved blood splatter / messy effects**
   Blood splatter effects work again and were moved closer to the intended original look.
10. **Reworked distance fog / far rendering**
    Current focus: smoother distance darkening, fewer harsh shading steps, stronger fade-out after roughly six texture widths, and dark far corridors instead of fully black gaps.


## Screenshots

<p align="center">
<img width="1026" height="800" alt="image" src="https://github.com/user-attachments/assets/885a5c9a-4c3b-48c2-b75d-d99f79149a65" />

<img width="1026" height="800" alt="image" src="https://github.com/user-attachments/assets/3a7ae507-4b8d-4650-890e-ff2bb23609fa" />

<img width="1026" height="800" alt="image" src="https://github.com/user-attachments/assets/f80e473c-04c7-452b-a747-42169354db2a" />
</p>

## Release

As soon as there is a stable basic version available. 

## Legal / Source Code Notice

This project is based on the publicly available original source code of **Gloom**. All original rights, trademarks, names, graphics, audio, game data and related assets remain the property of their respective owners.

This repository is intended for preservation, research, learning and non-commercial development purposes. It does not claim ownership of the original game, its assets or intellectual property.

Only source code and project files that are legally available or newly created for this project should be included in this repository. Original commercial game data, copyrighted assets or files from the retail release are not distributed here and must be provided by the user where required.
