-- Placement Api
-- MrAsync
-- March 24, 2020


--[[

    Interface for controlling the players ability to place objects, edit objects

    Events:
        ObjectPlaced => itemId, LocalSpace position
        ObjectMoved => itemId, LocalSpace newPosition, LocalSpace oldPosition
        PlacementCancelled => itemId

        PlacementSelectionStarted => Object
        PlacementSelectionEnded => Object

    Methods:
        public void StartPlacing(int ItemId OR Model PlacementModel)
        public void StopPlacing(Boolean MoveToOriginalCFrame)

        private Object hitPart, CFrame hitPosition, NormalId hitSurface CastRay()
        private void ShowGrid()
        private void HideGrid()
        private int Round(int num)
        private void ActivateCollisions()
        private void DeactivateCollisions()
        private void RotateObject(String actionName, Enum inputState, InputObject inputObject)
        private void PlaceObject(String actionName, Enum inputState, InputObject inputObject)
        private void ChangeInputType(int preferredTye)

        private void CheckHover()
        private void CheckSelection()
        private void UpdatePlacement()

]]



local PlacementApi = {}
local self = PlacementApi

--//Api
local UserInput
local Platform

--//Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local PlayerService

--//Controllers

--//Classes
local Maid

--//Locals
local camera
local character
local plotObject

local itemId
local plotSize
local isMoving
local dummyPart
local plotCFrame
local itemObject
local isColliding
local currentMaid
local itemRotation
local localPosition
local worldPosition
local selectedObject
local preferredInput
local inputController
local initialWorldPosition
local initialLocalPosition
local placementSelectionBox

local GRID_SIZE = 2
local BUILD_HEIGHT = 1024
local DAMPENING_SPEED = 0.2
local UP = Vector3.new(0, 1, 0)
local BACK = Vector3.new(0, 0, 1)
local SELECTION_BOX_THICKNESS = 0.05
local MAX_INTERACTION_DISTANCE = 30
local COLLISION_COLOR = Color3.fromRGB(231, 76, 60)
local NO_COLLISION_COLOR = Color3.fromRGB(46, 204, 113)

--Controls
local PC_ROTATE_BIND = Enum.KeyCode.R
local PC_STOP_BIND = Enum.KeyCode.X

local CONSOLE_PLACE_BIND = Enum.KeyCode.ButtonR2
local CONSOLE_ROTATE_BIND = Enum.KeyCode.ButtonR1
local CONSOLE_ROTATE_ALT_BIND = Enum.KeyCode.ButtonL1
local CONSOLE_STOP_BIND = Enum.KeyCode.ButtonB


--[[
    PRIVATE METHODS
]]


--//Cast a ray from the mouseOrigin to the mouseTarget
local function CastRay(ignoreList, mobileTouchPositions)
    local mousePos = ((mobileTouchPositions or {})[1] or UserInputService:GetMouseLocation())
    local mouseUnitRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y - 30)
    local mouseRay = Ray.new(mouseUnitRay.Origin, (mouseUnitRay.Direction * 100))

    return workspace:FindPartOnRayWithIgnoreList(mouseRay, ignoreList)
end


--//Smoothly shows the PlotObject's grid pattern
local function ShowGrid()
    plotObject.Main.Grid.Transparency = 0
    plotObject.Main.GridDash.Transparency = 0
end


--//Smoothly hides the plotObject's grid pattern
local function HideGrid()
    plotObject.Main.Grid.Transparency = 1
    plotObject.Main.GridDash.Transparency = 1
end


