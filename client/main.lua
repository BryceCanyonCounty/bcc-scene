if Config.Framework == 'rsg-core' then
    RSGCore = exports['rsg-core']:GetCoreObject()
end

local function Notify(text)
    if Config.Framework == 'rsg-core' then
        RSGCore.Functions.Notify(text, 'error')
    else
        TriggerEvent("vorp:TipBottom", text, 3000)
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
local scene_target

ResetActiveScene = function()
    ActiveScene = nil
end

---@param scene {id:any, charid:any}
---@return boolean
IsOwnerOfScene = function(scene)
    return tostring(scene.id) == tostring(Identifier) and tonumber(scene.charid) == tonumber(CharIdentifier)
end

SceneTarget = function()
    local Cam = GetGameplayCamCoord()
    local handle = Citizen.InvokeNative(0x377906D8A31E5586, Cam, GetCoordsFromCam(10.0, Cam), -1, PlayerPedId(), 4)
    local _, _, Coords, _, _ = GetShapeTestResult(handle)
    return Coords
end

GetCoordsFromCam = function(distance, coords)
    local rotation = GetGameplayCamRot()
    local adjustedRotation = vector3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
    local direction = vector3(-math.sin(adjustedRotation[3]) * math.abs(math.cos(adjustedRotation[1])), math.cos(adjustedRotation[3]) * math.abs(math.cos(adjustedRotation[1])), math.sin(adjustedRotation[1]))
    return vector3(coords[1] + direction[1] * distance, coords[2] + direction[2] * distance, coords[3] + direction[3] * distance)
end

function DrawText3D(x, y, z, text, type, font, bg, scale)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local str = CreateVarString(10, "LITERAL_STRING", text)
    if onScreen then
        SetTextColor(Config.Colors[type][1], Config.Colors[type][2], Config.Colors[type][3], 215)
        SetTextScale(scale, scale)
        SetTextFontForCurrentCommand(font) -- 0,1,5,6, 9, 11, 12, 15, 18, 19, 20, 22, 24, 25, 28, 29
        SetTextCentre(1)
        DisplayText(str, _x, _y - 0.0)

        if bg > 0 then
            local factor = (string.len(text)) / 225

            DrawSprite("feeds", "hud_menu_4a", _x, _y + scale / 50, (scale / 20) + factor, scale / 5, 0.1,
                Config.Colors[bg][1], Config.Colors[bg][2], Config.Colors[bg][3], 190, 0)
        end
    end
end

function whenKeyJustPressed(key)
    if Citizen.InvokeNative(0x580417101DDB492F, 0, key) then
        return true
    else
        return false
    end
end

function PlayerData()
    CreateThread(function ()
        while true do
            TriggerServerEvent("bcc_scene:getCharData")
            Wait(10000)
        end
    end)
end

function SceneDot()
    CreateThread(function()
        while true do
            local x, y, z
            if addMode then
                scene_target = SceneTarget()
                x, y, z = table.unpack(scene_target)
                Citizen.InvokeNative(0x2A32FAA57B937173, 0x50638AB9, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.15, 93, 17, 100, 255, false, false, 2, false, false)
                if Config.HotKeysEnabled then
                    local label = CreateVarString(10, 'LITERAL_STRING', '')
                    PromptSetActiveGroupThisFrame(EditGroup, label)
                end
            else
                break
            end
            Wait(5)
        end
    end)
end

if Config.HotKeysEnabled then
    CreateThread(function()
        while true do
        Wait(0)
            if whenKeyJustPressed(Config.HotKeys.Scene) then
                if addMode then
                    addMode = false
                elseif not addMode then
                    addMode = true
                    SceneDot()
                end
            end

            if whenKeyJustPressed(Config.HotKeys.Place) then
                if addMode then
                    TriggerEvent("bcc_scene:start")
                else
                    Notify(Config.Texts.SceneErr)
                end
            end
        end
    end)
end

