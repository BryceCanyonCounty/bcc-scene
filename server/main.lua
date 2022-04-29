TriggerEvent("getCore",function(core)
    VorpCore = core
end)

Citizen.CreateThread(function()
    if Config.RestartDelete == true then
        if Config.StoreToDB == true then 
            exports.ghmattimysql:execute("DELETE FROM scenes", {}, function(result)
                print('Scenes Table has been reset per RestartDelete config')   
            end)
        else
            local Scenes_a = {}
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(Scenes_a))
        end
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
    local scene = {identifier = identi, charidentifier = charid, text = _text, coords = coords, font = 1, color = 1, bg = 0, scale = 0.3}
   
    if Config.StoreToDB == true then 
        exports.ghmattimysql:execute("INSERT INTO scenes (identifier, charidentifier, text, coords, font, color, bg, scale) VALUES (@identifier, @charidentifier, @text, @coords, @font, @color, @bg, @scale)", {["@identifier"] = scene.identifier, ["@charidentifier"] = scene.charidentifier, ["@text"] = scene.text, ["@coords"] = scene.coords,  ["@font"] = scene.font,  ["@color"] = scene.color,  ["@bg"] = scene.bg, ["@scale"] = scene.scale}, function(result)
            if result ~= nil then
                exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
                    if result2[1] ~= nil then
                        TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
                    else
                        TriggerClientEvent("vorp:TipBottom", _source, 'An Error has Occurred', 5000)
                    end
                end)
            else
                TriggerClientEvent("vorp:TipBottom", _source, 'An Error has Occurred', 5000)
            end
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        datas[#datas+1] = scene
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
    end
end)

RegisterServerEvent("bcc_scene:getscenes")
AddEventHandler("bcc_scene:getscenes", function(text)
	local _source = source
    
    if Config.StoreToDB == true then 
        exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
            if result2[1] ~= nil then
                TriggerClientEvent("bcc_scene:sendscenes", _source, result2)
            else
                TriggerClientEvent("vorp:TipBottom", _source, 'An Error has Occurred', 5000)
            end
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        TriggerClientEvent("bcc_scene:sendscenes", _source, datas)
    end
end)

RegisterServerEvent("bcc_scene:delete")
AddEventHandler("bcc_scene:delete", function(nr, coords)
	local _source = source
    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    if Config.StoreToDB == true then 
        exports.ghmattimysql:execute("DELETE FROM scenes WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords}, function(result)
            exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
                if result2[1] ~= nil then
                    TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
                else
                    TriggerClientEvent("bcc_scene:sendscenes", -1, {}})
                end
            end)
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        --print(Character.charIdentifier,Character.identifier)
        --print(datas[nr].charid,datas[nr].id)
        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            table.remove( datas, nr)
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:edit")
AddEventHandler("bcc_scene:edit", function(nr, coords)
	local _source = source
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter

    if Config.StoreToDB == true then 
        exports.ghmattimysql:execute("SELECT * FROM scenes WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords}, function(result)
            if result[1] ~= nil then
                TriggerClientEvent("bcc_scene:client_edit", _source, nr, coords)
                return
            end
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            TriggerClientEvent("bcc_scene:client_edit", _source, nr, coords)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:moveright")
AddEventHandler("bcc_scene:moveright", function(nr, coords, x)
	-- This is not used currently
    
    local _source = source
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter

    
    
    
    local newcoords = 0



    if Config.StoreToDB == true then 
        -- exports.ghmattimysql:execute("UPDATE scenes SET coords = @newcoords WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@newcoords"] = newcoords, ["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords})      
        --     exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
        --         if result2[1] ~= nil then
        --             TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
        --         else
        --             print("Error searching for scenes: line 136")
        --         end
        --     end)
        -- end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            datas[nr].coords.y = datas[nr].coords.x + 0.005
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:color")
AddEventHandler("bcc_scene:color", function(nr, coords, color)
	local _source = source
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    if Config.StoreToDB == true then 
        local ncolor = color
        ncolor = ncolor + 1
        if ncolor > #Config.Colors then
            ncolor = 1
        end

        exports.ghmattimysql:execute("UPDATE scenes SET color = @color WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@color"] = ncolor, ["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords})      
            exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
                if result2[1] ~= nil then
                    TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
                else
                    print("Error searching for scenes: line 179")
                end
            end)
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            datas[nr].color = datas[nr].color + 1
                if datas[nr].color > #Config.Colors then
                    datas[nr].color = 1
                end
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:background")
AddEventHandler("bcc_scene:background", function(nr, coords, background)
	local _source = source
	local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter

    if Config.StoreToDB == true then 
        local bg = background
        bg = bg + 1
        if bg > #Config.Colors then
            bg = 1
        end

        exports.ghmattimysql:execute("UPDATE scenes SET bg = @bg WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@bg"] = bg, ["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords})      
            exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
                if result2[1] ~= nil then
                    TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
                else
                    print("Error searching for scenes: line 179")
                end
            end)
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            datas[nr].bg = datas[nr].bg + 1
            if datas[nr].bg > #Config.Colors then
                datas[nr].bg = 1
            end
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:font")
AddEventHandler("bcc_scene:font", function(nr, coords, font)
	local _source = source
    local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter

    if Config.StoreToDB == true then 
        local ft = font
        ft = ft + 1
        if ft > #Config.Fonts then
            ft = 1
        end

        exports.ghmattimysql:execute("UPDATE scenes SET font = @font WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@font"] = ft, ["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords})      
            exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
                if result2[1] ~= nil then
                    TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
                else
                    print("Error searching for scenes: line 179")
                end
            end)
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            datas[nr].font = datas[nr].font + 1
            if datas[nr].font > #Config.Fonts then
                datas[nr].font = 1
            end
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:edited")
AddEventHandler("bcc_scene:edited", function(text, nr, coords)
	local _source = source
    local _text = tostring(text)
    local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
    local datas = json.decode(edata)
    datas[nr].text = _text
    SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
    TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
end)

RegisterServerEvent("bcc_scene:scale")
AddEventHandler("bcc_scene:scale", function(nr, coords, scale)
    local _source = source
    local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter

    if Config.StoreToDB == true then 
        local sc = scale
        sc = sc + 0.05
        if sc > Config.MaxScale then
            sc = 0.2
        end
        exports.ghmattimysql:execute("UPDATE scenes SET scale = @scale WHERE identifier = @identifier AND charidentifier = @charidentifier AND coords = @coords", {["@scale"] = sc, ["@identifier"] = Character.identifier, ["@charidentifier"] = Character.charIdentifier, ["@coords"] = coords})      
            exports.ghmattimysql:execute("SELECT * FROM scenes", {}, function(result2)
                if result2[1] ~= nil then
                    TriggerClientEvent("bcc_scene:sendscenes", -1, result2)
                else
                    print("Error searching for scenes: line 179")
                end
            end)
        end)
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        if tostring(datas[nr].identifier) == Character.identifier and tonumber(datas[nr].charidentifier) == Character.charIdentifier then
            datas[nr].scale = datas[nr].scale + 0.05
            print(datas[nr].scale)
            if datas[nr].scale > Config.MaxScale then
                datas[nr].scale = 0.2
            end
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)