-- Placement Controller
-- MrAsync
-- June 4, 2020



local PlacementController = {}

--//Api
local PlacementApi
local LogApi

--//Services
local PlacementService

--//Classes

--//Controllers
local NotificationController

--//Locals


function PlacementController:Start()
    LogApi:Log("Client | PlacementController | Start: Initializing")

    if (not PlacementApi.IsLoaded) then
        PlacementApi.Loaded:Wait()
    end

    PlacementApi.RoadsPlaced:Connect(function(...)
        local actionData = PlacementService:RequestRoadPlacement(...)
    end)

    PlacementApi.ObjectPlaced:Connect(function(...)
        local actionData = PlacementService:RequestPlacement(...)
    end)

    PlacementApi:StartPlacing(1)

    LogApi:Log("Client | PlacementController | Start: Completed")
end


function PlacementController:Init()
    --//Api
    PlacementApi = self.Modules.Api.PlacementApi
    LogApi = self.Shared.Api.LogApi

    --//Services
    PlacementService = self.Services.PlacementService

    --//Classes

    --//Controllers
    NotificationController = self.Controllers.NotificationController

    --//Locals

end


return PlacementController