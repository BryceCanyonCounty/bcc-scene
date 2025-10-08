local BccUtils = exports['bcc-utils'].initiate()
local Framework = Config.Framework
local UseDatabase = Config.UseDataBase

if Framework == 'vorp' then
    Core = exports.vorp_core:GetCore()
else
    RSGCore = exports['rsg-core']:GetCoreObject()
end

local function Notify(text, src)
    if Framework == 'vorp' then
        Core.NotifyRightTip(src, text, 3000)
    else
        TriggerClientEvent('RSGCore:Notify', src, text, 'error')
    end
end

local function isPlayers(datas, src)
    if Framework == 'vorp' then
        local User = Core.getUser(src)
        local Character = User.getUsedCharacter
        return tostring(datas[nr].id) == Character.identifier and tonumber(datas[nr].charid) == Character.charIdentifier
    else
        local User = RSGCore.Functions.GetPlayer(src)
        local Character = User.PlayerData
		-- 'discord' and 'license are the only identifiers that work via rsg-core.'
        return tostring(datas[nr].id) == RSGCore.Functions.GetIdentifier(src, 'discord') and tonumber(datas[nr].charid) == Character.cid
    end
end

local function getPlayerInfo(src)
	local User
    local Character
    local identi
    local charid

    if Framework == 'vorp' then
        User = Core.getUser(src)
        Character = User.getUsedCharacter
        identi = Character.identifier
        charid = Character.charIdentifier
    else
        User = RSGCore.Functions.GetPlayer(src)
        Character = User.PlayerData
		-- 'discord' and 'license are the only identifiers that work via rsg-core.'
        identi = RSGCore.Functions.GetIdentifier(source, 'discord')
        charid = Character.cid
    end

    return {
        User = User,
        Character = Character,
        identi = identi,
        charid = charid
    }
end

local function dump(o)
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

AddEventHandler('onResourceStart', function(resource)
    if Config.RestartDelete == true then
        if UseDatabase == true then
            MySQL.Async.execute('DELETE FROM scenes', {}, function(rowsChanged)
                print('Deleting all Scenes', rowsChanged .. ' rows were deleted from the scenes table.')
            end)
        else
            local Scenes_a = {}
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(Scenes_a))
        end
    end

    if UseDatabase == true then
        local raw_store = LoadResourceFile(GetCurrentResourceName(), "./store.json")
        local data_store = json.decode(raw_store)

        if data_store.created_table == false then
            -- Setup server table
            MySQL.query([[
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

            print("Created Scenes Table")
            data_store.created_table = true
            SaveResourceFile(GetCurrentResourceName(), "./store.json", json.encode(data_store))
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

RegisterNetEvent("bcc_scene:add", function(text,coords)
    local src = source
    local _text = tostring(text)

    local player = getPlayerInfo(src)
    local identi = player.identi
    local charid = player.charid

    if UseDatabase == true then
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

RegisterNetEvent("bcc_scene:getscenes", function(text)
	local src = source
    if UseDatabase == true then
        refreshClientScenes()
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        TriggerClientEvent("bcc_scene:sendscenes", src, datas)
    end
end)

RegisterNetEvent("bcc_scene:delete", function(nr)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

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

        if isPlayers(datas, src) then
            table.remove( datas, nr)
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        else
            Notify(Config.Texts.NoAuth, src)
        end

    end
end)

RegisterNetEvent("bcc_scene:getCharData", function()
    local id
    local charid
    local job
    local group
    local src = source

    if Framework == 'rsg-core' then
        local User = RSGCore.Functions.GetPlayer(src)
        local Character = User.PlayerData

        id = RSGCore.Functions.GetIdentifier(src, 'steam')
        charid = Character.cid
        job = Character.job
        group = Character.group
    else
	local Character = Core.getUser(src).getUsedCharacter 

        id = Character.identifier
        charid = Character.charIdentifier
        job = Character.job
        group = Character.group
    end

    TriggerClientEvent("bcc_scene:retrieveCharData", src, id, charid, job, group)
end)

RegisterNetEvent("bcc_scene:edit", function(nr)
	local src = source

    if UseDatabase == false then
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if isPlayers(datas, src) then
            TriggerClientEvent("bcc_scene:client_edit", src, nr)
            return
        else
            Notify(Config.Texts.NoAuth, src)
        end
    end
end)

RegisterNetEvent("bcc_scene:color", function(nr, color)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

        local result = MySQL.update.await('UPDATE scenes SET `color` = @color WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@color"] = color})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if isPlayers(datas, src) then
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
            Notify(Config.Texts.NoAuth, src)
        end
    end
end)

RegisterNetEvent("bcc_scene:background", function(nr, color)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

        local result = MySQL.update.await('UPDATE scenes SET `bg` = @bg WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@bg"] = color})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if isPlayers(datas, src) then
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
            Notify(Config.Texts.NoAuth, src)
        end
    end
end)

RegisterNetEvent("bcc_scene:font", function(nr, font)
	local src = source

    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

        local result = MySQL.update.await('UPDATE scenes SET `font` = @font WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@font"] = font})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if isPlayers(datas, src) then
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
            Notify(Config.Texts.NoAuth, src)
        end
    end
end)

RegisterNetEvent("bcc_scene:edited", function(text,nr)
	local src = source
    local _text = tostring(text)

    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

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

RegisterNetEvent("bcc_scene:scale", function(nr, scale)
    local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

        local result = MySQL.update.await('UPDATE scenes SET `scale` = @scale WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@scale"] = scale})
        if not result then
            print("ERROR: Failed to update pages!", dump(result))
        else
            refreshClientScenes()
        end
    else
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if isPlayers(datas, src) then
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
            Notify(Config.Texts.NoAuth, src)
        end
    end
end)

RegisterNetEvent("bcc_scene:moveup", function(nr, coords, distance)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

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

        if isPlayers(datas, src) then
            datas[nr].coords.z = datas[nr].coords.z + distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterNetEvent("bcc_scene:movedown", function(nr, coords, distance)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid
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

        if isPlayers(datas, src) then
            datas[nr].coords.z = datas[nr].coords.z - distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterNetEvent("bcc_scene:moveleft", function(nr, coords, distance)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid
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

        if isPlayers(datas, src) then
            datas[nr].coords.x = datas[nr].coords.x + distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterNetEvent("bcc_scene:moveright", function(nr, coords, distance)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

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

        if isPlayers(datas, src) then
            datas[nr].coords.x = datas[nr].coords.x - distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterNetEvent("bcc_scene:moveforward", function(nr, coords, distance)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

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

        if isPlayers(datas, src) then
            datas[nr].coords.y = datas[nr].coords.y - distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

RegisterNetEvent("bcc_scene:movebackwards", function(nr, coords, distance)
	local src = source
    if UseDatabase == true then
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

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

        if isPlayers(datas, src) then
            datas[nr].coords.y = datas[nr].coords.y + distance
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        end
    end
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-scene')
