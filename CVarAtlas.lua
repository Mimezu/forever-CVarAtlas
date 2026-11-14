-- CVar Atlas: snapshot every console command/CVar the client has registered.
-- Run /cvaratlas to capture; output lands in WTF\Account\<acct>\SavedVariables\CVarAtlas.lua
-- after /reload or logout. The previous capture is kept until you run it again.

local GetAllCommands = ConsoleGetAllCommands or (C_Console and C_Console.GetAllCommands)
local GetInfo = (C_CVar and C_CVar.GetCVarInfo) or GetCVarInfo

local CATEGORY = { [0]="Debug", "Graphics", "Console", "Combat", "Game", "Default", "Net", "Sound", "Gm", "Reveal", "None" }
local KIND = { [0]="cvar", "command", "macro", "script" }

local function Dump()
	if not GetAllCommands then
		print("|cffff6060CVarAtlas:|r no command-listing API in this client.")
		return
	end
	local entries, sortKeys, cvars = {}, {}, 0
	for _, info in ipairs(GetAllCommands()) do
		local e = {
			name = info.command,
			help = info.help ~= "" and info.help or nil,
			category = CATEGORY[info.category] or info.category,
			kind = KIND[info.commandType] or info.commandType,
		}
		if info.commandType == 0 and GetInfo then
			local ok, value, default, acct, char, locked, secure, readOnly = pcall(GetInfo, info.command)
			if ok and value ~= nil then
				e.value, e.default = value, default
				local flags = {}
				if acct then flags[#flags + 1] = "account" end
				if char then flags[#flags + 1] = "character" end
				if locked then flags[#flags + 1] = "locked" end
				if secure then flags[#flags + 1] = "secure" end
				if readOnly then flags[#flags + 1] = "readonly" end
				e.flags = #flags > 0 and table.concat(flags, ",") or nil
			else
				e.unreadable = true
			end
			cvars = cvars + 1
		end
		entries[#entries + 1] = e
		sortKeys[e] = e.name:lower()
	end
	table.sort(entries, function(a, b) return sortKeys[a] < sortKeys[b] end)
	CVarAtlasDB = {
		build = table.concat({ GetBuildInfo() }, " "),
		date = date("%Y-%m-%d %H:%M:%S"),
		entries = entries,
	}
	print(("|cff60c0ffCVarAtlas:|r captured %d entries (%d CVars). /reload to write the file."):format(#entries, cvars))
	if CVarAtlas_RefreshPanel then CVarAtlas_RefreshPanel() end
end

SLASH_CVARATLAS1 = "/cvaratlas"
SlashCmdList.CVARATLAS = Dump

-- Page in Esc > Options > AddOns: Dump button, slash hint, last capture.
local function RegisterInSettings()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local panel = CreateFrame("Frame")
	local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	heading:SetPoint("TOPLEFT", 16, -16)
	heading:SetText("CVar Atlas")
	local dump = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	dump:SetSize(140, 26)
	dump:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -14)
	dump:SetText("Dump")
	dump:SetScript("OnClick", Dump)
	local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	hint:SetPoint("LEFT", dump, "RIGHT", 12, 0)
	hint:SetText("/cvaratlas")
	local last = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	last:SetPoint("TOPLEFT", dump, "BOTTOMLEFT", 0, -12)
	local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -6)
	note:SetText("Saved on /reload or logout.")
	function CVarAtlas_RefreshPanel()
		local db = CVarAtlasDB
		if db and db.entries then
			last:SetFormattedText("Last: %s · %d entries", db.date or "?", #db.entries)
		else
			last:SetText("No capture yet")
		end
	end
	panel:SetScript("OnShow", CVarAtlas_RefreshPanel)
	local category = Settings.RegisterCanvasLayoutCategory(panel, "CVar Atlas")
	Settings.RegisterAddOnCategory(category)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	pcall(RegisterInSettings)
end)
