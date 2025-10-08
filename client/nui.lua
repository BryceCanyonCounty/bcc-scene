---@type BCCSceneDebugLib
local DBG = BCCSceneDebug

UI = {}

UIOpen = false

function UI:Update(scenes, ActiveScene)
    DBG.Info("UI:Update called with " .. (#scenes or 0) .. " scenes, ActiveScene: " .. (ActiveScene and "present" or "nil"))
    for index, scene in ipairs(scenes) do
        if ActiveScene and ActiveScene.autoid == scene.autoid then
            DBG.Info("Updating UI for active scene ID: " .. tostring(scene.autoid))
            SendNUIMessage({
                type = 'toggle',
                visible = true,
                subtitle = Config.Texts.MenuSubCompliment..scene.text,
                config = Config,
                scene = scene,
                index = scene.autoid
            })
        end
    end
end

function UI:Open(subtitle, scene, index)
    DBG.Info("Opening UI for scene ID: " .. tostring(index) .. " with subtitle: " .. subtitle)
    SendNUIMessage({
        type = 'toggle',
        visible = true,
        subtitle = subtitle,
        config = Config,
        scene = scene,
        index = index
    })
    SetNuiFocus(true, true)

    UIOpen = true
end

function UI:Close()
    DBG.Info("Closing UI")
    SendNUIMessage({
        type = 'toggle',
        visible = false,
        subtitle = '',
        config = Config,
        index = 0
    })
    SetNuiFocus(false, false)
    UIOpen = false
    ResetActiveScene()
end

RegisterNUICallback('close', function(args, cb)
    DBG.Info("NUI Callback: close")
    SetNuiFocus(false, false) -- Sets the focus of the player view away from NUI
    UIOpen = false
    ResetActiveScene()
    cb('ok')
end)


RegisterNUICallback('editscene', function(args, cb)
    DBG.Info("NUI Callback: editscene for scene ID: " .. tostring(args.index))
    TriggerServerEvent("bcc_scene:edit", args.index)
    UI:Close()
    cb('ok')
end)

RegisterNUICallback('deletescene', function(args, cb)
    DBG.Info("NUI Callback: deletescene for scene ID: " .. tostring(args.index))
    TriggerServerEvent("bcc_scene:delete", args.index)
    UI:Close()
    cb('ok')
end)

RegisterNUICallback('updatecolor', function(args, cb)
    DBG.Info("NUI Callback: updatecolor for scene ID: " .. tostring(args.index) .. " to color: " .. tostring(args.color))
    TriggerServerEvent("bcc_scene:color", args.index, args.color)
    cb('ok')
end)

RegisterNUICallback('updatebackgroundcolor', function(args, cb)
    DBG.Info("NUI Callback: updatebackgroundcolor for scene ID: " .. tostring(args.index) .. " to color: " .. tostring(args.color))
    TriggerServerEvent("bcc_scene:background", args.index, args.color)
    cb('ok')
end)

RegisterNUICallback('updatefont', function(args, cb)
    DBG.Info("NUI Callback: updatefont for scene ID: " .. tostring(args.index) .. " to font: " .. tostring(args.font))
    TriggerServerEvent("bcc_scene:font", args.index, args.font)
    cb('ok')
end)

RegisterNUICallback('updatescale', function(args, cb)
    DBG.Info("NUI Callback: updatescale for scene ID: " .. tostring(args.index) .. " to scale: " .. tostring(args.scale))
    TriggerServerEvent("bcc_scene:scale", args.index, args.scale)
    cb('ok')
end)

RegisterNUICallback('updatetext', function(args, cb)
    DBG.Info("NUI Callback: updatetext for scene ID: " .. tostring(args.index) .. " to text: '" .. tostring(args.text) .. "'")
    TriggerServerEvent("bcc_scene:edited", args.text, args.index)
    cb('ok')
end)

RegisterNUICallback('moveup', function(args, cb)
    DBG.Info("NUI Callback: moveup for scene ID: " .. tostring(args.index) .. " distance: " .. tostring(args.distance))
    TriggerServerEvent("bcc_scene:moveup", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('movedown', function(args, cb)
    DBG.Info("NUI Callback: movedown for scene ID: " .. tostring(args.index) .. " distance: " .. tostring(args.distance))
    TriggerServerEvent("bcc_scene:movedown", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('moveleft', function(args, cb)
    DBG.Info("NUI Callback: moveleft for scene ID: " .. tostring(args.index) .. " distance: " .. tostring(args.distance))
    TriggerServerEvent("bcc_scene:moveleft", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('moveright', function(args, cb)
    DBG.Info("NUI Callback: moveright for scene ID: " .. tostring(args.index) .. " distance: " .. tostring(args.distance))
    TriggerServerEvent("bcc_scene:moveright", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('moveforward', function(args, cb)
    DBG.Info("NUI Callback: moveforward for scene ID: " .. tostring(args.index) .. " distance: " .. tostring(args.distance))
    TriggerServerEvent("bcc_scene:moveforward", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('movebackwards', function(args, cb)
    DBG.Info("NUI Callback: movebackwards for scene ID: " .. tostring(args.index) .. " distance: " .. tostring(args.distance))
    TriggerServerEvent("bcc_scene:movebackwards", args.index, args.coords, args.distance)
    cb('ok')
end)