-- Works out whether this is a dev or release build.
-- dev.project.json adds a BoolValue called DEV_BUILD to the root folder;
-- plugin.project.json (release) doesn't. Same idea as Rojo's ROJO_DEV_BUILD.
--
-- script        = Config
-- script.Parent = Plugin (the Script made from src/init.server.luau)
-- .Parent again = the root folder, where Version and DEV_BUILD live

local Constants = require(script.Parent.Data.Constants)
local Strict = require(script.Parent.Utils.Strict)

local root = script.Parent.Parent

local Version = root.Version
local trimmedVersion = Version.Value:gsub("^%s+", ""):gsub("%s+$", "")

local isDevMode = root:FindFirstChild("DEV_BUILD") ~= nil

local Config = {
	version = trimmedVersion,
	isDevMode = isDevMode,

	-- Different names/ids so the dev and release builds can be installed side by side
	pluginName = if isDevMode then `{Constants.PLUGIN_NAME} (DEV)` else Constants.PLUGIN_NAME,
	widgetId = if isDevMode then `{Constants.WIDGET_ID}_Dev` else Constants.WIDGET_ID,

	-- Dev builds save settings under different keys, so testing never touches real settings
	settingsPrefix = if isDevMode then "MeandrosDev_" else "Meandros_",
}

-- Prints only in dev builds, so debug output never ships to users
function Config.log(...: any)
	if isDevMode then
		print(`[{Config.pluginName}]`, ...)
	end
end

return Strict("Config", Config)
