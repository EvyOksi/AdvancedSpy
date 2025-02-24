local NetworkVisualizer = {}

-- Mock visualization data for non-Roblox environment
local mockData = {
    calls = {},
    totalBytes = 0,
    startTime = os.time()
}

function NetworkVisualizer:Init()
    self.data = mockData
    self.isRoblox = type(game) == "userdata"
    print("[NetworkVisualizer] Initialized" .. (self.isRoblox and " in Roblox" or " in test environment"))
end

function NetworkVisualizer:TrackRemoteCall(remote, args, returnValue)
    local callData = {
        timestamp = os.time(),
        remote = remote.Name,
        argSize = self:EstimateSize(args),
        returnSize = self:EstimateSize(returnValue),
        duration = 0.05 -- Mock duration
    }
    
    table.insert(self.data.calls, 1, callData)
    self.data.totalBytes = self.data.totalBytes + callData.argSize + callData.returnSize
    
    -- Keep only last 100 calls
    if #self.data.calls > 100 then
        table.remove(self.data.calls)
    end
    
    return callData
end

function NetworkVisualizer:EstimateSize(value)
    if type(value) == "string" then
        return #value
    elseif type(value) == "table" then
        local size = 0
        for k, v in pairs(value) do
            size = size + self:EstimateSize(k) + self:EstimateSize(v)
        end
        return size
    end
    return 8 -- Default size for numbers, booleans, etc.
end

function NetworkVisualizer:GetStatistics()
    local now = os.time()
    local duration = now - self.data.startTime
    
    return {
        totalCalls = #self.data.calls,
        totalBytes = self.data.totalBytes,
        callsPerMinute = duration > 0 and (#self.data.calls / (duration / 60)) or 0,
        bytesPerSecond = duration > 0 and (self.data.totalBytes / duration) or 0
    }
end

function NetworkVisualizer:GenerateReport()
    local stats = self:GetStatistics()
    local report = string.format([[
Network Statistics:
------------------
Total Calls: %d
Total Data: %.2f KB
Calls/Minute: %.1f
Bandwidth: %.2f KB/s
]], 
        stats.totalCalls,
        stats.totalBytes / 1024,
        stats.callsPerMinute,
        stats.bytesPerSecond / 1024
    )
    
    return report
end

return NetworkVisualizer
