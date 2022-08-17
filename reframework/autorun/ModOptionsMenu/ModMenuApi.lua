-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------API--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------


--Global mod variables
if not _CModUiList then
	_CModUiList = {};
	_CModUiCurMod = nil;
	_CModUiPromptCoRo = nil;
	_CmodUiColors = {};
end

local ModUI = {
	version = 1.65;
};

local ENUM = 0;
local SLIDER = 1;
local OTHERWINDOW = 2; --not used as this basically opens sub windows for graphics and stuff
local WATCHITEM = 3; --no idea what this is for really
local HEADER = 4;
local BUTTON = 5; --custom type






local lineBreakPattern = "(" .. ('.'):rep(40) .. ('.?'):rep(16) .. ") " -- in regex: /(.{40,56}) /

local function WrapText(text)
	if not text then
		return text;
	end
	local newlinePos = text:find("\n");
	if newlinePos then
		return text; -- assume the mod author wants to place newlines themselves
	end
	if #text <= 56 then
		return text;
	end
		
	text = text:gsub(lineBreakPattern, "%1\n");
  return text;
end

local function WrapTextTable(textTable)

	if not textTable then
		return nil;
	end

	local newTextTable = {};

	for _, text in ipairs(textTable) do
			table.insert(newTextTable, WrapText(text));
	end

	return newTextTable;
end





function ModUI.OnMenu(name, descript, uiCallback)		

	if not name then name = ""; end
	if not descript then descript = ""; end

	local mod = {
		originalName = name;
		modName = name;
		modNameSuid = 1;
		originalDescription = descript;
		description = WrapText(descript);
		optionsOrdered = {};
		guiCallback = uiCallback;
		created = false;
		curOptIdx = 0;
		indent = 0;
	};
	
	mod.UpdateGui = (function()
	
		mod.indent = 0;
		mod.curOptIdx = 0;
		
		mod.guiCallback();
		
		if mod.curOptIdx ~= mod.optionsCount then
			mod.regenOptions = true;
		end		
	end)
	
	table.insert(_CModUiList, mod);
	
	return mod;
end

function ModUI.Repaint()
	_CModUiRepaint();
end

local ColorStringType = sdk.find_type_definition("snow.gui.MessageManager.ColorString");
function ModUI.AddTextColor(colName, colHexStr)

	if not _CmodUiColors then _CmodUiColors = {}; end

	local newCol = ColorStringType:create_instance():add_ref();
	newCol.ColorName = colName;
	newCol.ColorValueStr = colHexStr;
	table.insert(_CmodUiColors, newCol);
end

function ModUI.ForceDeselect()
	local guiManager = sdk.get_managed_singleton("snow.gui.GuiManager");	
	local optionWindow = guiManager:get_refGuiOptionWindow();
	
	optionWindow._State = 2;
	optionWindow:setIsEditValue(false);
end

function ModUI.IncreaseIndent(val)
	_CModUiCurMod.indent = _CModUiCurMod.indent + (val and val or 1);
end

function ModUI.DecreaseIndent(val)
	_CModUiCurMod.indent = _CModUiCurMod.indent - (val and val or 1);	
end


function ModUI.SetIndent(val)
	_CModUiCurMod.indent = val;	
end

local function GetIndent(level)
	local pad = "			";
	for i = 2, level do
		pad = pad .. "			";
	end
	return pad;
end

local function GetFormattedName(name)
	if _CModUiCurMod.indent > 0 then
		return GetIndent(_CModUiCurMod.indent) .. name;
	else
		return name;
	end
end

local function GetOptionData(mod, optType, label, toolTip, defaultValue, immediate)

	mod.curOptIdx = mod.curOptIdx + 1;
	local data = mod.optionsOrdered[mod.curOptIdx];
	
	if not data then
	
		if not defaultValue then defaultValue = 0; end
		
		data = {
			parentMod = mod;
			type = optType;
			value = defaultValue;
			desiredValue = defaultValue;
			oldValue = defaultValue;
			name = label;
			displayName = (optType == HEADER) and label or GetFormattedName(label);
			message = toolTip;
			displayMessage = WrapText(toolTip);
			min = 0;
			max = 0;
			enumCount = 1;
			optionIdx = mod.curOptIdx;
			immediate = immediate;
		};
		
		mod.regenOptions = true;
		mod.optionsOrdered[mod.curOptIdx] = data;
		
		return data, true;
	else
	
		if data.name ~= label
			or data.message ~= toolTip
			or mod.regenOptions then
			
			mod.regenOptions = true;
			return;
		end
		
		return data, false;
	end
end



function ModUI.Slider(label, curValue, min, max, toolTip, immediate, isFloat)
	
	local mod = _CModUiCurMod;	
	local optData, new = GetOptionData(mod, SLIDER, label, toolTip, curValue, immediate);	
	if new then
		optData.min = min;
		optData.max = max;
		optData.float = isFloat;
	end
	if mod.regenOptions then return false, curValue; end
	
	local changed = optData.oldValue ~= optData.value;
	if not optData.wasChanged then
		--having to round this value is really dumb but otherwise it starts to bork things because of floating point precision issues
		optData.desiredValue = math.floor(curValue + 0.5);
	end
	optData.wasChanged = false;
	optData.oldValue = optData.value;
	return changed, optData.value;
end

-- the game legit internally represents float sliders as integers but scaled by 100 and then adds a decimal point...
-- this is why i initially thought the game didnt even support float sliders
-- this implementation is just so wack
function ModUI.FloatSlider(label, curValue, min, max, toolTip, immediate)

	if not curValue then curValue = 0; end

	local changed, val = ModUI.Slider(label, curValue * 100, min * 100, max * 100, toolTip, immediate, true);
	return changed, val * 0.01;
