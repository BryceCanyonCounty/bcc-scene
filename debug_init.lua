-- DO NOT MAKE CHANGES TO THIS FILE
if not BCCSceneDebug then
    ---@class BCCSceneDebugLib
    ---@field Info fun(message: string)
    ---@field Error fun(message: string)
    ---@field Warning fun(message: string)
    ---@field Success fun(message: string)
    ---@field DevModeActive boolean
    BCCSceneDebug = {}

    BCCSceneDebug.DevModeActive = Config and Config.Devmode and Config.Devmode.Active or false

    -- No-op function
    local function noop() end

    -- Function to create loggers
    local function createLogger(prefix, color)
        if BCCSceneDebug.DevModeActive then
            return function(message)
                print(('^%d[%s] ^3%s^0'):format(color, prefix, message))
            end
        else
            return noop
        end
    end

    -- Create loggers with appropriate colors
    BCCSceneDebug.Info = createLogger("INFO", 5)    -- Purple
    BCCSceneDebug.Error = createLogger("ERROR", 1)  -- Red
    BCCSceneDebug.Warning = createLogger("WARNING", 3) -- Yellow
    BCCSceneDebug.Success = createLogger("SUCCESS", 2) -- Green
end
