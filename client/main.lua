---@type BCCSceneDebugLib
local DBG = BCCSceneDebug

local Framework = Config.Framework

if Framework == 'vorp' then
    Core = exports.vorp_core:GetCore()
    DBG.Info("Framework initialized: VORP Core")
else
    RSGCore = exports['rsg-core']:GetCoreObject()
    DBG.Info("Framework initialized: RSG Core")
end

local function Notify(text)
    if Framework == 'vorp' then
        Core.NotifyRightTip(text, 4000)
        TriggerEvent("vorp:TipBottom", text, 4000)
    else
        RSGCore.Functions.Notify(text, 'error')
    end
end

local EditGroup = GetRandomIntInRange(0, 0xffffff)
local PlacePrompt
local EditPrompt
local SceneGroup = GetRandomIntInRange(0, 0xffffff)
local Scenes = {}
local Identifier, CharIdentifier, Job, Group
local ActiveScene
local authorized = false
local addMode = false
local placementSphereReady = false
local scene_target
local UseDataBase = Config.UseDataBase

ResetActiveScene = function()
    DBG.Info("Resetting active scene")
    ActiveScene = nil
end

local function CanEditScene(scene)

    if IsOwnerOfScene(scene) then return true end

    if Config.AdminLock then
        for _, grp in pairs(Config.AdminLock) do
            if Group == grp then return true end
        end
    end

    if Config.JobLock then
        for _, job in pairs(Config.JobLock) do
            if Job == job then return true end
        end
    end

    if Config.AllowAnyoneToEdit then return true end

    return false
end

---@param scene {id:any, charid:any}
---@return boolean
IsOwnerOfScene = function(scene)
    local isOwner = tostring(scene.id) == tostring(Identifier) and
                        tonumber(scene.charid) == tonumber(CharIdentifier)
    DBG.Info("Checking scene ownership - Scene ID: " .. tostring(scene.id) ..
                 ", Player ID: " .. tostring(Identifier) .. ", Scene CharID: " ..
                 tostring(scene.charid) .. ", Player CharID: " ..
                 tostring(CharIdentifier) .. ", Is Owner: " .. tostring(isOwner))
    return isOwner
end

SceneTarget = function()
    local Cam = GetGameplayCamCoord()
    local handle = Citizen.InvokeNative(0x377906D8A31E5586, Cam,
                                        GetCoordsFromCam(10.0, Cam), -1,
                                        PlayerPedId(), 4)
    local _, _, Coords, _, _ = GetShapeTestResult(handle)
    return Coords
end

GetCoordsFromCam = function(distance, coords)
    local rotation = GetGameplayCamRot()
    local adjustedRotation = vector3((math.pi / 180) * rotation.x,
                                     (math.pi / 180) * rotation.y,
                                     (math.pi / 180) * rotation.z)
    local direction = vector3(-math.sin(adjustedRotation[3]) *
                                  math.abs(math.cos(adjustedRotation[1])),
                              math.cos(adjustedRotation[3]) *
                                  math.abs(math.cos(adjustedRotation[1])),
                              math.sin(adjustedRotation[1]))
    return vector3(coords[1] + direction[1] * distance,
                   coords[2] + direction[2] * distance,
                   coords[3] + direction[3] * distance)
end

function DrawText3D(x, y, z, text, type, font, bg, scale)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local str = CreateVarString(10, "LITERAL_STRING", text)
    if onScreen then
        SetTextColor(Config.Colors[type][1], Config.Colors[type][2],
                     Config.Colors[type][3], 215)
        SetTextScale(scale, scale)
        SetTextFontForCurrentCommand(font) -- 0,1,5,6, 9, 11, 12, 15, 18, 19, 20, 22, 24, 25, 28, 29
        SetTextCentre(1)
        DisplayText(str, _x, _y - 0.0)

        if bg > 0 then
            local factor = (string.len(text)) / 225

            DrawSprite("feeds", "hud_menu_4a", _x, _y + scale / 50,
                       (scale / 20) + factor, scale / 5, 0.1,
                       Config.Colors[bg][1], Config.Colors[bg][2],
                       Config.Colors[bg][3], 190, false)
        end
    end
end

