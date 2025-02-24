local UIComponents = {}

-- Check if we're in Roblox environment
local function isRobloxEnvironment()
    return type(game) == "userdata" and type(game.GetService) == "function"
end

-- Mock services for non-Roblox environment
local mockServices = {
    TweenService = {
        Create = function(_, instance, info, props)
            -- Simple mock tween that instantly applies properties
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

local TweenService = getService("TweenService")

function UIComponents.CreateMainWindow()
    if not isRobloxEnvironment() then
        print("Warning: Running outside Roblox environment. UI will not be created.")
        return {
            Name = "MockScreenGui",
            Destroy = function() end
        }
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AdvancedSpy"
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Add rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame

    -- Add title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Text = "Advanced Spy"
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    -- Add close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -40, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 24
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar

    -- Make window draggable
    local Dragging = false
    local DragStart = nil
    local StartPos = nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if Dragging and
           (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale,
                StartPos.Y.Offset + Delta.Y
            )
        end
    end)

    -- Add content frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -40)
    ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    ScreenGui.Parent = getService("CoreGui")
    return ScreenGui
end

function UIComponents.CreateLogList()
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "LogList"
    ScrollingFrame.Size = UDim2.new(1, -20, 1, -60)
    ScrollingFrame.Position = UDim2.new(0, 10, 0, 50)
    ScrollingFrame.BackgroundTransparency = 0.9
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = ScrollingFrame
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    return ScrollingFrame
end

