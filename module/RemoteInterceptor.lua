local RemoteInterceptor = {
    HookedRemotes = {},
    BlacklistedRemotes = {}
}

-- Hook function implementation for different exploit environments
local hookFunction = hookfunction or replaceclosure or function(func, hook)
    local metatable = getrawmetatable(game)
    local oldNamecall = metatable.__namecall
    setreadonly(metatable, false)

    metatable.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == func then
            return hook(self, ...)
        end
        return oldNamecall(self, ...)
    end)

    setreadonly(metatable, true)
end

function RemoteInterceptor:IsRobloxEnvironment()
    return type(game) == "userdata" and type(game.GetService) == "function"
end

function RemoteInterceptor:Init(callback)
    if not self:IsRobloxEnvironment() then
        print("[RemoteInterceptor] Warning: Must be run within Roblox!")
        return
    end

    print("[RemoteInterceptor] Initializing remote interceptor...")
    self.Callback = callback
    self:HookRemotes()
    self:SetupAutoInterception()
end

function RemoteInterceptor:HookRemotes()
    print("[RemoteInterceptor] Setting up remote hooks...")

    -- Hook RemoteFunction
    local oldInvoke = Instance.new("RemoteFunction").InvokeServer
    hookFunction(oldInvoke, function(self, ...)
        if self.BlacklistedRemotes[self] then
            return oldInvoke(self, ...)
        end

        local args = {...}
        local callStart = os.clock()
        local success, returnValue = pcall(function()
            return oldInvoke(self, unpack(args))
        end)
        local callEnd = os.clock()

        if success then
            print(string.format("[RemoteInterceptor] Intercepted RemoteFunction call: %s (%.3fs)", self.Name, callEnd - callStart))
            if self.Callback then
                self.Callback(self, args, returnValue, {
                    duration = callEnd - callStart,
                    timestamp = os.time(),
                    type = "RemoteFunction",
                    path = self:GetFullName()
                })
            end
            return returnValue
        else
            warn("[RemoteInterceptor] Failed to intercept RemoteFunction:", returnValue)
            return oldInvoke(self, unpack(args))
        end
    end)

    -- Hook RemoteEvent
    local oldFireServer = Instance.new("RemoteEvent").FireServer
    hookFunction(oldFireServer, function(self, ...)
        if self.BlacklistedRemotes[self] then
            return oldFireServer(self, ...)
        end

        local args = {...}
        local callStart = os.clock()
        local success, returnValue = pcall(function()
            return oldFireServer(self, unpack(args))
        end)
        local callEnd = os.clock()

        if success then
            print(string.format("[RemoteInterceptor] Intercepted RemoteEvent call: %s (%.3fs)", self.Name, callEnd - callStart))
            if self.Callback then
                self.Callback(self, args, nil, {
                    duration = callEnd - callStart,
                    timestamp = os.time(),
                    type = "RemoteEvent",
                    path = self:GetFullName()
                })
            end
            return returnValue
        else
            warn("[RemoteInterceptor] Failed to intercept RemoteEvent:", returnValue)
            return oldFireServer(self, unpack(args))
        end
    end)

    print("[RemoteInterceptor] Remote hooks setup completed")
end

function RemoteInterceptor:SetupAutoInterception()
    -- Watch for new RemoteEvents and RemoteFunctions
    game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            print(string.format("[RemoteInterceptor] New remote detected: %s", descendant.Name))
            self.HookedRemotes[descendant] = true
        end
    end)

    -- Initial scan for existing remotes
    for _, instance in ipairs(game:GetDescendants()) do
        if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
            self.HookedRemotes[instance] = true
        end
    end
end

function RemoteInterceptor:BlockRemote(remote)
    self.BlacklistedRemotes[remote] = true
    print(string.format("[RemoteInterceptor] Blocked remote: %s", remote.Name))
end

function RemoteInterceptor:UnblockRemote(remote)
    self.BlacklistedRemotes[remote] = nil
    print(string.format("[RemoteInterceptor] Unblocked remote: %s", remote.Name))
end

function RemoteInterceptor:CreateSignal(remote)
    print(string.format("[RemoteInterceptor] Creating signal for remote: %s", remote.Name))
    local signal = {}
    local connections = {}

    function signal:Connect(callback)
        local connection = {
            Connected = true,
            Disconnect = function(self)
                self.Connected = false
                for i, conn in ipairs(connections) do
                    if conn == self then
                        table.remove(connections, i)
                        break
                    end
                end
            end
        }

        table.insert(connections, connection)
        return connection
    end

    return signal
end

function RemoteInterceptor:GetAllRemotes()
    local remotes = {}
    for remote, _ in pairs(self.HookedRemotes) do
        if remote and remote.Parent then
            table.insert(remotes, {
                Name = remote.Name,
                Type = remote.ClassName,
                Path = remote:GetFullName(),
                IsBlocked = self.BlacklistedRemotes[remote] or false
            })
        end
    end
    return remotes
end

return RemoteInterceptor