function SceneDot()
    DBG.Info("Starting SceneDot thread for placement sphere")
    CreateThread(function()
        while true do
            local x, y, z
            if addMode then
                scene_target = SceneTarget()
                x, y, z = table.unpack(scene_target)
                Citizen.InvokeNative(0x2A32FAA57B937173, 0x50638AB9, x, y, z,
                                     0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15,
                                     0.15, 93, 17, 100, 255, false, false, 2,
                                     false, false)

                placementSphereReady = true
                if Config.HotKeysEnabled then
                    local label = CreateVarString(10, 'LITERAL_STRING', '')
                    UiPromptSetActiveGroupThisFrame(EditGroup, label, 1, 0, 0, 0)
                end
            else
                placementSphereReady = false
                DBG.Info("Exiting SceneDot thread - addMode disabled")
                break
            end
            Wait(5)
        end
    end)
end

local function whenKeyJustPressed(key)
    if Citizen.InvokeNative(0x580417101DDB492F, 0, key) then
        return true
    else
        return false
    end
end

if Config.HotKeysEnabled then
    DBG.Info("Hotkeys enabled - Starting hotkey monitoring thread")
    CreateThread(function()
        while true do
            Wait(0)
            if whenKeyJustPressed(Config.HotKeys.Scene) then
                if addMode then
                    DBG.Info("Scene hotkey pressed - Disabling add mode")
                    addMode = false
                elseif not addMode then
                    DBG.Info("Scene hotkey pressed - Enabling add mode")
                    addMode = true
                    SceneDot()
                end
            end

            if whenKeyJustPressed(Config.HotKeys.Place) then
                if addMode then
                    DBG.Info("Place hotkey pressed - Triggering scene start")
                    TriggerEvent("bcc_scene:start")
                else
                    DBG.Warning("Place hotkey pressed but add mode is disabled")
                    Notify(Config.Texts.SceneErr)
                end
            end
        end
    end)
else
    DBG.Info("Hotkeys disabled in config")
end

