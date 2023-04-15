TriggerEvent("getCore",function(core)
    VorpCore = core
end)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

Citizen.CreateThread(function()
    if Config.RestartDelete == true and Config.UseDataBase == false then
        local Scenes_a = {}
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(Scenes_a))
    end

    if Config.UseDataBase == true then
        local result = exports.ghmattimysql:executeSync([[
            CREATE TABLE IF NOT EXISTS `scenes` (
                `autoid` INT(20) NOT NULL AUTO_INCREMENT,
                `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
                `charid` INT(30) NOT NULL DEFAULT '0',
                `text` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
                `coords` JSON,
                `font` INT(30) NOT NULL DEFAULT '0',
                `color` INT(30) NOT NULL DEFAULT '0',
                `bg` INT(30) NOT NULL DEFAULT '0',
                `scale` DOUBLE NOT NULL DEFAULT '0',
                PRIMARY KEY (`autoid`),
                CONSTRAINT `FK_bccscenes_users` FOREIGN KEY (`id`) REFERENCES `users` (`identifier`) ON DELETE CASCADE ON UPDATE CASCADE,
                INDEX `autoid` (`autoid`),
                INDEX `id` (`id`),
                INDEX `charid` (`charid`)
            ) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = DYNAMIC;

        ]])
        if result and result.warningStatus > 1 then
            print("ERROR: Failed to create Scene WL Table", dump(result))
        end
    end
end)

local function refreshClientScenes()
    local result = MySQL.query.await('SELECT * FROM scenes')
    if not result then
        print("ERROR: Failed to update pages!", dump(result))
    else
        TriggerClientEvent("bcc_scene:sendscenes", -1, result)
    end
end

RegisterServerEvent("bcc_scene:add", function(text,coords)
	local _source = source
    local _text = tostring(text)
	local User = VorpCore.getUser(_source)
    local Character = User.getUsedCharacter
    local identi = Character.identifier
    local charid = Character.charIdentifier

    if Config.UseDataBase == true then
        local result = MySQL.insert.await('INSERT INTO scenes (`id`, `charid`, `text`, `coords`, `font`, `color`, `bg`, `scale`) VALUES (@id, @charid, @text, @coords, @font, @color, @bg, @scale)', {["@id"] = identi, ["@charid"] = charid, ["@text"] = _text, ["@coords"] = json.encode({x=coords.x, y=coords.y, z=coords.z}), ["@font"] = Config.Defaults.Font, ["@color"] = Config.Defaults.Color, ["@bg"] =  Config.Defaults.BackgroundColor, ["@scale"] = Config.StartingScale})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local scene = {id = identi, charid = charid, text = _text, coords = json.encode(coords), font = Config.Defaults.Font, color = Config.Defaults.Color, bg = Config.Defaults.BackgroundColor, scale = Config.StartingScale}
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        datas[#datas+1] = scene
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
    end
end)

RegisterServerEvent("bcc_scene:getscenes", function(text)
	local _source = source
    if Config.UseDataBase == true then
        refreshClientScenes()
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        TriggerClientEvent("bcc_scene:sendscenes", _source, datas)
    end
end)

RegisterServerEvent("bcc_scene:delete", function(nr)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        if Config.AllowAnyoneToDelete then
            local result = MySQL.query.await('DELETE FROM scenes WHERE autoid = @autoid', {["@autoid"] = nr})
            if not result then
                print("ERROR: Failed to update pages!", dump(result))
            else
                refreshClientScenes()
            end
        else
            local result = MySQL.query.await('DELETE FROM scenes WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr})
            if not result then
                print("ERROR: Failed to update pages!", dump(result))
            else
                refreshClientScenes()
            end
        end
    else
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

    end
end)

RegisterServerEvent("bcc_scene:getCharData", function()
    local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    TriggerClientEvent("bcc_scene:retrieveCharData", source, Character.identifier, Character.charIdentifier, Character.job, Character.group)
end)

RegisterServerEvent("bcc_scene:edit", function(nr)
	local _source = source

    if Config.UseDataBase == false then
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
    end
end)

RegisterServerEvent("bcc_scene:color", function(nr, color)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        local result = MySQL.update.await('UPDATE scenes SET `color` = @color WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@color"] = color})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
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
    end
end)

RegisterServerEvent("bcc_scene:background", function(nr, color)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        local result = MySQL.update.await('UPDATE scenes SET `bg` = @bg WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@bg"] = color})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
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
    end
end)

RegisterServerEvent("bcc_scene:font", function(nr, font)
	local _source = source

    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        local result = MySQL.update.await('UPDATE scenes SET `font` = @font WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@font"] = font})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
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
    end
end)

RegisterServerEvent("bcc_scene:edited", function(text,nr)
	local _source = source
    local _text = tostring(text)

    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        local result = MySQL.update.await('UPDATE scenes SET `text` = @text WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@text"] = _text})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        datas[nr].text = _text
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
    end
end)

RegisterServerEvent("bcc_scene:scale", function(nr, scale)
    local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        local result = MySQL.update.await('UPDATE scenes SET `scale` = @scale WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@scale"] = scale})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
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
    end
end)

RegisterServerEvent("bcc_scene:moveup", function(nr, coords, distance)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        coords = json.decode(coords)
        coords.z = coords.z + distance
        local result = MySQL.update.await('UPDATE scenes SET `coords` = @coords WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@coords"] = json.encode(coords)})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
            datas[nr].coords.z = datas[nr].coords.z + distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:movedown", function(nr, coords, distance)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        coords = json.decode(coords)
        coords.z = coords.z - distance
        local result = MySQL.update.await('UPDATE scenes SET `coords` = @coords WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@coords"] = json.encode(coords)})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
            datas[nr].coords.z = datas[nr].coords.z - distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:moveleft", function(nr, coords, distance)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        coords = json.decode(coords)
        coords.x = coords.x + distance
        local result = MySQL.update.await('UPDATE scenes SET `coords` = @coords WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@coords"] = json.encode(coords)})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
            datas[nr].coords.x = datas[nr].coords.x + distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:moveright", function(nr, coords, distance)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        coords = json.decode(coords)
        coords.x = coords.x - distance
        local result = MySQL.update.await('UPDATE scenes SET `coords` = @coords WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@coords"] = json.encode(coords)})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
            datas[nr].coords.x = datas[nr].coords.x - distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:moveforward", function(nr, coords, distance)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier

        coords = json.decode(coords)
        coords.y = coords.y - distance
        local result = MySQL.update.await('UPDATE scenes SET `coords` = @coords WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@coords"] = json.encode(coords)})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
            datas[nr].coords.y = datas[nr].coords.y - distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterServerEvent("bcc_scene:movebackwards", function(nr, coords, distance)
	local _source = source
    if Config.UseDataBase == true then
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        local identi = Character.identifier
        local charid = Character.charIdentifier
        coords = json.decode(coords)
        coords.y = coords.y + distance
        local result = MySQL.update.await('UPDATE scenes SET `coords` = @coords WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@coords"] = json.encode(coords)})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        local User = VorpCore.getUser(_source)
        local Character = User.getUsedCharacter
        if tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier then
            datas[nr].coords.y = datas[nr].coords.y + distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)
