local PotButtonConfig_ModifierList = {"None","Ctrl","Alt","Ctrl + Alt"}
local PotButtonConfig_ModListName = {}
PotButtonConfig_ModListName["None"] = "nomod"
PotButtonConfig_ModListName["Ctrl"] = "ctrl"
PotButtonConfig_ModListName["Alt"] = "alt"
PotButtonConfig_ModListName["Ctrl + Alt"] = "ctrlAlt"
local PotButtonConfig_CurrentModifier = "None"
local PotButtonConfig_TempEntryList = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"}
local PotButtonConfig_EntrySelected = 0
local PotButtonConfig_InitComplete = false

function PotButtonConfig_Init()
	PotButtonConfigFrame:Hide()
	PotButtonConfigFrame.name = "PotButton"
	InterfaceOptions_AddCategory(PotButtonConfigFrame);
	PotButtonConfigFrame:RegisterForDrag("LeftButton")
	PotButtonConfig_SetDropDowns()
	PotButtonConfigFrame_AddFrame_ebxAdd:SetTextInsets(8,5,5,5)
	PotButtonConfigFrame_btnAdd:Enable()
	PotButtonConfigFrame_btnRemove:Disable()
	PotButtonConfigFrame_btnUp:Disable()
	PotButtonConfigFrame_btnDown:Disable()
	PotButtonConfig_InitComplete = true
	PotButtonConfig_Update()
end
--------------------------------------------------------------------
SLASH_POTBUTTON1 = "/potbutton"
function SlashCmdList.POTBUTTON(msg, editbox, ...)
	--PotButton_ChangeInitiated = true
	if PotButtonConfigFrame:IsVisible() then
		PotButtonConfigFrame:Hide()
	else
		PotButtonConfigFrame:Show()
	end
end
--------------------------------------------------------------------
function PotButtonConfig_ButtonClick(btn)
	if btn:GetName() == "PotButtonConfigFrame_btnX" then
		PotButtonConfigFrame:Hide()
	elseif btn:GetName() == "PotButtonConfigFrame_btnCreate" then
		PotButton_ChangeInitiated = true
	elseif btn:GetName() == "PotButtonConfigFrame_btnAdd" then
		PotButtonConfig_EntrySelected = 0
		PotButtonConfig_Update()
		PotButtonConfigFrame_btnAdd:Disable()
		PotButtonConfigFrame_AddFrame:Show()
		PotButtonConfigFrame_AddFrame_ebxAdd:SetText("")
		PotButtonConfigFrame_AddFrame_btnOK:Disable()
		UIDropDownMenu_DisableDropDown(PotButtonConfigFrame_btnModifier)
	elseif btn:GetName() == "PotButtonConfigFrame_btnRemove" then
		local currentList = PotButton.lists[PotButtonConfig_ModListName[PotButtonConfig_CurrentModifier]]
		for listCount = PotButtonConfig_EntrySelected,(getn(currentList) - 1) do
			currentList[listCount] = currentList[listCount + 1]
		end
		currentList[getn(currentList)] = nil
		PotButtonConfig_Update()
		PotButton_ChangeInitiated = true
	elseif btn:GetName() == "PotButtonConfigFrame_btnClear" then
		local currentList = PotButton.lists[PotButtonConfig_ModListName[PotButtonConfig_CurrentModifier]]
		for listCount = getn(currentList),1,-1 do
			currentList[listCount] = nil
		end
		PotButtonConfig_Update()
		PotButton_ChangeInitiated = true
	elseif btn:GetName() == "PotButtonConfigFrame_btnUp" then
		local currentList = PotButton.lists[PotButtonConfig_ModListName[PotButtonConfig_CurrentModifier]]
		local tempString = currentList[PotButtonConfig_EntrySelected - 1]
		currentList[PotButtonConfig_EntrySelected - 1] = currentList[PotButtonConfig_EntrySelected]
		currentList[PotButtonConfig_EntrySelected] = tempString
		PotButtonConfig_EntrySelected = PotButtonConfig_EntrySelected - 1
		PotButtonConfig_Update()
		PotButton_ChangeInitiated = true
	elseif btn:GetName() == "PotButtonConfigFrame_btnDown" then
		local currentList = PotButton.lists[PotButtonConfig_ModListName[PotButtonConfig_CurrentModifier]]
		local tempString = currentList[PotButtonConfig_EntrySelected]
		currentList[PotButtonConfig_EntrySelected] = currentList[PotButtonConfig_EntrySelected + 1]
		currentList[PotButtonConfig_EntrySelected + 1] = tempString
		PotButtonConfig_EntrySelected = PotButtonConfig_EntrySelected + 1
		PotButtonConfig_Update()
		PotButton_ChangeInitiated = true
	elseif btn:GetName() == "PotButtonConfigFrame_AddFrame_btnOK" then
		local itemName = PotButtonConfigFrame_AddFrame_ebxAdd:GetText()
		local itemAlreadyInList = false
		local currentList = PotButton.lists[PotButtonConfig_ModListName[PotButtonConfig_CurrentModifier]]
		for listCount = 1, getn(currentList) do
			if currentList[listCount] == itemName then itemAlreadyInList = true end
		end
		if not itemAlreadyInList then
			currentList[getn(currentList) + 1] = itemName
			PotButton_ChangeInitiated = true
		end
		PotButtonConfigFrame_AddFrame:Hide()
		PotButtonConfigFrame_btnAdd:Enable()
		UIDropDownMenu_EnableDropDown(PotButtonConfigFrame_btnModifier)
		PotButtonConfig_Update()
	elseif btn:GetName() == "PotButtonConfigFrame_AddFrame_btnCancel" then
		PotButtonConfigFrame_AddFrame:Hide()
		PotButtonConfigFrame_btnAdd:Enable()
		UIDropDownMenu_EnableDropDown(PotButtonConfigFrame_btnModifier)	
	end
