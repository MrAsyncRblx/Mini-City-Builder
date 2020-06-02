-- Log Api
-- MrAsync
-- June 2, 2020


--[[

    Handles the logging of events in-game

    Methods:
        public void Log(String info)
        public void LogWarn(String info)
        public void LogError(String info)

]]


local LogApi = {}

--//Api

--//Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Classes

--//Controllers

--//Locals
local SessionLog = {}


--//Logs a normal event
function LogApi:Log(info)
    print("Log @", info)

    table.insert(SessionLog, "Log @ " .. info)
end


--//Logs a warning event
function LogApi:LogWarn(info)
    warn("Warning @", info)

    table.insert(SessionLog, "Warning @ " .. info)
end


--//Logs an error event
function LogApi:LogError(info)
    error("Error @", info)

    table.insert(SessionLog, "Error @ " .. info)
end


function LogApi:Init()
    --//Api

    --//Services

    --//Classes

    --//Controllers

    --//Locals

end


return LogApi