CreateThread(function()
    PlacePrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(PlacePrompt, Config.HotKeys.Place)
    UiPromptSetText(PlacePrompt, CreateVarString(10, 'LITERAL_STRING',
                                                 Config.Prompts.Place.title))
    UiPromptSetEnabled(PlacePrompt, true)
    UiPromptSetVisible(PlacePrompt, true)
    UiPromptSetStandardMode(PlacePrompt, true)
    UiPromptSetGroup(PlacePrompt, EditGroup, 0)
    UiPromptRegisterEnd(PlacePrompt)

    EditPrompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(EditPrompt, Config.Prompts.Edit[2])
    UiPromptSetText(EditPrompt, CreateVarString(10, 'LITERAL_STRING',
                                                Config.Prompts.Edit[1]))
    UiPromptSetEnabled(EditPrompt, true)
    UiPromptSetVisible(EditPrompt, true)
    UiPromptSetStandardMode(EditPrompt, true)
    UiPromptSetGroup(EditPrompt, SceneGroup, 0)
    UiPromptRegisterEnd(EditPrompt)

    TriggerServerEvent("bcc_scene:getscenes")
    DBG.Info("Scene management thread started - Requesting scenes from server")
    while true do
        local sleep = 500
        local x, y, z
        if addMode == true and placementSphereReady == true then
            x, y, z = table.unpack(scene_target)
        end
        if Scenes[1] ~= nil then
            local closest = {dist = 99999999}
            DBG.Info("Processing " .. #Scenes ..
                         " scenes for display and interaction")
            for i, _ in pairs(Scenes) do
                local cc = GetEntityCoords(PlayerPedId())
                local edist = Config.EditDistance
                if addMode == true and placementSphereReady == true then
                    cc = vector3(x, y, z)
                    edist = 0.1
                end
                local sc
                if UseDataBase then
                    sc = json.decode(Scenes[i].coords)
                else
                    sc = Scenes[i].coords
                end
                local dist = #(cc - vector3(sc.x, sc.y, sc.z))
                if dist < Config.ViewDistance then
                    sleep = 5
                    local canEdit = CanEditScene(Scenes[i])
                    if canEdit and (dist < edist) and dist <= closest.dist then
                        closest = {dist = dist}

                        local label = CreateVarString(10, 'LITERAL_STRING',
                                                      Scenes[i].text)
                        UiPromptSetActiveGroupThisFrame(SceneGroup, label, 1, 0,
                                                        0, 0)

                        if Citizen.InvokeNative(0xC92AC953F0A982AE, EditPrompt) then
                            local id = UseDataBase and Scenes[i].autoid or i
                            ActiveScene = Scenes[i]
                            UI:Open(Config.Texts.MenuSubCompliment ..
                                        Scenes[i].text, Scenes[i], id)
                        end
                    end
                    local outtext = Scenes[i].text
                    if Config.TextAsterisk then
                        outtext = "*" .. Scenes[i].text .. "*"
                    end
                    DrawText3D(sc.x, sc.y, sc.z, outtext, Scenes[i].color,
                               Scenes[i].font, Scenes[i].bg, Scenes[i].scale)
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('scene', function(source, args, raw)
    DBG.Info("Scene command executed")
    if addMode then
        DBG.Info("Scene command - Disabling add mode")
        addMode = false
    elseif not addMode then
        DBG.Info("Scene command - Enabling add mode")
        addMode = true
        SceneDot()
    end
end, false)

RegisterCommand('scene:place', function(source, args, raw)
    DBG.Info("Scene place command executed")
    if addMode then
        DBG.Info("Scene place command - Triggering scene start")
        TriggerEvent("bcc_scene:start")
    else
        DBG.Warning("Scene place command executed but add mode is disabled")
        Notify(Config.Texts.SceneErr)
    end
end, false)

RegisterNetEvent('bcc_scene:sendscenes', function(scenes)
    DBG.Info("Received " .. (scenes and #scenes or 0) .. " scenes from server")
    Scenes = scenes
    UI:Update(scenes, ActiveScene)
end)

RegisterNetEvent('bcc_scene:client_edit', function(nr)
    DBG.Info("Editing scene with ID: " .. tostring(nr))
    local scenetext = ""
    CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', Config.Texts.AddDetails)
        DisplayOnscreenKeyboard(0, "FMMC_MPM_NA", "", "", "", "", "", 50)
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0);
            Wait(5);
        end
        if (GetOnscreenKeyboardResult()) then
            scenetext = GetOnscreenKeyboardResult()
            DBG.Info("Scene edit completed - New text: " .. scenetext)
            TriggerServerEvent("bcc_scene:edited", scenetext, nr)
            CancelOnscreenKeyboard()
        else
            DBG.Warning("Scene edit cancelled by user")
        end
    end)
end)

RegisterNetEvent('bcc_scene:start', function()
    local scenetext = ""
    CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', Config.Texts.AddDetails)
        DisplayOnscreenKeyboard(0, "FMMC_MPM_NA", "", "", "", "", "", 50)
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0);
            Wait(5);
        end
        if (GetOnscreenKeyboardResult()) then
            scenetext = GetOnscreenKeyboardResult()

            -- player:
            -- GetEntityCoords(PlayerPedId())
            addMode = false
            TriggerServerEvent("bcc_scene:add", scenetext, SceneTarget())
            CancelOnscreenKeyboard()
        end
    end)
end)

RegisterNetEvent('bcc_scene:retrieveCharData',
                 function(identifier, charIdentifier, job, group)
    if Config.Devmode.Active then
        print("Retrieving scenes for identifier: " .. identifier ..
                  " | charIdentifier: " .. charIdentifier .. " | Job: " .. job ..
                  " | group: " .. group)
        print("--------- Config Settings ------------")
        if Config.AllowAnyoneToEdit then
            print("true | Config.AllowAnyoneToEdit")
        else
            print("false | Config.AllowAnyoneToEdit")
        end
        if Config.AdminLock then
            print("true | Config.AdminLock")
        else
            print("false | Config.AdminLock")
        end
        if Config.JobLock then
            print("true | Config.JobLock")
        else
            print("false | Config.JobLock")
        end
        print("--------------------------------------")
    end
    
    Group = group
    Job = job
    Identifier = identifier
    CharIdentifier = charIdentifier
end)

local function PlayerData()
    CreateThread(function()
        while true do
            TriggerServerEvent("bcc_scene:getCharData")
            Wait(10000)
        end
    end)
end

if Framework == 'vorp' then
    RegisterNetEvent("vorp:SelectedCharacter", function()
        Wait(10000)
        PlayerData()
    end)
else
    RegisterNetEvent("RSGCore:Client:OnPlayerLoaded", function()
        Wait(10000)
        PlayerData()
    end)
end
