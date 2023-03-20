local EditGroup = GetRandomIntInRange(0, 0xffffff)
local PlacePrompt
local EditPrompt
local SceneGroup = GetRandomIntInRange(0, 0xffffff)
local Scenes = {}
local Identifier, CharIdentifier

local ActiveScene

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
    local _, Hit, Coords, _, Entity = GetShapeTestResult(handle)
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
    local px, py, pz = table.unpack(GetGameplayCamCoord())
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

local addMode = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if Config.HotKeysEnabled == true then
            if whenKeyJustPressed(Config.HotKeys.Scene) then
                if addMode then
                    addMode = false
                elseif not addMode then
                    addMode = true
                end
            end

            if whenKeyJustPressed(Config.HotKeys.Place) then
                if addMode then
                    TriggerEvent("bcc_scene:start")
                else
                    TriggerEvent("vorp:TipBottom", Config.Texts.SceneErr, 3000)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
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
            x, y, z = table.unpack(SceneTarget())
            Citizen.InvokeNative(0x2A32FAA57B937173, 0x50638AB9, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.15, 93, 17, 100, 255, false, false, 2, false, false)

            if Config.HotKeysEnabled == true then
                local label = CreateVarString(10, 'LITERAL_STRING', '')
                PromptSetActiveGroupThisFrame(EditGroup, label)
            end
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
                if Config.UseDataBase == true then
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
                                if Config.UseDataBase == true then
                                    id = Scenes[i].autoid
                                else
                                    id = i
                                end
                                UI:Open(Config.Texts.MenuSubCompliment .. Scenes[i].text, Scenes[i], id)
                                ActiveScene = Scenes[i]
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

                    if Config.TextAsterisk == true then
                         outtext = "*" .. Scenes[i].text .. "*"
                    end

                    DrawText3D(sc.x, sc.y, sc.z, outtext, Scenes[i].color, Scenes[i].font,
                        Scenes[i].bg, Scenes[i].scale)
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
    end
end)

RegisterCommand('scene:place', function(source, args, raw)
    if addMode then
        TriggerEvent("bcc_scene:start")
    else
        TriggerEvent("vorp:TipBottom", Config.Texts.SceneErr, 3000)
    end
end)

RegisterNetEvent('bcc_scene:sendscenes')
AddEventHandler('bcc_scene:sendscenes', function(scenes)
    Scenes = scenes
    UI:Update(scenes, ActiveScene)
end)

RegisterNetEvent('bcc_scene:client_edit')
AddEventHandler('bcc_scene:client_edit', function(nr)
    local scenetext = ""
    Citizen.CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', Config.Texts.AddDetails)
        DisplayOnscreenKeyboard(0, "FMMC_MPM_NA", "", "", "", "", "", 50)
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0);
            Citizen.Wait(5);
        end
        if (GetOnscreenKeyboardResult()) then
            scenetext = GetOnscreenKeyboardResult()

            TriggerServerEvent("bcc_scene:edited", scenetext, nr)
            CancelOnscreenKeyboard()
        end
    end)
end)

RegisterNetEvent('bcc_scene:start')
AddEventHandler('bcc_scene:start', function()
    local scenetext = ""
    Citizen.CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', Config.Texts.AddDetails)
        DisplayOnscreenKeyboard(0, "FMMC_MPM_NA", "", "", "", "", "", 50)
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0);
            Citizen.Wait(5);
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

RegisterNetEvent('bcc_scene:retrieveCharData')
AddEventHandler('bcc_scene:retrieveCharData', function(identifier, charIdentifier)
    --print("Retrieving scenes for " .. identifier .. " " .. charIdentifier)
    Identifier = identifier
    CharIdentifier = charIdentifier
end)

RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function(charid)
    Wait(10000)
    TriggerServerEvent("bcc_scene:getCharData")
end)
