---@type BCCSceneDebugLib
local DBG = BCCSceneDebug

local Framework = Config.Framework

if Framework == 'vorp' then
    Core = exports.vorp_core:GetCore()
    DBG.Info("Server - Framework initialized: VORP Core")
else
    RSGCore = exports['rsg-core']:GetCoreObject()
    DBG.Info("Server - Framework initialized: RSG Core")
end

local BccUtils = exports['bcc-utils'].initiate()
local UseDatabase = Config.UseDataBase

DBG.Info("Server - UseDatabase setting: " .. tostring(UseDatabase))

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
    DBG.Info("Server - Resource starting: " .. resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    DBG.Info("Server - BCC Scene resource started")
    if Config.RestartDelete == true then
        DBG.Warning("Server - RestartDelete is enabled - clearing all scenes")
        if UseDatabase == true then
            MySQL.Async.execute('DELETE FROM scenes', {}, function(rowsChanged)
                DBG.Info('Server - Deleted ' .. rowsChanged .. ' scenes from database')
                print('Deleting all Scenes', rowsChanged .. ' rows were deleted from the scenes table.')
            end)
        else
            local Scenes_a = {}
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(Scenes_a))
            DBG.Info("Server - Cleared scenes.json file")
        end
    end

    if UseDatabase == true then
        DBG.Info("Server - Database mode enabled - checking table setup")
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
    DBG.Info("Server - Refreshing client scenes from database")
    local result = MySQL.query.await('SELECT * FROM scenes')
    if not result then
        DBG.Error("Server - Failed to query scenes from database")
        print("ERROR: Failed to update pages!", dump(result))
    else
        DBG.Info("Server - Retrieved " .. #result .. " scenes from database, sending to all clients")
        TriggerClientEvent("bcc_scene:sendscenes", -1, result)
    end
end

RegisterNetEvent("bcc_scene:add", function(text,coords)
    local src = source
    local _text = tostring(text)
    DBG.Info("Server - Scene add request from player " .. src .. " with text: '" .. _text .. "' at coords: " .. tostring(coords))

    local player = getPlayerInfo(src)
    local identi = player.identi
    local charid = player.charid

    DBG.Info("Server - Player info - ID: " .. tostring(identi) .. ", CharID: " .. tostring(charid))

    if UseDatabase == true then
        DBG.Info("Server - Adding scene to database")
        local result = MySQL.insert.await('INSERT INTO scenes (`id`, `charid`, `text`, `coords`, `font`, `color`, `bg`, `scale`) VALUES (@id, @charid, @text, @coords, @font, @color, @bg, @scale)', {["@id"] = identi, ["@charid"] = charid, ["@text"] = _text, ["@coords"] = json.encode({x=coords.x, y=coords.y, z=coords.z}), ["@font"] = Config.Defaults.Font, ["@color"] = Config.Defaults.Color, ["@bg"] =  Config.Defaults.BackgroundColor, ["@scale"] = Config.StartingScale})
        if not result then
            DBG.Error("Server - Failed to insert scene into database")
            print("ERROR: Failed to update pages!", dump(result))
        else
            DBG.Success("Server - Scene successfully added to database with ID: " .. tostring(result))
            refreshClientScenes()
        end
    else
        DBG.Info("Server - Adding scene to JSON file")
        local scene = {id = identi, charid = charid, text = _text, coords = json.encode(coords), font = Config.Defaults.Font, color = Config.Defaults.Color, bg = Config.Defaults.BackgroundColor, scale = Config.StartingScale}
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        datas[#datas+1] = scene
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        DBG.Success("Server - Scene successfully added to JSON file")
        TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
    end
end)

RegisterNetEvent("bcc_scene:getscenes", function(text)
	local src = source
    DBG.Info("Server - Scene request from player " .. src)
    if UseDatabase == true then
        DBG.Info("Server - Fetching scenes from database for player " .. src)
        refreshClientScenes()
    else
        DBG.Info("Server - Fetching scenes from JSON file for player " .. src)
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        DBG.Info("Server - Sending " .. #datas .. " scenes to player " .. src)
        TriggerClientEvent("bcc_scene:sendscenes", src, datas)
    end
end)

RegisterNetEvent("bcc_scene:delete", function(nr)
	local src = source
    DBG.Info("Server - Scene delete request from player " .. src .. " for scene ID: " .. tostring(nr))

    if UseDatabase == true then
        DBG.Info("Server - Deleting scene from database")
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

        if Config.AllowAnyoneToDelete then
            DBG.Info("Server - AllowAnyoneToDelete is enabled - deleting scene")
            local result = MySQL.query.await('DELETE FROM scenes WHERE autoid = @autoid', {["@autoid"] = nr})
            if not result then
                DBG.Error("Server - Failed to delete scene from database")
                print("ERROR: Failed to update pages!", dump(result))
            else
                DBG.Success("Server - Scene deleted from database")
                refreshClientScenes()
            end
        else
            DBG.Info("Server - Checking ownership before deletion")
            local result = MySQL.query.await('DELETE FROM scenes WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr})
            if not result then
                DBG.Error("Server - Failed to delete scene from database")
                print("ERROR: Failed to update pages!", dump(result))
            else
                DBG.Success("Server - Scene deleted from database")
                refreshClientScenes()
            end
        end
    else
        DBG.Info("Server - Deleting scene from JSON file")
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)

        if isPlayers(datas, src) then
            DBG.Success("Server - Player owns scene - deleting from JSON")
            table.remove( datas, nr)
            SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
            TriggerClientEvent("bcc_scene:sendscenes", -1, datas)
            return
        else
            DBG.Warning("Server - Player does not own scene - denying deletion")
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

    DBG.Info("Server - Character data request from player " .. src)

    if Framework == 'rsg-core' then
        DBG.Info("Server - Using RSG Core framework to get player data")
        local User = RSGCore.Functions.GetPlayer(src)
        local Character = User.PlayerData

        id = RSGCore.Functions.GetIdentifier(src, 'steam')
        charid = Character.cid
        job = Character.job
        group = Character.group
    else
        DBG.Info("Server - Using VORP Core framework to get player data")
	local Character = Core.getUser(src).getUsedCharacter 

        id = Character.identifier
        charid = Character.charIdentifier
        job = Character.job
        group = Character.group
    end

    DBG.Info("Server - Sending character data to player " .. src .. " - ID: " .. tostring(id) .. ", CharID: " .. tostring(charid) .. ", Job: " .. tostring(job) .. ", Group: " .. tostring(group))
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
    DBG.Info("Server - Scene edit request from player " .. src .. " for scene ID: " .. tostring(nr) .. " with new text: '" .. _text .. "'")

    if UseDatabase == true then
        DBG.Info("Server - Updating scene in database")
        local player = getPlayerInfo(src)
        local identi = player.identi
        local charid = player.charid

        local result = MySQL.update.await('UPDATE scenes SET `text` = @text WHERE id = @id AND charid = @charid AND autoid = @autoid', {["@id"] = identi, ["@charid"] = charid, ["@autoid"] = nr, ["@text"] = _text})
        if not result then
            DBG.Error("Server - Failed to update scene text in database")
            print("ERROR: Failed to update pages!", dump(result))
        else
            DBG.Success("Server - Scene text updated in database")
            refreshClientScenes()
        end
    else
        DBG.Info("Server - Updating scene in JSON file")
        local edata = LoadResourceFile(GetCurrentResourceName(), "./scenes.json")
        local datas = json.decode(edata)
        datas[nr].text = _text
        SaveResourceFile(GetCurrentResourceName(), "./scenes.json", json.encode(datas))
        DBG.Success("Server - Scene text updated in JSON file")
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
