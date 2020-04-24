-- Payment Service
-- MrAsync
-- April 23, 2020


--[[

    Handles the deposit of money to each player

]]


local PaymentService = {Client = {}}

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PlayerService

--//Controllers

--//Classes

--//Locals
local timeUntilNextPaycheck
local lastPayment = os.time()

local PAYMENT_INTERVAL = 30 --seconds


--TODO
--Verification of loaded data, unloading data etc
local function PayPlayer(player)
    local totalPaycheck = 0

    print(player.Name)

    return
end

function PaymentService:Start()   
    RunService.Stepped:Connect(function()
        timeUntilNextPaycheck.Value = PAYMENT_INTERVAL - (os.time() - lastPayment)

        if (timeUntilNextPaycheck.Value <= 0) then
            lastPayment = os.time()

            --Asynchronously pay each player
            for _, player in pairs(Players:GetChildren()) do
                coroutine.wrap(PayPlayer)(player)
            end
        end
    end)
end


function PaymentService:Init()
    --//Api

    --//Services

    --//Controllers

    --//Classes

    --//Locals
    timeUntilNextPaycheck = ReplicatedStorage:WaitForChild("TimeUntilNextPaycheck")
        
end


return PaymentService