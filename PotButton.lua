local PotButton_EventFrame, events = CreateFrame("FRAME"), {}
PotButton_ChangeInitiated = false
local PotButton_Timer = 0
local PotButton_TimerInterval = .1
local PotButton_AddonIsLoaded = false
local PotButton_MacrosAreLoaded = false
local PotButton_EnteredWorld = false
--------------------------------------------------------------------
function events:ADDON_LOADED(...)
	local addonName = ...
	if addonName == "PotButton" then
		PotButton_AddonIsLoaded = true
		PotButton_Init()
		PotButton_EventFrame:UnregisterEvent("ADDON_LOADED")
	end
end
--------------------------------------------------------------------
function events:UPDATE_MACROS(...)
	PotButton_MacrosAreLoaded = true
	PotButton_Init()
	PotButton_EventFrame:UnregisterEvent("UPDATE_MACROS")
end
--------------------------------------------------------------------
function events:PLAYER_ENTERING_WORLD(...)
	PotButton_EnteredWorld = true
	PotButton_Init()
	PotButton_EventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
--------------------------------------------------------------------
function events:BAG_UPDATE(...)
	PotButton_ChangeInitiated = true
end
--------------------------------------------------------------------
function events:UNIT_INVENTORY_CHANGED(unit)
	if unit == "player" then
	PotButton_ChangeInitiated = true
	end
end
--------------------------------------------------------------------
PotButton_EventFrame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...)
end)
--------------------------------------------------------------------
for i, v in pairs(events) do
	PotButton_EventFrame:RegisterEvent(i)
end
--------------------------------------------------------------------
PotButton_EventFrame:SetScript("OnUpdate", function(self, elapsed)
	PotButton_Timer = PotButton_Timer + elapsed
	if PotButton_Timer > PotButton_TimerInterval then
		PotButton_UpdateButton()
		PotButton_Timer = 0
	end
end)
--------------------------------------------------------------------
SLASH_SETPOTIONBTN1 = "/setpot"
function SlashCmdList.SETPOTIONBTN(msg, editbox, ...)
	local spArgv, _ = SecureCmdOptionParse(msg)
	if (spArgv == nil or not CursorHasItem()) then return end

	local btns = ...
	local ctrlPressed = IsControlKeyDown()
	local altPressed = IsAltKeyDown()

	local itemName = ""
	local infoType, itemID = GetCursorInfo()
	if infoType == "item" then
		itemName = GetItemInfo(itemID)
	end

	if itemName ~= "" then
		if ctrlPressed and altPressed then
			PotButton.lists.ctrlAlt[1] = itemName
		elseif not ctrlPressed and not altPressed then
			PotButton.lists.nomod[1] = itemName
		elseif ctrlPressed then
			PotButton.lists.ctrl[1] = itemName
		else
			PotButton.lists.alt[1] = itemName
		end

		PotButton_ChangeInitiated = true
	end
end
--------------------------------------------------------------------
SLASH_POTBUTTONHELP1 = "/potbuttonhelp"
function SlashCmdList.POTBUTTONHELP(msg, editbox, ...)
	local spArgv, _ = SecureCmdOptionParse(msg)
	if (spArgv == nil) then return end

	DEFAULT_CHAT_FRAME:AddMessage("To add an item to PotButton:")
	DEFAULT_CHAT_FRAME:AddMessage("1. Pick up item with pointer")
	DEFAULT_CHAT_FRAME:AddMessage("2. Hold shift down")
	DEFAULT_CHAT_FRAME:AddMessage("3. Hold any combination of Ctrl and Alt")
	DEFAULT_CHAT_FRAME:AddMessage("4. Press the button you've assigned PotButton to")
	DEFAULT_CHAT_FRAME:AddMessage("Additionally, you may use /potbutton to open the config menu")
	DEFAULT_CHAT_FRAME:AddMessage("or use the menu in Interface -> AddOns -> PotButton")
	DEFAULT_CHAT_FRAME:AddMessage("Use /potbuttonreset to set current character's lists back to default")
