-- Plot
-- MrAsync
-- June 26, 2020



local Plot = {}
Plot.__index = Plot

--//Api
local CompressionApi
local DataApi

--//Services
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local PlayerService

--//Classes
local BuildingClass
local StackClass
local MaidClass

--//Controllers

--//Locals
local LandStack


function Plot.new(pseudoPlayer)
    local self = setmetatable({
        Player = pseudoPlayer.Player,
        Object = LandStack:Pop(),

        Loaded = false,
        _Maid = MaidClass.new()
    }, Plot)


    --Sterilization
    if (not self.Object) then
        warn(self.Player.Name, "was not given a plot!")

        self.Object = LandStack:Pop()
        if (not self.Object) then
            self.Player:Kick("We're sorry, something went wrong.  Please rejoin!")
        end
    end

    return self
end


function Plot:ShowPlate(plateNumber)
    local decor = self.Object.Locked.Decor:FindFirstChild(tostring(plateNumber))
    local plate = self.Object.Locked.Plates:FindFirstChild(tostring(plateNumber))

    decor.Parent = self.Object.Decor
    plate.Parent = self.Object.Plates

    decor.Transparency = 0
    plate.Grid.Transparency = 1
    plate.GridDash.Transparency = 1
end


function Plot:LoadSave(pseudoPlayer)
    self.Data:Get("Placements", ""):Then(function(rawBuildData)
        print(rawBuildData)

        if (rawBuildData == "") then
            print("HERE!")

            self.Loading = true
            wait(5)
            self.Loading = false

            return PlayerService:FireClient("PlotLoaded", self.Player, self.Object)
        end

        local buildData = self:DeserializeData(rawBuildData)
        local ownedPlates = self.Data:Get("OwnedPlates", {})
        self.Loading = true

        --Load plates
        for _, ownedPlate in pairs(ownedPlates) do
            self:ShowPlate(ownedPlate)
        end

        --Load builds
        local steppedConnection
        local numericalTable = {}
        local currentIndex = 1

        --Temporarily store all items in a sub-table in numericalTable
        for guid, JSONData in pairs(buildData) do
            table.insert(numericalTable, {guid, JSONData})
        end

        --Failsafe to prevent error spam if player leaves while loading
        local failSafe = Players.PlayerRemoving:Connect(function(player)
            if (player.Name == self.Player.Name) then
                if (steppedConnection) then
                    steppedConnection:Disconnect()
                end
            end
        end)

        --Load items when stepped
        steppedConnection = RunService.Stepped:Connect(function()
            local buildInfo = numericalTable[currentIndex]

            --Run once all buildings are loaded
            if (not buildInfo) then
                steppedConnection:Disconnect()

                --Tell client that their plot has finished loading
                PlayerService:FireClient("PlotLoaded", self.Player, self.Object)

                --Disconnect failsafe
                failSafe:Disconnect()
                self.Loading = false

                return
            end

            local guid = buildInfo[1]
            local jsonData = buildInfo[2]

            --Construct a new BuildingObject
            local buildingObject = BuildingClass.newFromSave(pseudoPlayer, guid, jsonData)
            if (not buildingObject) then return end

            self:AddBuildingObject(buildingObject)

            currentIndex += 1
        end)
    end, function(err)
        warn(err)
    end)
end


--//Returns data at index guid
function Plot:GetBuildingObject(guid)
    return self.BuildingList[guid]
end


--//Adds buildingObject to buildingList and to BuildingStore
function Plot:AddBuildingObject(buildingObject)
    self.BuildingList[buildingObject.Guid] = buildingObject

    local currentIndex = self.DataContainer:Get("Placements")
    currentIndex[buildingObject.Guid] = buildingObject:Encode()
    self.DataContainer:Set("Placements", currentIndex)
end


--//Removes traces of buildingObject from buildingList and building store
function Plot:RemoveBuildingObject(buildingObject)
    self.BuildingList[buildingObject.Guid] = nil

    self.BuildingStore:Update(function(currentIndex)
        currentIndex[buildingObject.Guid] = nil

        return currentIndex
    end)

    for i=1, 10 do
        continue
    end
end


--//Pseudo-code for AddBuildingObject
function Plot:RefreshBuildingObject(...)
    return self:AddBuildingObject(...)
end


function Plot:DeserializeData(serialized)
    local decompressedData = CompressionApi:decompress(serialized)
    local buildingData = string.split(decompressedData, "|")
    serialized = {}

    --Iterate through all split strings, insert them into table
    for _, JSONData in pairs(buildingData) do
        serialized[HttpService:GenerateGUID(false)] = JSONData
    end

    return serialized
end


function Plot:SerializeData(deserialized)
    local str = ""

    --Iterate through all placements, combine JSONData
    for guid, jsonArray in pairs(deserialized) do
        if (str == "") then
            str = jsonArray
        else
            str = str .. "|" .. jsonArray
        end
    end

    return CompressionApi:compress(str)
end


--//Unloads and cleans up PlotOnject
function Plot:Unload()
    self._Maid:DoCleaning()

    LandStack:Push(self.Object)
end


function Plot:Start()
    LandStack = StackClass.new(Workspace.Land:GetChildren())

    -- Initiate land
    for _, landObject in pairs(Workspace.Land:GetChildren()) do
        for i = 1, #landObject.Plates:GetChildren() - 1 do
            local plate = landObject.Plates:FindFirstChild(tostring(i))
            local decor = landObject.Decor:FindFirstChild(tostring(i))

            plate.Grid.Transparency = 1
            plate.GridDash.Transparency = 1
            decor.Transparency = 1

            local adjacentPlatePosition = landObject.PrimaryPart.CFrame:ToObjectSpace(plate.CFrame)
            local adjacentDecorPosition = landObject.PrimaryPart.CFrame:ToObjectSpace(decor.CFrame)

            local plateCFrame = Instance.new("CFrameValue")
            plateCFrame.Name = "Origin"
            plateCFrame.Value = adjacentPlatePosition
            plateCFrame.Parent = plate

            local decorCFrame = Instance.new("CFrameValue")
            decorCFrame.Name = "Origin"
            decorCFrame.Value = adjacentDecorPosition
            decorCFrame.Parent = decor

            plate.Parent = landObject.Locked.Plates
            decor.Parent = landObject.Locked.Decor
        end
    end
end


function Plot:Init()
    --//Api
    CompressionApi = self.Shared.Api.CompressionApi
    DataApi = self.Modules.Data

    --//Services
    PlayerService = self.Services.PlayerService

    --//Classes
    BuildingClass = self.Modules.Classes.Building
    StackClass = self.Shared.Stack
    MaidClass = self.Shared.Maid

    --//Controllers

    --//Locals

end


return Plot