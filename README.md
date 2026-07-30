# GLOOM Reforged

![OS](https://img.shields.io/badge/OS-AmigaOS%203%2B-blue)
![AI Assisted Coding](https://img.shields.io/badge/AI-Assisted%20Coding-white)
![Controls](https://img.shields.io/badge/Controls-Keyboard%20%2F%20Mouse%20%2F%20Joypad-green)

This project aims to build an enhanced Amiga version of Gloom, based on the original, unmodified source code published at [earok/GloomAmiga](https://github.com/earok/GloomAmiga). Currently, Gloom Reforged is compatible with ECS and AGA Amigas (and basic Picasso96 compatibility for AGA Amigas). And it is **NOT** - I reapeat - **NOT** optimized for anything below PiStorm/68040.

[Watch the latest preview](https://vimeo.com/1213335312?share=copy&fl=sv&fe=ci) of Gloom Reforged v1.10.0 on Vimeo.

> [!WARNING]
> This game needs more CPU power than the original Gloom.  
> **A PISTORM OR AT LEAST 060@100MHz IS HIGHLY RECOMMENDED TO ACHIEVE STABLE FRAME RATES OF THE MAXIMUM 20-25 FPS!**  
> Picasso96 output is experimental at the moment! Use at your own risk.

The goal is *not* to turn Gloom into a completely different engine, but to modernize it where it makes sense, while preserving the look, feel, atmosphere, and gameplay identity of the classic release.

Nine years ago, the Gloom (not Gloom Deluxe) source code was released. This fork/port is based on the Gloom source code and has been extended with features from the non-functional "gloom2.s". This source code was presumably intended as the basis for Gloom Deluxe, but it had texture rendering errors, no HUD, no P96, the combat mode was broken, and palettes were not displayed correctly.


## SCOPE OF THIS PROJECT

### IN the Scope of this project

- Bugfix for the original source code in gloom2.s as only the gloom.s code was 99% complete
- Improve keyboard and mouse controls for a smoother FPS-style experience
- Improve render depth for far areas (including Bayer-dithering to avoid banding)
- Integrate new options in the ingame-menu (cheats, subtle reflections and blob-shadows)
- Integrate an universal health/weapon-bar 
- Maintain the original Gloom gameplay structure, assets and atmosphere as the foundation
- Compatibility to Gloom Deluxe, Gloom 3 and Zombie Massacre *(Gloom has other assets, no gun, other statusbar, etc)*
- Keep compatibility with real Amiga systems as a priority, not only emulators
- Graphicscard/P96 compatibility
- Widescreen support and renderer (Images are artificially widened)
- True ECS port (32 colors)
- Integrate [Kalm's C2P routines](https://github.com/Kalmalyzer/kalms-c2p)
- Performance optimizing (especially weaker processors)

### NOT in the Scope of this project

- No true high resolutions, as even a 060@94MHz has its limit at 320x240 AGA
- Support for 3rd party extensions like 8Bit Killer or others

The project will proceed step by step, with stability and authenticity taking priority over feature creep. Each improvement should feel like something that could have belonged in a polished Amiga-era enhanced edition of Gloom.


## MOST CRITICAL CHANGES MADE

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


## TOOLTYPES (Icon or CLI)

- Without a tool type, auto recognition kicks in
- AGA = Start AGA mode
- ECS = Start ECS Mode (only on AGA)
- P96 = Use P96 graphics card mode (AGA necessary)
- STOCK = use the default renderer from 90s Gloom without effects, Nasty violence mode, new Bayer-dithering and depth-fog
- FPS = Displays a frame counter in the bottom right corner (Gloom caps at 25 FPS)


## SCREENSHOTS

[Watch the latest preview](https://vimeo.com/1213335312?share=copy&fl=sv&fe=ci) of Gloom Reforged v1.10.0 on Vimeo.


**Titlescreen as usual** _(extended to widescreen 16:9_
![Titlescreen as usual](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/1_titlescreen.jpg)

**Titlemenu with reworked options and sorting, also new Violence mode "Nasty"**
![Titlemenu with reworked options and sorting, also new Violence mode "Nasty"](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/2_titlemenu.jpg)

**Intermission screen** _(extended to widescreen 16:9)_
![Intermission screen](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/3_intermissionscreen.jpg)

**New ingame menu with effects, options and cheats**
![New ingame menu with effects, options and cheats](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/4_ingamemenu.jpg)

**Bayer-dither-renderer and two different visabilities** _(render depths)_
![Bayer-dither-renderer and two different visabilities](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/5_bayerdither%2Bvisibility.jpg)

**New reflections on enemies, walls and weapons/upgrades** _(needs PiStorm)_
![New reflections on enemies, walls and weapons/upgrades](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/6_reflections.jpg)

**New invisibilty mode when "Invisibility"-powerup is taken**
![New invisibilty mode when "Invisibility"-powerup is taken](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/7_invisibilitymode.jpg)

**Nasty-Violence with procedual-generated pools of blood**
![Nasty-Violence with pools of blood](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/8_nastyviolencemode.jpg)

**Two-Player Splitscreen** _(also optimized for widescreen 16:9)_
![Two-Player Splitscreen](https://github.com/Andiweli/Gloom-Reforged/blob/master/images/9_twoplayersplitscreen.jpg)


## KNOWN ISSUES

- TWO PLAYER COMBAT (not working 100%) removed in 1.7
- REMOTE LINK OPTIONS (not working 100%) removed in 1.7


## BASELINE VALUES
Determined using the [GloomBench benchmark](https://github.com/Andiweli/Gloom-Reforged/releases/tag/Benchmark)
*(Version 1.10, AGA/ECS, without any enhancements or P96)*

| System                        | FPS (AGA/ECS)       |
|-------------------------------|---------------------|
| Amiga 500 PiStorm Zero        | 25                  |
| Amiga 600 PiStorm Pi3A        | 25                  |
| Amiga 1000 TF536              | 4.8                 |
| Amiga 1200 PiStorm32 CM4      | 25.0                |
| Amiga 1200 TF1260@94MHz       | 19.4                |
| Amiga 1200 CSPPC@50MHz        | 14.5                |
| Amiga 1200 V1200              | 25.0                |
| Amiga 4000 CS MKII            | 12.5                |
| Apollo A6000                  | 25.0                |


## RELEASE

Look at the [Release section](https://github.com/Andiweli/GloomReforged/releases).


## LEGAL / SOURCE CODE NOTICE

This project is based on the publicly available original source code of **Gloom**. All original rights, trademarks, names, graphics, audio, game data and related assets remain the property of their respective owners.

This repository is intended for preservation, research, learning and non-commercial development purposes. It does not claim ownership of the original game, its assets or intellectual property.

Only source code and project files that are legally available or newly created for this project should be included in this repository. Original commercial game data, copyrighted assets or files from the retail release are not distributed here and must be provided by the user where required.
