# BCC - Scene

> A RedM scene text free placement system for Vorp 

##Features
1. Freely Add Text to a scene
2. Remove Text in a scene
3. Update Text in a scene
4. Hotkeys and/or commands
5. Easily configurateble settings
6. Json file storage  (Sql coming soon!)
7. WarMenu UI

## Installation
1. Download this repo/codebase
2. Extract and place `bcc-scene` into your `resources` folder
3. Add `ensure bcc-scene` to your `server.cfg` file
4. _(optional)_ remove the /assets readme images to save on resource space.
4. Restart your server (unless you have nightly restarts)

## How-to-use
1. Type `/scene` to activate tracking ball _(Or press Z if hotkeys are enabled)_
![image](https://user-images.githubusercontent.com/10902965/166846929-739318de-7b7d-482e-9702-6b2d4f03a82c.png)
2. Type `/scene:place` will save the coords of the ball and pop up a text prompt _(Or press X if hotkeys are enabled)_
![image](https://user-images.githubusercontent.com/10902965/166847059-a12eeb03-2f48-409f-bcb7-b5425519f390.png)
3. Type what you want to display on the scene
4. Click enter
5. Your text should appear in the given location.
![image](https://user-images.githubusercontent.com/10902965/166847110-7be69bab-6ae3-4330-b6ab-a016897e560f.png)

### How to Edit
1. Stand near your scene text, or enable scene ball and place it on your text
2. Press B to display the scene menu
3. Navigate with arrows, backspace and enter to confirm
![image](https://user-images.githubusercontent.com/10902965/166846730-5e4c712f-5169-4397-9d5c-ee4037706bea.png)


## How-to-configure
All configurations available in `/config.lua`

## Disclaimers and Credits
- I utilized Skate and rickx's [lto_scene](https://github.com/zelbeus/ricx_scene) codebase from the vorp prebuilt server for the base of this project.
- I utilized the Sphere locator object from a similar old FiveM script [nh-scenes](https://github.com/nerohiro/nh-scenes). 

## TODO
- Create a config toggle for sql vs json storage, add sql support (db will give longer lived persistence to the scene texts)

 ## Dependency
 - Vorp Core