end
--------------------------------------------------------------------
SLASH_POTBUTTONRESET1 = "/potbuttonreset"
function SlashCmdList.POTBUTTONRESET(msg, editbox, ...)
	PotButton.lists.nomod = nil
	PotButton.lists.ctrl = nil
	PotButton.lists.alt = nil
	PotButton.lists.ctrlAlt = nil
	PotButton.lists.nomod = {}
	PotButton.lists.ctrl = {}
	PotButton.lists.alt = {}
	PotButton.lists.ctrlAlt = {}
	PotButton_SetNomodWDefaultPotionList()

	PotButtonConfig_Update()
	PotButton_ChangeInitiated = true
	DEFAULT_CHAT_FRAME:AddMessage("PotButton reset")
end
--------------------------------------------------------------------
function PotButton_Init()
	if PotButton_AddonIsLoaded and PotButton_MacrosAreLoaded and PotButton_EnteredWorld then
		if not PotButton then PotButton = {} end
		--if not PotButton.nomod then PotButton.nomod = "" end
		--if not PotButton.ctrl then PotButton.ctrl = "" end
		--if not PotButton.alt then PotButton.alt = "" end
		
		if not PotButton.lists then
			PotButton.lists = {}
			PotButton.lists.nomod = {}
			PotButton.lists.ctrl = {}
			PotButton.lists.alt = {}
			PotButton.lists.ctrlAlt = {}
			-- Conversion to new list for users prior to 6.0.3.2
			if PotButton.nomod and PotButton.nomod ~= "" and not PotButton.lists.nomod[1] then
				PotButton.lists.nomod[1] = PotButton.nomod
				PotButton.nomod = nil
			end
			if PotButton.ctrl and PotButton.ctrl ~= "" and not PotButton.lists.ctrl[1] then
				PotButton.lists.ctrl[1] = PotButton.ctrl
				PotButton.ctrl = nil
			end
			if PotButton.alt and PotButton.alt ~= "" and not PotButton.lists.alt[1] then
				PotButton.lists.alt[1] = PotButton.alt
				PotButton.alt = nil
			end

			PotButton_SetNomodWDefaultPotionList()
		end
		
		PotButtonConfig_Init()
		PotButton_ChangeInitiated = true
	end
end
--------------------------------------------------------------------
function PotButton_SetNomodWDefaultPotionList()
	local addToNomod = function(str)
		PotButton.lists.nomod[getn(PotButton.lists.nomod) + 1] = str
	end

	addToNomod("Smuggled Tonic")
	addToNomod("Healing Tonic")
	addToNomod("Master Healing Potion")
	addToNomod("Mythical Healing Potion")
	addToNomod("Runic Healing Potion")
	addToNomod("Super Healing Potion")
	addToNomod("Major Healing Potion")
	addToNomod("Superior Healing Potion")
	addToNomod("Greater Healing Potion")
	addToNomod("Healing Potion")
	addToNomod("Lesser Healing Potion")
	addToNomod("Minor Healing Potion")
end
--------------------------------------------------------------------
function PotButton_GetModResultText(modName)
	local resultText = ""
	
	if getn(PotButton.lists[modName]) > 0 then
		for itemCount=1,getn(PotButton.lists[modName]) do
			if resultText == "" then
				if PotButton_PlayerHasItem(PotButton.lists[modName][itemCount]) then
					resultText = PotButton.lists[modName][itemCount]
				end
			end
		end
		
		-- If player has none of the items in this mod's list, they will get the
		-- first item in the list, which they won't be able to cast
		if resultText == "" then resultText = PotButton.lists[modName][1] end
	end
	
	return resultText