end


function ModUI.Header(label)
	local mod = _CModUiCurMod;
	local optData = GetOptionData(mod, HEADER, label);
end


function ModUI.Button(label, prompt, isHighlight, toolTip)
	
	prompt = prompt or "<COL YEL>Go</COL>";	

	local mod = _CModUiCurMod;	
	local optData, new = GetOptionData(mod, ENUM, label, toolTip);
	

	if new then
		optData.isBtn = true;
		optData.value = false;
		optData.enumNames = {prompt};
		optData.prompt = prompt;
		
		if isHighlight then
			optData.displayName = "<COL YEL>" .. optData.displayName .. "</COL>";
		end
	end
	if mod.regenOptions then return false; end
	
	
	if optData.prompt ~= prompt then
		mod.regenOptions = true;
	end
	
	if optData.value then
		optData.value = false;
		return true;
	end
	
	return false;
end


local checkLabels = {"☐","☒"};
function ModUI.CheckBox(label, curValue, toolTip)

	local mod = _CModUiCurMod;
	local optData, new = GetOptionData(mod, ENUM, label, toolTip);
	
	local idxValue = curValue and 1 or 0;
	if new then
		optData.isBtn = true;
		optData.value = false;
		optData.enumNames = checkLabels;
		optData.enumCount = 2;
		optData.max = 2;
		optData.desiredValue = idxValue;
	end
	if mod.regenOptions then return false, curValue; end
	
	local changed = false;
	if optData.value then
		changed = true;
	elseif optData.desiredValue ~= idxValue then
		changed = true;
	end
	
	if changed then
		optData.value = false;
		curValue = not curValue;
		optData.desiredValue = curValue and 1 or 0;
		optData.data._SelectValue = optData.desiredValue;
		optData.data._OldSelectValue = optData.desiredValue;
		ModUI.Repaint();
	end
	
	return changed, curValue;
end


function ModUI.Label(label, displayValue, toolTip)

	local mod = _CModUiCurMod;	
	local opt, new = GetOptionData(mod, WATCHITEM, label, toolTip);

	if new then
		opt.prompt = displayValue;
		opt.enumNames = {displayValue};
	end
	if mod.regenOptions then return; end
	
	if opt.prompt ~= displayValue then
		mod.regenOptions = true;
	end
end


function ModUI.Options(label, curValue, optionNames, optionMessages, toolTip, immediate)

	local mod = _CModUiCurMod;	
	local opt, new = GetOptionData(mod, ENUM, label, toolTip, curValue - 1, immediate);

	if new then
	
		local count = 0;
		for i, t in ipairs(optionNames) do
			count = count + 1;
		end
	
		opt.enumCount = count;
		opt.max = count;
		opt.enumNames = optionNames;
		opt.originalEnumMessages = optionMessages;
		opt.enumMessages = WrapTextTable(optionMessages);
	end
	if mod.regenOptions then
		return false, curValue;
	end
	
	if optionNames ~= opt.enumNames or optionMessages ~= opt.originalEnumMessages then
		mod.regenOptions = true;
	end
	
	local changed = opt.oldValue ~= opt.value;
	if not opt.wasChanged then
		opt.desiredValue = curValue - 1;
	end
	opt.wasChanged = false;
	opt.oldValue = opt.value;
	return changed, opt.value + 1;
end


--not entirely sure how i feel about these symbols but its neat
local offOn = {"✖","√"};
local offOnMsg = {"Disabled.","Enabled."};
function ModUI.Toggle(label, curValue, toolTip, togNames, togMsgs, immediate)
	local idx = curValue and 2 or 1;
	if not togNames then togNames = offOn; end
	if not togMsgs then togMsgs = offOnMsg; end
	local changed, optSel = ModUI.Options(label, idx, togNames, togMsgs, toolTip, immediate);
	return changed, (optSel == 2);
end



function ModUI.PromptMsg(promptMessage, callback)

	_CModUiPromptCoRo = coroutine.create(function()
	
		local gui_mgr = sdk.get_managed_singleton("snow.gui.GuiManager")
      gui_mgr:call(
          "setOpenInfo(System.String, snow.gui.GuiCommonInfoBase.Type, snow.gui.SnowGuiCommonUtility.Segment, System.Boolean, System.Boolean, snow.gui.GuiRootBaseBehavior)"
          , promptMessage, 0x1, 0x32, false, false, nil)

      coroutine.yield();

      while not gui_mgr:updateInfoWindow() do
          coroutine.yield();
      end		
		
		if callback then callback(); end
	end);
end

function ModUI.PromptYN(promptMessage, callback)

	_CModUiPromptCoRo = coroutine.create(function()
	
		local result = 2;
	
		local guiMgr = sdk.get_managed_singleton("snow.gui.GuiManager");
		guiMgr:call(
					"setOpenYNInfo(System.String, snow.gui.GuiManager.YNInfoUIState, snow.gui.SnowGuiCommonUtility.Segment, System.Boolean, System.Boolean)"
					,
					promptMessage, 0, 0x32, false, false
			)
	
		coroutine.yield();
		while result == 2 do
			local uiConfirmSoundID = 0xaa66032d;
			result = guiMgr:updateYNInfoWindow(uiConfirmSoundID);
			coroutine.yield();
		end
		
		guiMgr:closeYNInfo();
		
		if callback then callback(result == 0); end
	end);	
end


return ModUI;






