end
--------------------------------------------------------------------
local PotButtonConfig_DropDownSize = {}
PotButtonConfig_DropDownSize["PotButtonConfigFrame_btnModifier"] = 100

function PotButtonConfig_dropMenuShow(self)
	UIDropDownMenu_Initialize(self, PotButtonConfig_dropMenuInitialize);
	UIDropDownMenu_SetWidth(self,PotButtonConfig_DropDownSize[self:GetName()],3);
	UIDropDownMenu_JustifyText(self, "LEFT");
end

function PotButtonConfig_dropMenuInitialize(btn)
	local listForBtn
	
	if btn:GetName() == "PotButtonConfigFrame_btnModifier" then
		listForBtn = PotButtonConfig_ModifierList
	end
	
	PotButtonConfig_populateButton(btn, listForBtn)
end

function PotButtonConfig_populateButton(btn, listForBtn)
	if listForBtn then
		for listCount=1,getn(listForBtn) do
			PotButtonConfig_addDropDownMenuBtn(listForBtn[listCount], btn)
		end
	end
end

function PotButtonConfig_addDropDownMenuBtn(str, btn)
	local info = UIDropDownMenu_CreateInfo()
	info.text = str
	info.func = PotButtonConfig_dropDownMenuBtnClick
	info.owner = btn
	UIDropDownMenu_AddButton(info)
end

function PotButtonConfig_dropDownMenuBtnClick(self)
	local filtersChanged = false
	local parentFrame = self.owner;
	local selection = self:GetText();
	PotButtonConfig_setDropDownTo(parentFrame, selection)

	if parentFrame == PotButtonConfigFrame_btnModifier and PotButtonConfig_CurrentModifier ~= selection then
		PotButtonConfig_CurrentModifier = selection
		filtersChanged = true
	end
	
	if filtersChanged then
		PotButtonConfig_SetDropDowns()
	end
end

function PotButtonConfig_setDropDownTo(btn, str)
	UIDropDownMenu_SetSelectedValue(btn, str)
	UIDropDownMenu_SetText(btn, str)
end

function PotButtonConfig_SetDropDowns()
	PotButtonConfig_setDropDownTo(PotButtonConfigFrame_btnModifier,PotButtonConfig_CurrentModifier)
	PotButtonConfig_Update()
