local TouchControls = {}

-- Check if we're in Roblox environment
local function isRobloxEnvironment()
    return type(game) == "userdata" and type(game.GetService) == "function"
end

-- Mock services for non-Roblox environment
local mockServices = {
    UserInputService = {
        TouchEnabled = false,
        TouchStarted = {
            Connect = function() end
        },
        TouchMoved = {
            Connect = function() end
        },
        TouchEnded = {
            Connect = function() end
        }
    },
    TweenService = {
        Create = function(_, instance, info, props)
            for prop, value in pairs(props) do
                instance[prop] = value
            end
            return {
                Play = function() end
            }
        end
    }
}

-- Get service (real or mock)
local function getService(serviceName)
    if isRobloxEnvironment() then
        return game:GetService(serviceName)
    else
        return mockServices[serviceName]
    end
end

local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")

function TouchControls:Init(gui)
    if not isRobloxEnvironment() then
        print("Warning: Running outside Roblox environment. Touch controls will not be initialized.")
        return
    end

    if not UserInputService.TouchEnabled then return end

    self.GUI = gui
    self:SetupTouchControls()
end

function TouchControls:SetupTouchControls()
    local mainFrame = self.GUI:WaitForChild("MainFrame")
    
    -- Add touch gesture support
    local touchStartPos = nil
    local frameStartPos = nil
    local isDragging = false
    
    -- Setup swipe to close/open
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStartPos = input.Position
            frameStartPos = mainFrame.Position
            isDragging = true
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - touchStartPos
            
            -- Calculate new position
            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y
            
            -- Update position
            mainFrame.Position = UDim2.new(
                frameStartPos.X.Scale,
                newX,
                frameStartPos.Y.Scale,
                newY
            )
        end
    end)
    
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            
            -- Check if should snap to edge
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local frameSize = mainFrame.AbsoluteSize
            local framePos = mainFrame.AbsolutePosition
            
            local snapPosition = UDim2.new(
                frameStartPos.X.Scale,
                framePos.X < viewportSize.X / 2 and 0 or viewportSize.X - frameSize.X,
                frameStartPos.Y.Scale,
                framePos.Y
            )
            
            -- Animate to snap position
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(mainFrame, tweenInfo, {
                Position = snapPosition
            })
            tween:Play()
        end
    end)
    
    -- Add pinch to resize
    local touches = {}
    local initialDistance = nil
    local initialSize = nil
    
    UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
        if #touches < 2 then
            table.insert(touches, touch)
            
            if #touches == 2 then
                initialDistance = (touches[1].Position - touches[2].Position).magnitude
                initialSize = mainFrame.Size
            end
        end
    end)
    
    UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
        if #touches == 2 then
            local currentDistance = (touches[1].Position - touches[2].Position).magnitude
            local scale = currentDistance / initialDistance
            
            -- Update frame size
            local newSize = UDim2.new(
                initialSize.X.Scale * scale,
                initialSize.X.Offset,
                initialSize.Y.Scale * scale,
                initialSize.Y.Offset
            )
            
            -- Clamp size
            local minSize = UDim2.new(0.3, 0, 0.3, 0)
            local maxSize = UDim2.new(0.9, 0, 0.9, 0)
            
            newSize = UDim2.new(
                math.clamp(newSize.X.Scale, minSize.X.Scale, maxSize.X.Scale),
                0,
                math.clamp(newSize.Y.Scale, minSize.Y.Scale, maxSize.Y.Scale),
                0
            )
            
            mainFrame.Size = newSize
        end
    end)
    
    UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
        for i, t in ipairs(touches) do
            if t == touch then
                table.remove(touches, i)
                break
            end
        end
    end)
    
    -- Add double tap to maximize/restore
    local lastTap = 0
    local originalSize = nil
    local originalPosition = nil
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local currentTime = tick()
            
            if currentTime - lastTap < 0.4 then
                -- Double tap detected
                if not originalSize then
                    -- Maximize
                    originalSize = mainFrame.Size
                    originalPosition = mainFrame.Position
                    
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(mainFrame, tweenInfo, {
                        Size = UDim2.new(0.9, 0, 0.9, 0),
                        Position = UDim2.new(0.05, 0, 0.05, 0)
                    })
                    tween:Play()
                else
                    -- Restore
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(mainFrame, tweenInfo, {
                        Size = originalSize,
                        Position = originalPosition
                    })
                    tween:Play()
                    
                    originalSize = nil
                    originalPosition = nil
                end
            end
            
            lastTap = currentTime
        end
    end)
end

return TouchControls
