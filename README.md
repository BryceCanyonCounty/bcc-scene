# BCC - Scene

> A RedM scene text free placement system for Vorp 

## Installation
1. Download this repo/codebase
2. Extract and place `bcc-scene` into your `resources` folder
3. Add `ensure bcc-scene` to your `server.cfg` file
4. Restart your server (unless you have nightly restarts)

## How-to-use
1. Type `/scene` to activate tracking ball
![step 1](/assets/readme1.png)
2. Type `/scene:place` will save the coords of the ball and pop up a text prompt
![step 1](/assets/readme2.png)
3. Type what you want to display on the scene
4. Click enter
5. Your text should appear in the given location.
![step 1](/assets/readme2.png)


## How-to-configure
All configurations available in `/config.lua`

## Disclaimers and Credits
- I utilized Skate and rickx's [lto_scene](https://github.com/zelbeus/ricx_scene) codebase from the vorp prebuilt server for the base of this project.
- I utilized the Sphere locator object from a similar old FiveM script [nh-scenes](https://github.com/nerohiro/nh-scenes). 

## TODO
- Add better UI
- Migrate from (or make a config toggle) to store into sqldb vs json file (db will give longer lived persistence to the scene texts)

 ## Dependency
 - Vorp Core
