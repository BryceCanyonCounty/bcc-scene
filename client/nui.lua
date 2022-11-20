UI = {}

UIOpen = false

function UI:Update(scenes, ActiveScene)
    for index, scene in ipairs(scenes) do
        if ActiveScene and ActiveScene.autoid == scene.autoid then
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
    SendNUIMessage({
        type = 'toggle',
        visible = false,
        subtitle = '',
        config = Config,
        index = 0
    })
    SetNuiFocus(false, false)
    UIOpen = false
end

RegisterNUICallback('close', function(args, cb)
    SetNuiFocus(false, false) -- Sets the focus of the player view away from NUI
    UIOpen = false
    cb('ok')
end)


RegisterNUICallback('editscene', function(args, cb)
    TriggerServerEvent("bcc_scene:edit", args.index)
    UI:Close()
    cb('ok')
end)

RegisterNUICallback('deletescene', function(args, cb)
    TriggerServerEvent("bcc_scene:delete", args.index)
    UI:Close()
    cb('ok')
end)

RegisterNUICallback('updatecolor', function(args, cb)
    TriggerServerEvent("bcc_scene:color", args.index, args.color)
    cb('ok')
end)

RegisterNUICallback('updatebackgroundcolor', function(args, cb)
    TriggerServerEvent("bcc_scene:background", args.index, args.color)
    cb('ok')
end)

RegisterNUICallback('updatefont', function(args, cb)
    TriggerServerEvent("bcc_scene:font", args.index, args.font)
    cb('ok')
end)

RegisterNUICallback('updatescale', function(args, cb)
    TriggerServerEvent("bcc_scene:scale", args.index, args.scale)
    cb('ok')
end)

RegisterNUICallback('updatetext', function(args, cb)
    TriggerServerEvent("bcc_scene:edited", args.text, args.index)
    cb('ok')
end)

RegisterNUICallback('moveup', function(args, cb)
    TriggerServerEvent("bcc_scene:moveup", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('movedown', function(args, cb)
    TriggerServerEvent("bcc_scene:movedown", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('moveleft', function(args, cb)
    TriggerServerEvent("bcc_scene:moveleft", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('moveright', function(args, cb)
    TriggerServerEvent("bcc_scene:moveright", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('moveforward', function(args, cb)
    TriggerServerEvent("bcc_scene:moveforward", args.index, args.coords, args.distance)
    cb('ok')
end)

RegisterNUICallback('movebackwards', function(args, cb)
    TriggerServerEvent("bcc_scene:movebackwards", args.index, args.coords, args.distance)
    cb('ok')
end)