--//Rounds a number up or down
local function RoundNumber(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end


--//Checks to see if model is touching another model
local function CheckCollision()
    local touchingParts = dummyPart:GetTouchingParts()

    --Iterate through touching parts
    for _, part in pairs(touchingParts) do
        local model = part:FindFirstAncestorOfClass("Model")

        --If part IsDescendantOf a placed object, return true
        if (model and model:IsDescendantOf(plotObject.Placements) and (model.PrimaryPart == part)) then
            return true
        end
    end

    return false
end


--//Disables Collisions for all parts in itemObject
local function deactivateCollisions()
    for _, part in pairs(itemObject.Decor:GetChildren()) do
        part.CanCollide = false
    end

    if (itemObject:FindFirstChild("Base")) then
        itemObject.Base.CanCollide = false
    end

    dummyPart.CanCollide = false
end


--//Enables Collisions for all parts in itemObject
local function activateCollisions()
    for _, part in pairs(itemObject.Decor:GetChildren()) do
        part.CanCollide = true
    end

    if (itemObject:FindFirstChild("Base")) then
        itemObject.Base.CanCollide = true
    end
end


--//Rotates the object according to input
local function RotateObject(keyCode)
    if (keyCode == PC_ROTATE_BIND or keyCode == CONSOLE_ROTATE_BIND) then
        itemRotation = itemRotation - (math.pi / 2)
    else
        itemRotation = itemRotation + (math.pi / 2)
    end
end


--//Fires the ObjectPlaced signal
local function PlaceObject()
    if (not CheckCollision()) then
        --Fire proper event according to operation
        if (isMoving) then
            self.Events.ObjectMoved:Fire(itemObject.Name, localPosition, initialLocalPosition)
        else
            self.Events.ObjectPlaced:Fire(itemId, localPosition)
        end
    end
end


--//Calculates the proper CFrame and Size for the canvas
--//Taking into consideration the rotation of the model
local function CalcCanvas()
	local canvasSize = plotObject.Main.Size

	-- want to create CFrame such that cf.lookVector == self.CanvasPart.CFrame.upVector
	-- do this by using object space and build the CFrame
	local back = Vector3.new(0, -1, 0)
	local top = Vector3.new(0, 0, -1)
	local right = Vector3.new(-1, 0, 0)

	-- convert to world space
	local cf = plotObject.Main.CFrame * CFrame.fromMatrix(-back*canvasSize/2, right, top, back)
	-- use object space vectors to find the width and height
	local size = Vector2.new((canvasSize * right).magnitude, (canvasSize * top).magnitude)

	return cf, size
end


--//Bound to Click, Tap, Trigger
--//Checks if player is hovering over a placed object
local function CheckSelection(mobileTouchPositions)
    if (itemObject) then return end

    local rayPart, hitPosition, normal = CastRay({character}, mobileTouchPositions)

    --Fire StartedSignal if rayPart is being selected for the first time,
    --Fire EndedSignal if rayPart is not longer selected
    if (rayPart and rayPart:IsDescendantOf(plotObject.Placements) and (rayPart.Position - character.PrimaryPart.Position).magnitude <= MAX_INTERACTION_DISTANCE) then
        selectedObject = rayPart:FindFirstAncestorOfClass("Model")
            
        self.Events.PlacementSelectionStarted:Fire(selectedObject)
    else
        if (selectedObject) then
            selectedObject = nil

            self.Events.PlacementSelectionEnded:Fire()
        end
    end
end


--//Bound to RenderStepped
--//Adornee a selection box to placementObjects currently being hovered
local function CheckHover()
    local rayPart = CastRay({character})

    if (rayPart) then
        local parentModel = rayPart:FindFirstAncestorOfClass("Model")

        if (parentModel and parentModel:IsDescendantOf(plotObject.Placements) and (rayPart.Position - character.PrimaryPart.Position).magnitude <= MAX_INTERACTION_DISTANCE) then
            placementSelectionBox.Adornee = parentModel.PrimaryPart
        else
            placementSelectionBox.Adornee = nil
        end
    else
        placementSelectionBox.Adornee = nil
    end
end


--//Changes core keybinds to accomadate new input type
local function ChangeInputType(newPreferredType)
    if (newPreferredType == UserInput.Preferred.Gamepad) then
        local gamePad = UserInput:Get("Gamepad").new(Enum.UserInputType.Gamepad1)

        --When trigger is triggered, check selection
        gamePad.ButtonDown:Connect(function(keyCode)
            if (keyCode == CONSOLE_PLACE_BIND) then
                CheckSelection()
            end
        end)
    elseif (newPreferredType == UserInput.Preferred.Mobile) then
        local mobile = UserInput:Get("Mobile")

        --When player taps screen, check selection
        mobile.TouchTapInWorld:Connect(function(touchPositions)
            CheckSelection(touchPositions)
        end)
    else
        local mouse = UserInput:Get("Mouse")

        --When a player clicks mouse, check selections
        mouse.LeftDown:Connect(function()
            CheckSelection()
        end)
    end
end


--//Bound to RenderStep
--//Moves model to position of mouse
--//Big maths
local function UpdatePlacement(isInitialUpdate)
    local _, hitPosition = CastRay({character, itemObject, dummyPart})

    --Calculate model size according to current itemRotation
	local modelSize = CFrame.fromEulerAnglesYXZ(0, itemRotation, 0) * itemObject.PrimaryPart.Size
    modelSize = Vector3.new(math.abs(RoundNumber(modelSize.x)), math.abs(RoundNumber(modelSize.y)), math.abs(RoundNumber(modelSize.z)))

	--Get model size and position relative to the plot
	local lpos = plotCFrame:pointToObjectSpace(hitPosition);
	local size2 = (plotSize - Vector2.new(modelSize.x, modelSize.z))/2

	--Constrain model withing the bounds of the plot
	local x = math.clamp(lpos.x, -size2.x, size2.x);
    local y = math.clamp(lpos.y, -size2.y, size2.y);

    --Align model GRID_SIZE
	x = math.sign(x)*((math.abs(x) - math.abs(x) % GRID_SIZE) + (size2.x % GRID_SIZE))
	y = math.sign(y)*((math.abs(y) - math.abs(y) % GRID_SIZE) + (size2.y % GRID_SIZE))

    --Calculate the worldSpace and ObjectSpace CFrame
    worldPosition = plotCFrame * CFrame.new(x, y, -modelSize.y/2) * CFrame.Angles(-math.pi/2, itemRotation, 0)
    localPosition = plotObject.Main.CFrame:ToObjectSpace(worldPosition)

    --Set the position of the object
    dummyPart.CFrame = worldPosition

    --Immedietely snap itemObject to proper position
    if (isInitialUpdate == true) then
        itemObject:SetPrimaryPartCFrame(worldPosition)
    else
        itemObject:SetPrimaryPartCFrame(itemObject.PrimaryPart.CFrame:Lerp(worldPosition, DAMPENING_SPEED))
    end    
    

    --Check collision
    isColliding = CheckCollision()

    --Color bounding box according to collision state
    if (isColliding) then
        itemObject.PrimaryPart.Color = COLLISION_COLOR
    else
        itemObject.PrimaryPart.Color = NO_COLLISION_COLOR
    end
end

--[[
    PUBLIC METHODS
]]

--//Starts the placing process
--//Clones the model
--//Binds function to renderStepped
function PlacementApi:StartPlacing(id)
    self:StopPlacing()

    --Show grid
    ShowGrid()

    --If placementObject is a valid arg, player is moving object
    if (type(id) == "userdata") then
        isMoving = true

        itemObject = id
        itemObject.Parent = camera
        initialWorldPosition = itemObject.PrimaryPart.CFrame
        initialLocalPosition = plotObject.Main.CFrame:ToObjectSpace(initialWorldPosition)
    else
        --Clone model into current camera
        --IMPLEMENT LEVEL SELECTION
        itemObject = ReplicatedStorage.Items.Buildings:FindFirstChild(id .. ":1"):Clone()
        itemObject.Parent = camera
        itemId = id
    end

    --Create dummy part,used for checking collisions
    dummyPart = itemObject.PrimaryPart:Clone()
    dummyPart.Parent = camera
    dummyPart.Touched:Connect(function() end)

    --Show bounding box, set position to plot
    itemObject.PrimaryPart.Transparency = 0.5

    --Setup rotation
    itemRotation = math.pi / 2

    --Disable collisions
    deactivateCollisions()

    --Keybind Setup (playform dependent)
    preferredInput = UserInput:GetPreferred()
    if (preferredInput == UserInput.Preferred.Gamepad) then
        local gamePad = UserInput:Get("Gamepad").new(Enum.UserInputType.Gamepad1)

        currentMaid:GiveTask(gamePad.ButtonDown:Connect(function(keyCode)
            if (keyCode == CONSOLE_PLACE_BIND) then
                PlaceObject()
                
            elseif (keyCode == CONSOLE_ROTATE_BIND or keyCode == CONSOLE_ROTATE_ALT_BIND) then
                RotateObject(keyCode)

            elseif (keyCode == CONSOLE_STOP_BIND) then
                self.StopPlacing()
            end
        end))
    elseif (preferredInput == UserInput.Preferred.Mobile) then
        local mobile  = UserInput:Get("Mobile")

        --To be implemented later
    else
        local mouse = UserInput:Get("Mouse")
        local keyboard = UserInput:Get("Keyboard")

        currentMaid:GiveTask(mouse.LeftDown:Connect(function()
            PlaceObject()
        end))

        currentMaid:GiveTask(keyboard.KeyDown:Connect(function(keyCode)
            if (keyCode == PC_ROTATE_BIND) then
                RotateObject(keyCode)
            elseif (keyCode == PC_STOP_BIND) then
                self.StopPlacing()
            end
        end))
    end
    
    --Initially snap itemObject to proper position
    UpdatePlacement(true)
    RunService:BindToRenderStep("UpdatePlacement", 1, UpdatePlacement)
end


--//Stops placing object
--//Cleans up client
function PlacementApi:StopPlacing(moveToOriginalCFrame)
    --Hide grid
    HideGrid()

    --Special cleanup for moving objects
    if (isMoving) then
        if (itemObject) then
            itemObject.Parent = plotObject.Placements
            itemObject.PrimaryPart.Transparency = 1
            activateCollisions()

            --If player cancelled or server errored, return placement to original position
            if (moveToOriginalCFrame) then
                itemObject:SetPrimaryPartCFrame(initialWorldPosition)
            end
        end
    else
        if (itemObject) then itemObject:Destroy() end
    end

    --Destroy dummyPart
    if (dummyPart) then dummyPart:Destroy() end

    --Reset locals
    initialWorldPosition = nil
    initialLocalPosition = nil
    localPosition = nil
    worldPosition = nil
    isColliding = false
    isMoving = false
    itemId = 0

    itemObject = nil

    --Cleanup grid
    plotObject.Main.Grid.Transparency = 1
    plotObject.Main.GridDash.Transparency = 1

    --Unbind actions
    currentMaid:DoCleaning()

    RunService:UnbindFromRenderStep("UpdatePlacement")
end


function PlacementApi:Start()
    currentMaid = Maid.new()

    plotObject = self.Player:WaitForChild("PlotObject").Value

    --Setup plot locals
    plotCFrame, plotSize = CalcCanvas()

    --Initially grab character, and grab character when player resets
    character = (self.Player.Character or self.Player.CharacterAdded:Wait())
    self.Player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
    end)
      
    --When player clicks, check if they are selection a previously placed object
    RunService:BindToRenderStep("HoverSelectionQueue", 2, CheckHover)

    --Handle selectionQueue
    ChangeInputType(UserInput:GetPreferred())
    UserInput.PreferredChanged:Connect(function(newPreferred)
        ChangeInputType(newPreferred)
    end)
