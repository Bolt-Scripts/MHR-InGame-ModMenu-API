-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------API--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------


--Global mod variables
if not _CModUiList then
	_CModUiList = {};
	_CModUiCurMod = nil;
	_CModUiPromptCoRo = nil;
end


local ModUI = {};

local ENUM = 0;
local SLIDER = 1;
local OTHERWINDOW = 2; --not used as this basically opens sub windows for graphics and stuff
local WATCHITEM = 3; --no idea what this is for really
local HEADER = 4;
local BUTTON = 5; --custom type


function ModUI.OnMenu(name, descript, uiCallback)		

	if not name then name = ""; end
	if not descript then descript = ""; end

	local mod = {
		modName = name;
		modNameSuid = 1;
		description = descript;
		optionsList = {};
		optionsOrdered = {};
		guiCallback = uiCallback;
		created = false;
		optionsCount = 0;
	};
	
	table.insert(_CModUiList, mod);
	
	--pre run the callback once on init to pre fill the mod's optionsList
	--should be fine since the ui functions will simply return the initial values anyway
	_CModUiCurMod = mod;
	uiCallback();
	
	return mod;
end

function ModUI.Repaint()
	_CModUiRepaint();
end






local function CheckLabel(opt, toolTip)

	if (opt.message ~= toolTip) then
		opt.message = toolTip;
		opt.needsUpdate = true;
	end
end


local function GetOptionData(mod, optType, label, toolTip, defaultValue)

	local data = mod.optionsList[label];
	if not data then
	
		if not defaultValue then defaultValue = 0; end
				
		data = {
			parentMod = mod;
			type = optType;
			value = defaultValue;
			desiredValue = defaultValue;
			oldValue = defaultValue;
			name = label;
			message = toolTip;
			min = 0;
			max = 0;
			enumCount = 1;
			needsUpdate = false;
		};
		
		mod.optionsCount = mod.optionsCount + 1;
		mod.optionsOrdered[mod.optionsCount] = data;
		mod.optionsList[label] = data;
		return data, true;
	else
		
		CheckLabel(data, toolTip);
		return data, false;
	end
end



function ModUI.Slider(label, toolTip, curValue, min, max)
	
	local mod = _CModUiCurMod;	
	local optData, new = GetOptionData(mod, SLIDER, label, toolTip, curValue);
	if new then
		optData.min = min;
		optData.max = max;
	end
	
	local changed = optData.oldValue ~= optData.value;
	if not optData.wasChanged then
		optData.desiredValue = curValue;
	end
	optData.wasChanged = false;
	optData.oldValue = optData.value;
	return optData.value, changed;
end

function ModUI.SliderScaled(label, toolTip, curValue, min, max, scale)
	local val, changed = ModUI.Slider(label, toolTip, curValue * scale, min * scale, max * scale);
	return val / scale, changed;
end


function ModUI.Header(label)
	local mod = _CModUiCurMod;	
	local optData = GetOptionData(mod, HEADER, label);	
end


function ModUI.Button(label, prompt, toolTip)

	local mod = _CModUiCurMod;	
	local optData, new = GetOptionData(mod, ENUM, label, toolTip);

	if new then
		optData.isBtn = true;
		optData.value = false;
		optData.enumNames = {prompt};
		optData.prompt = prompt;
	end
	
	if optData.prompt ~= prompt then	
		optData.prompt = prompt;
		optData.enumNames = {prompt};
		optData.needsUpdate = true;
	end
	
	if optData.value then
		optData.value = false;
		return true;
	end
	
	return false;
end


function ModUI.Label(label, displayValue, toolTip)

	local mod = _CModUiCurMod;	
	local opt, new = GetOptionData(mod, WATCHITEM, label, toolTip);

	if new then
		opt.enumNames = {displayValue};
		opt.prompt = displayValue;
	end
	
	if opt.prompt ~= displayValue then
		opt.prompt = displayValue;
		opt.enumNames = {displayValue};
		opt.needsUpdate = true;
	end
end


function ModUI.Options(label, toolTip, curValue, count, optionNames, optionMessages)

	local mod = _CModUiCurMod;	
	local opt, new = GetOptionData(mod, ENUM, label, toolTip, curValue);

	if new then
		opt.enumCount = count;
		opt.max = count;
		opt.enumNames = optionNames;
		opt.enumMessages = optionMessages;
	end
	
	if optionNames ~= opt.enumNames or optionMessages ~= opt.enumMessages then
		opt.enumNames = optionNames;
		opt.enumMessages = optionMessages;
		opt.needsUpdate = true;
	end
	
	local changed = opt.oldValue ~= opt.value;
	if not opt.wasChanged then
		opt.desiredValue = curValue;
	end
	opt.wasChanged = false;
	opt.oldValue = opt.value;
	return opt.value, changed;
end


--not entirely sure how i feel about these symbols but its neat
local offOn = {"✖","√"};
local offOnMsg = {"Disabled.","Enabled."};
function ModUI.Toggle(label, toolTip, curValue, togNames, togMsgs)
	local idx = curValue and 1 or 0;
	if not togNames then togNames = offOn; end
	if not togMsgs then togMsgs = offOnMsg; end
	local optSel, changed = ModUI.Options(label, toolTip, idx, 2, togNames, togMsgs);
	return (optSel == 1), changed;
end



function ModUI.PromptMsg(promptMessage, callback)

	_CModUiPromptCoRo = coroutine.create(function()
	
		local gui_mgr = sdk.get_managed_singleton("snow.gui.GuiManager")
      gui_mgr:call(
          "setOpenInfo(System.String, snow.gui.GuiCommonInfoBase.Type, snow.gui.SnowGuiCommonUtility.Segment, System.Boolean, System.Boolean)"
          , promptMessage, 0x1, 0x32, false, false)

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
			result = guiMgr:updateYNInfoWindow(0xaa66032d);
			coroutine.yield();
		end
		
		guiMgr:closeYNInfo();
		
		if callback then callback(result == 0); end
	end);	
end


return ModUI;






