CreateThread(function()
    local place = Config.Prompts.Place.title
    PlacePrompt = PromptRegisterBegin()
    PromptSetControlAction(PlacePrompt, Config.HotKeys.Place)
    place = CreateVarString(10, 'LITERAL_STRING', place)
    PromptSetText(PlacePrompt, place)
    PromptSetEnabled(PlacePrompt, 1)
    PromptSetVisible(PlacePrompt, 1)
    PromptSetStandardMode(PlacePrompt, 1)
    PromptSetGroup(PlacePrompt)
    PromptSetGroup(PlacePrompt, EditGroup)

    Citizen.InvokeNative(0xC5F428EE08FA7F2C, PlacePrompt, true)
    PromptRegisterEnd(PlacePrompt)


    local str = Config.Prompts.Edit[1]
    EditPrompt = PromptRegisterBegin()
    PromptSetControlAction(EditPrompt, Config.Prompts.Edit[2])
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(EditPrompt, str)
    PromptSetEnabled(EditPrompt, 1)
    PromptSetVisible(EditPrompt, 1)
    PromptSetStandardMode(EditPrompt, 1)
    PromptSetGroup(EditPrompt, SceneGroup)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, EditPrompt, true)
    PromptRegisterEnd(EditPrompt)

    TriggerServerEvent("bcc_scene:getscenes")
    while true do
        local sleep = 500
        local x, y, z
        if addMode == true then
            x, y, z = table.unpack(scene_target)
        end
        if Scenes[1] ~= nil then
            local closest = {
                dist = 99999999
            }
            for i, _ in pairs(Scenes) do
                local cc = GetEntityCoords(PlayerPedId())
                local edist = Config.EditDistance
                if addMode == true then
                    cc = {
                        x = x,
                        y = y,
                        z = z
                    }
                    edist = 0.1
                end
                local sc
                if Config.UseDataBase then
                    sc = json.decode(Scenes[i].coords)
                else
                    sc = Scenes[i].coords
                end
                local dist = #(vector3(cc.x, cc.y, cc.z) - vector3(sc.x, sc.y, sc.z))
                if dist < Config.ViewDistance then
                    sleep = 5
                    if Config.AllowAnyoneToEdit then
                        if (dist < edist) and dist <= closest.dist then
                            closest = {
                                dist = dist
                            }

                            local label = CreateVarString(10, 'LITERAL_STRING', Scenes[i].text)
                            PromptSetActiveGroupThisFrame(SceneGroup, label)
                            if Citizen.InvokeNative(0xC92AC953F0A982AE, EditPrompt) then
                                local id
                                if Config.UseDataBase then
                                    id = Scenes[i].autoid
                                else
                                    id = i
                                end
                                UI:Open(Config.Texts.MenuSubCompliment .. Scenes[i].text, Scenes[i], id)
                                ActiveScene = Scenes[i]
                            end
                        end
                    elseif Config.JobLock then
                        for _,v in pairs(Config.JobLock) do
                            if Job == v then
                                authorized = true
                                break
                            end
                        end
                        if authorized then
                            if (dist < edist) and dist <= closest.dist then
                                closest = {
                                    dist = dist
                                }

                                local label = CreateVarString(10, 'LITERAL_STRING', Scenes[i].text)
                                PromptSetActiveGroupThisFrame(SceneGroup, label)
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, EditPrompt) then
                                    local id
                                    if Config.UseDataBase then
                                        id = Scenes[i].autoid
                                    else
                                        id = i
                                    end
                                    UI:Open(Config.Texts.MenuSubCompliment .. Scenes[i].text, Scenes[i], id)
                                    ActiveScene = Scenes[i]
                                end
                            end
                        end
                    elseif Config.JobLock ~= false then
                        for _,v in pairs(Config.AdminLock) do
                            if Group == v then
                                authorized = true
                                break
                            end
                        end
                        if authorized then
                            if (dist < edist) and dist <= closest.dist then
                                closest = {
                                    dist = dist
                                }
                                local label = CreateVarString(10, 'LITERAL_STRING', Scenes[i].text)
                                PromptSetActiveGroupThisFrame(SceneGroup, label)
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, EditPrompt) then
                                    local id
                                    if Config.UseDataBase then
                                        id = Scenes[i].autoid
                                    else
                                        id = i
                                    end
                                    UI:Open(Config.Texts.MenuSubCompliment .. Scenes[i].text, Scenes[i], id)
                                    ActiveScene = Scenes[i]
                                end
                            end
                        end
                    else
                        if IsOwnerOfScene(Scenes[i]) then
                            if (dist < edist) and dist <= closest.dist then
                                closest = {
                                    dist = dist
                                }

                                local label = CreateVarString(10, 'LITERAL_STRING', Scenes[i].text)
                                PromptSetActiveGroupThisFrame(SceneGroup, label)
                                if Citizen.InvokeNative(0xC92AC953F0A982AE, EditPrompt) then
                                    local id
                                    if Config.UseDataBase == true then
                                        id = Scenes[i].autoid
                                    else
                                        id = i
                                    end
                                    UI:Open(Config.Texts.MenuSubCompliment .. Scenes[i].text, Scenes[i], id)
                                    ActiveScene = Scenes[i]
                                end
                            end
                        end
                    end
                    local outtext = Scenes[i].text
                    if Config.TextAsterisk then
                         outtext = "*" .. Scenes[i].text .. "*"
                    end
                    DrawText3D(sc.x, sc.y, sc.z, outtext, Scenes[i].color, Scenes[i].font, Scenes[i].bg, Scenes[i].scale)
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('scene', function(source, args, raw)
    if addMode then
        addMode = false
    elseif not addMode then
        addMode = true
        SceneDot()
    end
end)

RegisterCommand('scene:place', function(source, args, raw)
    if addMode then
        TriggerEvent("bcc_scene:start")
    else
        Notify(Config.Texts.SceneErr)
    end
end)

RegisterNetEvent('bcc_scene:sendscenes', function(scenes)
    Scenes = scenes
    UI:Update(scenes, ActiveScene)
end)

RegisterNetEvent('bcc_scene:client_edit', function(nr)
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

            TriggerServerEvent("bcc_scene:edited", scenetext, nr)
            CancelOnscreenKeyboard()
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

RegisterNetEvent('bcc_scene:retrieveCharData', function(identifier, charIdentifier, job, group)
    if Config.Debug then
        print("Retrieving scenes for identifier: " .. identifier .. " | charIdentifier: " .. charIdentifier.." | Job: "..job.. " | group: "..group)
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


if Config.Framework == 'rsg-core' then
    RegisterNetEvent("RSGCore:Client:OnPlayerLoaded")
    AddEventHandler("RSGCore:Client:OnPlayerLoaded", function()
        Wait(10000)
        PlayerData()
    end)
else
    RegisterNetEvent("vorp:SelectedCharacter")
    AddEventHandler("vorp:SelectedCharacter", function()
        Wait(10000)
        PlayerData()
    end)
end