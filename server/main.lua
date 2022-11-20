TriggerEvent("getCore",function(core)
    VorpCore = core
end)

Citizen.CreateThread(function()
    if Config.RestartDelete == true then
        local Scenes_a = {}
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(Scenes_a))
    end
end)

RegisterServerEvent("bcc_scene:add")
AddEventHandler("bcc_scene:add", function(text,coords)
	local _source = source
    local _text = tostring(text)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    local identi = Character.identifier
    local charid = Character.charIdentifier	
    local scene = {id = identi, charid = charid, text = _text, coords = coords, font = Config.Defaults.Font, color = Config.Defaults.Color, bg = Config.Defaults.BackgroundColor, scale = Config.StartingScale}
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
    datas[#datas+1] = scene
    SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
    TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
end)

RegisterServerEvent("bcc_scene:getscenes")
AddEventHandler("bcc_scene:getscenes", function(text)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
    TriggerClientEvent("bcc_scene:sendscenes", _source, datas)
end)

RegisterServerEvent("bcc_scene:delete")
AddEventHandler("bcc_scene:delete", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        table.remove( datas, nr)
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    else
        TriggerClientEvent("vorp:TipBottom", _source, Config.Texts.NoAuth, 2000)
    end
end)

RegisterServerEvent("bcc_scene:edit")
AddEventHandler("bcc_scene:edit", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        TriggerClientEvent("bcc_scene:client_edit", _source, nr)
        return
    else
        TriggerClientEvent("vorp:TipBottom", _source, Config.Texts.NoAuth, 2000)
    end
end)

RegisterServerEvent("bcc_scene:color")
AddEventHandler("bcc_scene:color", function(nr, color)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        if color ~= nil then
            datas[nr].color = color
        else
            datas[nr].color = datas[nr].color + 1
            if datas[nr].color > #Config.Colors then
                datas[nr].color = 1
            end
        end
        
        
        
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    else
        TriggerClientEvent("vorp:TipBottom", _source, Config.Texts.NoAuth, 2000)
    end
end)

RegisterServerEvent("bcc_scene:background")
AddEventHandler("bcc_scene:background", function(nr, color)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        if color ~= nil then
            datas[nr].bg = color
        else
            datas[nr].bg = datas[nr].bg + 1
            if datas[nr].bg > #Config.Colors then
                datas[nr].bg = 1
            end
        end
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    else
        TriggerClientEvent("vorp:TipBottom", _source, Config.Texts.NoAuth, 2000)
    end
end)

RegisterServerEvent("bcc_scene:font")
AddEventHandler("bcc_scene:font", function(nr, font)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter

    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        
        if font ~= nil then
            datas[nr].font = font
        else
            datas[nr].font = datas[nr].font + 1
            if datas[nr].font > #Config.Fonts then
                datas[nr].font = 1
            end
        end
        
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    else
        TriggerClientEvent("vorp:TipBottom", _source, Config.Texts.NoAuth, 2000)
    end
end)

RegisterServerEvent("bcc_scene:edited")
AddEventHandler("bcc_scene:edited", function(text,nr)
	local _source = source
    local _text = tostring(text)
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
    datas[nr].text = _text
    SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
    TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
end)

RegisterServerEvent("bcc_scene:scale")
AddEventHandler("bcc_scene:scale", function(nr, scale)
    local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        if scale ~= nil then
            datas[nr].scale = scale
        else
            datas[nr].scale = datas[nr].scale + 0.05
            if datas[nr].scale > Config.MaxScale then
                datas[nr].scale = Config.StartingScale
            end
        end
        
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    else
        TriggerClientEvent("vorp:TipBottom", _source, Config.Texts.NoAuth, 2000)
    end
end)

RegisterServerEvent("bcc_scene:moveup")
AddEventHandler("bcc_scene:moveup", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        datas[nr].coords.z = datas[nr].coords.z + 0.009
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    end
end)

RegisterServerEvent("bcc_scene:movedown")
AddEventHandler("bcc_scene:movedown", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        datas[nr].coords.z = datas[nr].coords.z - 0.009
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    end
end)

RegisterServerEvent("bcc_scene:moveleft")
AddEventHandler("bcc_scene:moveleft", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        datas[nr].coords.x = datas[nr].coords.x + 0.009
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    end
end)

RegisterServerEvent("bcc_scene:moveright")
AddEventHandler("bcc_scene:moveright", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        datas[nr].coords.x = datas[nr].coords.x - 0.009
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    end
end)

RegisterServerEvent("bcc_scene:moveforward")
AddEventHandler("bcc_scene:moveforward", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        datas[nr].coords.y = datas[nr].coords.y - 0.009
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    end
end)

RegisterServerEvent("bcc_scene:movebackwards")
AddEventHandler("bcc_scene:movebackwards", function(nr)
	local _source = source
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
        datas[nr].coords.y = datas[nr].coords.y + 0.009
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
        return
    end
end)