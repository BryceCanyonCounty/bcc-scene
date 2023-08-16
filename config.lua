Config = {}
Config.Debug = false
Config.Framework = 'vorp' --What framework to use. Options: (vorp, rsg-core)

Config.ViewDistance = 5.0
Config.EditDistance = 2.0

-- Delete Scenes on server restart(whenever script is started)
-- Keep this to true for best performance (if not using a db)
Config.RestartDelete = true
Config.UseDataBase = true

-- USE ONLY ONE OF THE BELOW --
Config.AllowAnyoneToEdit = true -- True or False
Config.AllowAnyoneToDelete = true -- True or False
Config.AdminLock = false -- Use 'false' for no admin lock or IE group names. {'admin', 'god'}
Config.JobLock = false --{'police', 'doctor'} -- Use 'false' for no job lock or IE. {'police'}
-------------------------------

Config.HotKeysEnabled = true
Config.HotKeys = {
    Scene = 0x26E9DC00,
    Place = 0x8CC9CD42
}

Config.Prompts = {
    Edit = {[1] = "Edit Scene", [2] = 0x4CC0E2FE},
    Place = {
        title = 'Place Scene'
    }
}

Config.Texts = {
    AddDetails = "Add Scene Details",
    NoAuth = "You are not the owner of this scene",
    SceneErr = "You must have scene enabled to place text",
    MenuTitle = "Scene Editor",
    MenuSubCompliment = "Current Text: ",
    Delete = "Delete",
    Edit = "Edit",
    Font = "Change Font",
    Scale = "Change Scale",
    Color = "Change Color",
    BackgroundColor  = "Change Background Color",
    Exit = "Exit"
}

Config.StartingScale = 0.2
Config.MaxScale = 0.8

-- 0 value = transparent
Config.Defaults = {
    Font = 1,
    Color = 1,
    BackgroundColor = 0
}

Config.TextAsterisk = true

-- DO NOT TOUCH BELOW
Config.Fonts = {0,1,5,6, 9, 11, 12, 15, 18, 19, 20, 22, 24, 25, 28, 29}
Config.Colors = {
    --reds
    [1] = {128,0,0},
    [2] = {139,0,0},
    [3] = {165,42,42},
    [4] = {178,34,34},
    [5] = {220,20,60},
    [6] = {255,0,0},
    [7] = {255,99,71},
    [8] = {255,127,80},
    [9] = {205,92,92},
    [10] = {233,150,122},
    [11] = {250,128,114},
    [12] = {255,69,0},
    [13] = {255,140,0},
    [14] = {255,165,0},
    [15] = {255,215,0},
    [16] = {218,165,32},
    [17] = {238,232,170},
    [18] = {189,183,107},
    [19] = {240,230,140},
    [20] = {128,128,0},
    [21] = {255,255,0},
    [22] = {154,205,50},
    [23] = {85,107,47},
    [24] = {107,142,35},
    [25] = {124,252,0},
    [26] = {173,255,47},
    [27] = {0,128,0},
    [28] = {0,255,0},
    [29] = {50,205,50},
    [30] = {152,251,152},
    [31] = {143,188,143},
    [32] = {0,255,127},
    [33] = {102,205,170},
    [34] = {32,178,170},
    [35] = {0,128,128},
    [36] = {0,255,255},
    [37] = {0,206,209},
    [38] = {72,209,204},
    [39] = {70,130,180},
    [40] = {30,144,255},
    [41] = {138,43,226},
    [42] = {72,61,139},
    [43] = {123,104,238},
    [44] = {148,0,211},
    [45] = {238,130,238},
    [46] = {219,112,147},
    [47] = {255,105,180},
    [48] = {255,192,203},
    [49] = {250,235,215},
    [50] = {245,222,179},
    [51] = {255,248,220},
    [52] = {255,250,205},
    [53] = {139,69,19},
    [54] = {210,105,30},
    [55] = {205,133,63},
    [56] = {222,184,135},
    [57] = {255,218,185},
    [58] = {112,128,144},
    [59] = {255,250,250},
    [60] = {0,0,0},
    [61] = {128,128,128},
    [62] = {192,192,192},
    [63] = {245,245,245},
    [64] = {255,255,255},
}
