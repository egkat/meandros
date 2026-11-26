local ReactRoblox = require(script.Parent.Packages.ReactRoblox)
local App = require(script.App)
local Config = require(script.Config)
local React = require(script.Parent.Packages.React)

if not plugin then
    warn(`[Meandros]: Plugin not found.`)
    return
end

Config.log("loading version", Config.version)

local container = Instance.new("Folder")
container.Name = Config.pluginName
container.Parent = game:GetService("CoreGui")

local root = ReactRoblox.createRoot(container)
root:render(React.createElement(App, { plugin = plugin }))

plugin.Unloading:Connect(function()
    Config.log("unloading")
    root:unmount()
    container:Destroy()
end)