function UIComponents.AddLogEntry(logList, logEntry)
    local EntryFrame = Instance.new("Frame")
    EntryFrame.Size = UDim2.new(1, 0, 0, 60)
    EntryFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    EntryFrame.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = EntryFrame

    local RemoteName = Instance.new("TextLabel")
    RemoteName.Size = UDim2.new(1, -20, 0, 20)
    RemoteName.Position = UDim2.new(0, 10, 0, 5)
    RemoteName.BackgroundTransparency = 1
    RemoteName.TextColor3 = Color3.fromRGB(255, 255, 255)
    RemoteName.TextSize = 14
    RemoteName.Font = Enum.Font.GothamSemibold
    RemoteName.TextXAlignment = Enum.TextXAlignment.Left
    RemoteName.Text = logEntry.Remote.Name
    RemoteName.Parent = EntryFrame

    local ArgsText = Instance.new("TextLabel")
    ArgsText.Size = UDim2.new(1, -20, 0, 30)
    ArgsText.Position = UDim2.new(0, 10, 0, 25)
    ArgsText.BackgroundTransparency = 1
    ArgsText.TextColor3 = Color3.fromRGB(200, 200, 200)
    ArgsText.TextSize = 12
    ArgsText.Font = Enum.Font.Gotham
    ArgsText.TextXAlignment = Enum.TextXAlignment.Left
    ArgsText.Text = "Args: " .. UIComponents.SerializeArgs(logEntry.Args)
    ArgsText.Parent = EntryFrame

    EntryFrame.Parent = logList
    logList.CanvasSize = UDim2.new(0, 0, 0, #logList:GetChildren() * 65)
end

function UIComponents.SerializeArgs(args)
    local result = {}
    for i, arg in ipairs(args) do
        table.insert(result, tostring(arg))
    end
    return table.concat(result, ", ")
end

function UIComponents.CreateSearchBar()
    local SearchBar = Instance.new("TextBox")
    SearchBar.Size = UDim2.new(1, -20, 0, 30)
    SearchBar.Position = UDim2.new(0, 10, 0, 10)
    SearchBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    SearchBar.BorderSizePixel = 0
    SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBar.PlaceholderText = "Search remotes..."
    SearchBar.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    SearchBar.TextSize = 14
    SearchBar.Font = Enum.Font.Gotham
    SearchBar.ClearTextOnFocus = false

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = SearchBar

    return SearchBar
end

function UIComponents.CreateSettingsPanel()
    local Panel = Instance.new("Frame")
    Panel.Name = "SettingsPanel"
    Panel.Size = UDim2.new(0.3, 0, 1, 0)
    Panel.Position = UDim2.new(1, 0, 0, 0)
    Panel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Panel.BorderSizePixel = 0

    -- Add settings controls here

    return Panel
end

-- Add diagnostic functions
function UIComponents.LogUIEvent(eventType, details)
    print(string.format("[UIComponents] %s: %s", eventType, details))
end

function UIComponents.CreateMockLogEntry()
    if not isRobloxEnvironment() then
        local mockRemote = {
            Name = "TestRemote",
            IsA = function() return true end
        }
        local mockArgs = {
            "test_arg1",
            {key = "value"},
            123
        }
        UIComponents.AddLogEntry(nil, {
            Remote = mockRemote,
            Args = mockArgs,
            Timestamp = os.time(),
            Id = 1
        })
        UIComponents.LogUIEvent("MockEntry", "Created test log entry")
    end
end

function UIComponents.CreateRemoteManagementPanel()
    local Panel = Instance.new("Frame")
    Panel.Name = "RemoteManagementPanel"
    Panel.Size = UDim2.new(0.3, 0, 1, 0)
    Panel.Position = UDim2.new(0.7, 0, 0, 0)
    Panel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Panel.BorderSizePixel = 0

    -- Add title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.Text = "Remote Management"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Panel

    -- Add remote list
    local RemoteList = Instance.new("ScrollingFrame")
    RemoteList.Name = "RemoteList"
    RemoteList.Size = UDim2.new(1, -20, 1, -40)
    RemoteList.Position = UDim2.new(0, 10, 0, 35)
    RemoteList.BackgroundTransparency = 0.9
    RemoteList.BorderSizePixel = 0
    RemoteList.ScrollBarThickness = 4
    RemoteList.Parent = Panel

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = RemoteList
    UIListLayout.SortOrder = Enum.SortOrder.Name
    UIListLayout.Padding = UDim.new(0, 5)

    -- Function to update remote list
    function Panel:UpdateRemotes(remotes)
        -- Clear existing entries
        for _, child in ipairs(RemoteList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        -- Add new entries
        for _, remote in ipairs(remotes) do
            local Entry = Instance.new("Frame")
            Entry.Size = UDim2.new(1, 0, 0, 60)
            Entry.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Entry.BorderSizePixel = 0

            -- Add remote name
            local Name = Instance.new("TextLabel")
            Name.Size = UDim2.new(1, -100, 0, 20)
            Name.Position = UDim2.new(0, 10, 0, 5)
            Name.BackgroundTransparency = 1
            Name.Text = remote.Name
            Name.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name.TextXAlignment = Enum.TextXAlignment.Left
            Name.Parent = Entry

            -- Add remote type
            local Type = Instance.new("TextLabel")
            Type.Size = UDim2.new(1, -100, 0, 20)
            Type.Position = UDim2.new(0, 10, 0, 25)
            Type.BackgroundTransparency = 1
            Type.Text = remote.Type
            Type.TextColor3 = Color3.fromRGB(200, 200, 200)
            Type.TextXAlignment = Enum.TextXAlignment.Left
            Type.Parent = Entry

            -- Add block toggle button
            local BlockButton = Instance.new("TextButton")
            BlockButton.Size = UDim2.new(0, 80, 0, 25)
            BlockButton.Position = UDim2.new(1, -90, 0, 5)
            BlockButton.BackgroundColor3 = remote.IsBlocked and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113)
            BlockButton.Text = remote.IsBlocked and "Unblock" or "Block"
            BlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            BlockButton.Parent = Entry

            -- Add copy script button
            local ScriptButton = Instance.new("TextButton")
            ScriptButton.Size = UDim2.new(0, 80, 0, 25)
            ScriptButton.Position = UDim2.new(1, -90, 0, 35)
            ScriptButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            ScriptButton.Text = "Copy Script"
            ScriptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            ScriptButton.Parent = Entry

            Entry.Parent = RemoteList
        end

        -- Update canvas size
        RemoteList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    end

    return Panel
end

return UIComponents