end
--------------------------------------------------------------------
function PotButtonConfig_Update()
	if PotButtonConfig_InitComplete then
		local currentList = PotButton.lists[PotButtonConfig_ModListName[PotButtonConfig_CurrentModifier]]
		local line;
		local lineplusoffset;
		local totalLines = getn(currentList);
		local condition;
		local lineText;
		FauxScrollFrame_Update(PotButtonConfigFrame_scrollBar,totalLines,6,16)
		
		for line=1,6 do
			lineplusoffset = line + FauxScrollFrame_GetOffset(PotButtonConfigFrame_scrollBar);
			if lineplusoffset <= totalLines then
				lineText = currentList[lineplusoffset]
			
				_G["PotButtonConfigFrame_scrollEntry"..line]:SetText(lineText);
				_G["PotButtonConfigFrame_scrollEntry"..line]:Show();

				if lineplusoffset == PotButtonConfig_EntrySelected then
					_G["PotButtonConfigFrame_scrollEntry"..line.."Background"]:SetVertexColor(1, 1, 1, 1);
				else
					_G["PotButtonConfigFrame_scrollEntry"..line.."Background"]:SetVertexColor(0, 0, 0, 0);
				end
			else
				_G["PotButtonConfigFrame_scrollEntry"..line]:Hide();
				_G["PotButtonConfigFrame_scrollEntry"..line.."Background"]:SetVertexColor(0, 0, 0, 0);
			end
		end
		
		if PotButtonConfig_EntrySelected > 0 then
			PotButtonConfigFrame_btnRemove:Enable()
			if PotButtonConfig_EntrySelected > 1 then
				PotButtonConfigFrame_btnUp:Enable()
			else
				PotButtonConfigFrame_btnUp:Disable()
			end
			if PotButtonConfig_EntrySelected < getn(currentList) then
				PotButtonConfigFrame_btnDown:Enable()
			else
				PotButtonConfigFrame_btnDown:Disable()
			end
			
		else
			PotButtonConfigFrame_btnRemove:Disable()
			PotButtonConfigFrame_btnUp:Disable()
			PotButtonConfigFrame_btnDown:Disable()
		end
		
		PotButtonConfigFrame_scrollBar:Show()
	end
end
--------------------------------------------------------------------
function PotButtonConfig_EntryClick(btn)
	PotButtonConfig_EntrySelected = tonumber(btn:GetName():sub(33)) + FauxScrollFrame_GetOffset(PotButtonConfigFrame_scrollBar)
	PotButtonConfig_Update()
end
--------------------------------------------------------------------
function PotButton_AddTextChanged()
	if PotButtonConfigFrame_AddFrame_ebxAdd:GetText():len() > 0 then
		PotButtonConfigFrame_AddFrame_btnOK:Enable()
	else
		PotButtonConfigFrame_AddFrame_btnOK:Disable()
	end
end
--------------------------------------------------------------------
local PotButtonConfig_equipClicked = function(button)
	if IsShiftKeyDown() and PotButtonConfigFrame_AddFrame_ebxAdd:HasFocus() then
		local itemId = GetInventoryItemID("player", GetInventorySlotInfo(string.sub(button:GetName(),10)))
		if itemId then
			local itemName = GetItemInfo(itemId)
			PotButtonConfigFrame_AddFrame_ebxAdd:Insert(itemName)
		end
	end
end
hooksecurefunc("PaperDollItemSlotButton_OnModifiedClick", PotButtonConfig_equipClicked)

local PotButtonConfig_bagItemClicked = function(button)
	if IsShiftKeyDown() and PotButtonConfigFrame_AddFrame_ebxAdd:HasFocus() then
		local btnName = button:GetName()
		local bagViewer = (string.find(btnName, "ARKINV_Frame") and "ArkInv" or "Default")
		local indexOfItem = string.find(btnName, "Item")
		local bagNum = tonumber(string.sub(btnName, indexOfItem - 1, indexOfItem - 1)) - 1
		local slotNum = tonumber(string.sub(btnName, indexOfItem + 4))
		
		local itemId = GetContainerItemID(bagNum, slotNum)
		if itemId then
			local itemName = GetItemInfo(itemId)
			PotButtonConfigFrame_AddFrame_ebxAdd:Insert(itemName)
		end
	end
end
hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", PotButtonConfig_bagItemClicked)