end
--------------------------------------------------------------------
function PotButton_PlayerHasItem(itemName)
	-- Check player bags for item
	local numberofslots
	local bagitemname
	for bagid=0,4 do
		numberofslots = C_Container.GetContainerNumSlots(bagid)
		if (numberofslots > 0) then
			for bagslotnum=1, numberofslots do
				local bagitemid = C_Container.GetContainerItemID(bagid, bagslotnum)
				if (bagitemid) then bagitemname = GetItemInfo(bagitemid) end
				if (itemName == bagitemname) then return true end
			end
		end
	end

	-- Check player equipped inventory for item
	for equipcount=1,19 do
		local equipitemid = GetInventoryItemID("player",equipcount)
		if equipitemid then equipitemname = GetItemInfo(equipitemid) end
		if itemName == equipitemname then return true end
	end
	
	return false
end
--------------------------------------------------------------------
function PotButton_UpdateButton()
	if PotButton_ChangeInitiated and not UnitAffectingCombat("player") then
		local btnPreviousText = ""
		local btnName = "Pot"
		local btnText = ""
		local nomodList = PotButton_GetModResultText("nomod")
		local nomodEmpty = nomodList == ""
		local ctrlList = PotButton_GetModResultText("ctrl")
		local ctrlEmpty = ctrlList == ""
		local altList = PotButton_GetModResultText("alt")
		local altEmpty = altList == ""
		local ctrlAltList = PotButton_GetModResultText("ctrlAlt")
		local ctrlAltEmpty = ctrlAltList == ""
		
		-- Condensed conditional helper strings
		local noMods = "[nomod:shift] "
		local modAlt = "[nomod:shift,mod:alt] "
		local modCtrl = "[nomod:shift,mod:ctrl] "
		local ctrlORalt = "[nomod:shift,mod:ctrl/alt] "
		local ctrlANDalt = "[nomod:shift,mod:ctrl,mod:alt] "
		
		if nomodEmpty and ctrlEmpty and altEmpty and ctrlAltEmpty then
			btnText = "/potbuttonhelp " .. noMods
		else
			btnText = "#showtooltip\n/cast "
			
			-- Process CA list
			if not ctrlAltEmpty then
				btnText = btnText .. (nomodEmpty and ctrlEmpty and altEmpty and noMods or ctrlANDalt)
				btnText = btnText .. ctrlAltList
			end
			
			-- Process alt list
			if not altEmpty then
				btnText = btnText .. (not ctrlAltEmpty and ";" or "")
				btnText = btnText .. (nomodEmpty and ctrlEmpty and noMods or "")
				btnText = btnText .. (not ctrlEmpty and modAlt or "")
				btnText = btnText .. (not nomodEmpty and ctrlEmpty and ctrlORalt or "")
				btnText = btnText .. altList
			end
			
			-- Process ctrl list
			if not ctrlEmpty then
				btnText = btnText .. ((not ctrlAltEmpty or not altEmpty) and ";" or "")
				btnText = btnText .. (nomodEmpty and noMods or "")
				btnText = btnText .. (not nomodEmpty and altEmpty and ctrlORalt or "")
				btnText = btnText .. (not nomodEmpty and not altEmpty and modCtrl or "")
				btnText = btnText .. ctrlList
			end
			
			-- Process nomod list
			if not nomodEmpty then
				btnText = btnText .. ((not ctrlAltEmpty or not altEmpty or not ctrlEmpty) and ";" or "")
				btnText = btnText .. noMods
				btnText = btnText .. nomodList
			end
		end
		
		btnText = btnText .. "\n/setpot [mod:shift]"

		local macroFrameOpen = false
		if MacroFrame and MacroFrame:IsShown() then
			macroFrameOpen = true
			MacroFrame:Hide()
		end

		if not GetMacroInfo(btnName) then
			CreateMacro(btnName, "INV_MISC_QUESTIONMARK", btnText, nil)
		else
			btnPreviousText = GetMacroBody(btnName)
			EditMacro(btnName,btnName, nil, btnText, 1, 1)
		end

		if macroFrameOpen then MacroFrame:Show() end

		if GetMacroInfo(btnName) then
			if btnPreviousText ~= btnText then 
				DEFAULT_CHAT_FRAME:AddMessage("PotButton updated!")
			end
			PotButton_ChangeInitiated = false
		end
	end
end