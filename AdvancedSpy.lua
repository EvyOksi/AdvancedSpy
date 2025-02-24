--[[
    AdvancedSpy
    A mobile-friendly enhanced remote spy for Roblox games.
    Author: Assistant
    Version: 1.0.0
]]
local AdvancedSpy = {
    Version = "1.0.0",
    Enabled = false,
    Connections = {},
    RemoteLog = {},
    BlockedRemotes = {},
    ExcludedRemotes = {},
    Settings = {
        Theme = "dark",
        MaxLogs = 1000,
        AutoBlock = false,
        LogReturnValues = true,
        Debug = true
    }
}

-- Debug logging function
local function debugLog(module, message)
    if AdvancedSpy.Settings.Debug then
        print(string.format("[AdvancedSpy Debug] [%s] %s", module, message))
    end
end

-- Load modules
local UIComponents = require("modules.UIComponents")
local RemoteInterceptor = require("modules.RemoteInterceptor")
local ScriptGenerator = require("modules.ScriptGenerator")
local Theme = require("modules.Theme")
local TouchControls = require("modules.TouchControls")
local NetworkVisualizer = require("modules.NetworkVisualizer")

-- Core UI Elements
local GUI = {
    Main = nil,
    LogList = nil,
    SearchBar = nil,
    SettingsPanel = nil,
    RemotePanel = nil  -- Remote management panel
}

function AdvancedSpy:Init()
    if not game then
        warn("AdvancedSpy must be run within Roblox!")
        return
    end

    debugLog("Init", "Initializing AdvancedSpy v" .. self.Version)

    -- Create main UI components
    GUI.Main = UIComponents.CreateMainWindow()
    GUI.LogList = UIComponents.CreateLogList()
    GUI.SearchBar = UIComponents.CreateSearchBar()
    GUI.SettingsPanel = UIComponents.CreateSettingsPanel()
    GUI.RemotePanel = UIComponents.CreateRemoteManagementPanel()
    GUI.RemotePanel.Parent = GUI.Main.MainFrame.ContentFrame

    -- Initialize touch controls for mobile
    debugLog("TouchControls", "Initializing touch controls...")
    TouchControls:Init(GUI.Main)

    -- Setup remote interceptors
    debugLog("RemoteInterceptor", "Setting up remote interceptors...")
    RemoteInterceptor:Init(function(remote, args, returnValue, stats)
        self:HandleRemoteCall(remote, args, returnValue, stats)
    end)

    -- Apply initial theme
    debugLog("Theme", "Applying initial theme: " .. self.Settings.Theme)
    Theme:Apply(self.Settings.Theme)

    -- Setup search functionality
    GUI.SearchBar.Changed:Connect(function(text)
        self:FilterLogs(text)
    end)

    -- Setup periodic remote list updates
    self:UpdateRemoteList()
    task.spawn(function()
        while self.Enabled do
            task.wait(5)  -- Update every 5 seconds
            if self.Enabled then  -- Check again to prevent update after destruction
                self:UpdateRemoteList()
            end
        end
    end)

    self.Enabled = true
    debugLog("Init", "AdvancedSpy initialized successfully")
end

function AdvancedSpy:HandleRemoteCall(remote, args, returnValue, stats)
    if not self.Enabled then return end
    debugLog("RemoteCall", string.format("Handling remote call: %s", remote.Name))

    if self:IsExcluded(remote) then 
        debugLog("RemoteCall", "Remote is excluded, ignoring...")
        return 
    end

    if self:IsBlocked(remote) then 
        debugLog("RemoteCall", "Remote is blocked, ignoring...")
        return 
    end

    local logEntry = {
        Remote = remote,
        Args = args,
        ReturnValue = returnValue,
        Timestamp = os.time(),
        Stack = debug.traceback(),
        Id = #self.RemoteLog + 1,
        NetworkStats = stats  -- Detailed network statistics from interception
    }

    table.insert(self.RemoteLog, 1, logEntry)
    debugLog("RemoteCall", string.format("Added log entry #%d", logEntry.Id))
    self:TrimLogs()
    self:UpdateLogDisplay(logEntry)
end

function AdvancedSpy:FilterLogs(searchText)
    if not searchText then return end
    searchText = searchText:lower()
    for _, entry in ipairs(self.RemoteLog) do
        local visible = entry.Remote.Name:lower():find(searchText) ~= nil
        local logElement = GUI.LogList:FindFirstChild("Log_" .. entry.Id)
        if logElement then
            logElement.Visible = visible
        end
    end
end

function AdvancedSpy:UpdateLogDisplay(logEntry)
    if not self.Enabled or not logEntry then return end
    debugLog("UI", string.format("Updating display for log entry #%d", logEntry.Id))
    UIComponents.AddLogEntry(GUI.LogList, logEntry)
end

function AdvancedSpy:TrimLogs()
    while #self.RemoteLog > self.Settings.MaxLogs do
        table.remove(self.RemoteLog)
    end
    debugLog("Logs", string.format("Trimmed logs to %d entries", #self.RemoteLog))
end

-- API Functions
function AdvancedSpy:BlockRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Blocking remote: %s", remote.Name))
    self.BlockedRemotes[remote] = true
    RemoteInterceptor:BlockRemote(remote)
end

function AdvancedSpy:UnblockRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Unblocking remote: %s", remote.Name))
    self.BlockedRemotes[remote] = nil
    RemoteInterceptor:UnblockRemote(remote)
end

function AdvancedSpy:ExcludeRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Excluding remote: %s", remote.Name))
    self.ExcludedRemotes[remote] = true
end

function AdvancedSpy:IncludeRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Including remote: %s", remote.Name))
    self.ExcludedRemotes[remote] = nil
end

function AdvancedSpy:GetRemoteFiredSignal(remote)
    if not remote then return end
    debugLog("API", string.format("Creating signal for remote: %s", remote.Name))
    return RemoteInterceptor:CreateSignal(remote)
end

function AdvancedSpy:UpdateRemoteList()
    if not self.Enabled then return end
    local remotes = RemoteInterceptor:GetAllRemotes()
    GUI.RemotePanel:UpdateRemotes(remotes)
    debugLog("RemoteList", string.format("Updated remote list (%d remotes)", #remotes))
end

function AdvancedSpy:IsBlocked(remote)
    return remote and self.BlockedRemotes[remote] ~= nil
end

function AdvancedSpy:IsExcluded(remote)
    return remote and self.ExcludedRemotes[remote] ~= nil
end

function AdvancedSpy:Destroy()
    debugLog("Cleanup", "Destroying AdvancedSpy...")
    self.Enabled = false
    for _, connection in pairs(self.Connections) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then
            connection:Disconnect()
        end
    end
    if GUI.Main and typeof(GUI.Main) == "Instance" then
        GUI.Main:Destroy()
    end
    table.clear(self.RemoteLog)
    table.clear(self.BlockedRemotes)
    table.clear(self.ExcludedRemotes)
    debugLog("Cleanup", "AdvancedSpy destroyed successfully")
end

-- Return the module initialization function
return function()
    AdvancedSpy:Init()
    return AdvancedSpy
end