end


function PlacementApi:Init()
    --//Api
    UserInput = self.Controllers.UserInput
    Platform = self.Shared.Platform
    
    --//Services
    PlayerService = self.Services.PlayerService
    
    --//Controllers
    
    --//Classes
    Maid = self.Shared.Maid
    
    --//Locals
    camera = workspace.CurrentCamera
    placementSelectionBox = Instance.new("SelectionBox")
    placementSelectionBox.Parent = camera
    placementSelectionBox.LineThickness = SELECTION_BOX_THICKNESS

    --Register signals
    self.Events = {}
    self.Events.PlacementSelectionStarted = Instance.new("BindableEvent")
    self.Events.PlacementSelectionEnded = Instance.new("BindableEvent")
    self.Events.PlacementCancelled = Instance.new("BindableEvent")
    self.Events.ObjectPlaced = Instance.new("BindableEvent")
    self.Events.ObjectMoved = Instance.new("BindableEvent")

    self.ObjectMoved = self.Events.ObjectMoved.Event
    self.ObjectPlaced = self.Events.ObjectPlaced.Event
    self.PlacementCancelled = self.Events.PlacementCancelled.Event
    self.PlacementSelectionEnded = self.Events.PlacementSelectionEnded.Event
    self.PlacementSelectionStarted = self.Events.PlacementSelectionStarted.Event
end

return PlacementApi