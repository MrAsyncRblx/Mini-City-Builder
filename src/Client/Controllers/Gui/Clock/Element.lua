local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)
local Clock = Roact.PureComponent:extend("Clock")

function Clock:render(hourRotation, minuteRotation)
	return Roact.createElement("Frame", {
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(92, 94, 94),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, -36),
		Size = UDim2.new(0.0753067806, 0, 0.168650225, 0),
	}, {
		Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
		}),
		Roact.createElement("Frame", {
            Name = "Hour",
            Rotation = hourRotation,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.899999976, 0, 0.899999976, 0),
			ZIndex = 2,
		}, {
			Roact.createElement("Frame", {
				Name = "Arrow",
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Selectable = true,
				Size = UDim2.new(0.0329999998, 0, 0.338888884, 0),
			})
		}),
		Roact.createElement("Frame", {
            Name = "Minute",
            Rotation = minuteRotation,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.899999976, 0, 0.899999976, 0),
			ZIndex = 2,
		}, {
			Roact.createElement("Frame", {
				Name = "Arrow",
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0.0329999998, 0, 0.449999988, 0),
			})
		}),
		Roact.createElement("UIAspectRatioConstraint", {
		})
	})
end

return Clock