




-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------UTILITY--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------


local SAVE_DATA_IDX = 4;
local DISPLAY_IDX = 5;
local ADV_GPU_OPT_IDX = 7;
local MOD_TAB_IDX = 6;

local ENUM = 0;
local SLIDER = 1;
local OTHERWINDOW = 2;
local WATCHITEM = 3; --no idea what this is for really
local HEADER = 4;
local BUTTON = 5; --custom type

local optionBaseDataType = sdk.find_type_definition("snow.StmGuiOptionData.StmOptionBaseData");
local optionDataType = sdk.find_type_definition("snow.StmOptionData"); 

local OptionName_OFFSET = optionBaseDataType:get_field("_OptionName"):get_offset_from_base();
local OptionMessage_OFFSET = optionBaseDataType:get_field("_OptionSystemMessage"):get_offset_from_base();
local SAVE_DATA_SUID = 789582228;

local function SaveData()
	if reframework.save_config then
		reframework:save_config();	
	end
end


local suidCounter = 1;
local modStrings = {};
local modStringsToSuids = {};

modStrings[1] = sdk.to_ptr(sdk.create_managed_string(""):add_ref_permanent());
modStringsToSuids[""] = 1;

local function GetNewId()
	suidCounter = suidCounter + 1;
	return suidCounter;
end

local function StringToSuid(str)

	if not str then return 1; end

	local suid = modStringsToSuids[str];
	if suid then
		return suid;
	end
	
	--not entirely sure why these strings need to be permanent ref but the game crashes otherwise so whatever
	suid = GetNewId();
	modStrings[suid] = sdk.to_ptr(sdk.create_managed_string(str):add_ref_permanent());
	modStringsToSuids[str] = suid;
	return suid;
end



--I dont like having to use the "write" functions but it simply doesnt work to set the guid values normally using set_field or anything
local function SetBaseDataOptionName(baseData, str)
	local suid = StringToSuid(str);
	baseData:write_dword(OptionName_OFFSET, suid);
	return suid;
end

local function SetBaseDataOptionMessage(baseData, str)	
	local suid = StringToSuid(str);
	baseData:write_dword(OptionMessage_OFFSET, suid);
	return suid;
end


local guidType = sdk.find_type_definition("System.Guid");
local guidTypeSystem = sdk.typeof("System.Guid");

local function GetManualGuid(suid)
	local guid = ValueType.new(guidType);
	guid:set_field("mData1", suid);
	return guid;
end

local function CreateGuidArray(count, stringTable)

	local arr = sdk.create_managed_array(guidTypeSystem, count):add_ref_permanent();
	
	for idx, str in ipairs(stringTable) do
		
		local suid = StringToSuid(str);
		local guid = GetManualGuid(suid);
		
		--no idea why but calling this "Set" method works while "set_Item" doesnt and its very annoying
		arr:call("Set", idx - 1, guid);
	end	
	
	return arr;
end


--Default Strings
local ModsListName_Str = sdk.create_managed_string("Mods"):add_ref_permanent();
local ModsListName_Ptr = sdk.to_ptr(ModsListName_Str);
local ModsListDesc_Ptr = sdk.to_ptr(sdk.create_managed_string("Adjust settings for mods using the <col YEL>custom mod menu.</col>"):add_ref_permanent());
local Go_STRING = ("<COL YEL>Go</COL>");
local OpenMenu_STRING = ("<COL YEL>Open Menu</COL>");
local Back_SUID = StringToSuid("Back To Mod List");
local Null_SUID = StringToSuid("Null");
local Return_Str = "Return to the list of mods.";
local Return_SUID = StringToSuid(Return_Str);
local OpenMenu_ARR = CreateGuidArray(1, {OpenMenu_STRING});
local Go_ARR = CreateGuidArray(2, {Go_STRING, Go_STRING});




local GuiOptionWindowTypeSystem = sdk.typeof("snow.gui.GuiOptionWindow");
local viaGuiType = sdk.find_type_definition("via.gui.GUI");
local get_GameObject = viaGuiType:get_method("get_GameObject");
local goType = sdk.find_type_definition("via.GameObject");
local get_Components = goType:get_method("get_Components");
local get_Name = goType:get_method("get_Name");
local getComponent = goType:get_method("getComponent(System.Type)");

local guiUtilityType = sdk.find_type_definition("snow.gui.SnowGuiCommonUtility");
local playSound = guiUtilityType:get_method("reqSe(System.UInt32)");
local uiConfirmSoundID = 0xaa66032d;

local msgManagerType = sdk.find_type_definition("snow.gui.MessageManager");
local ColTagUserData = msgManagerType:get_field("ColTagUserData");


local uiOpen = false;
local mainBaseDataList;
local mainDataList;
local modBaseDataList;
local modDataList;
local displayedList;
local defaultSelMsgGuidArr;

local guiManager;
local optionWindow;
local messageWindow;
local mainScrollList;
local subHeadingTxt;
local unifier;

local function GetUnifier()
	if not unifier then
		unifier = optionWindow:call("get_OptionDataUnifier");
	end
	
	return unifier;
end

local function SetOptionWindow(optWin)

	if optWin then
		optionWindow = optWin;
	else
		guiManager = sdk.get_managed_singleton("snow.gui.GuiManager");	
		if not guiManager then return end
		optionWindow = guiManager:get_refGuiOptionWindow();
		messageWindow = guiManager:get_refGuiCommonMessageWindow();
	end
	 
	
	mainScrollList = optionWindow._scrL_MainOption;
	subHeadingTxt = optionWindow._txt_SubHeading;
end

local ignoreSetSysMsg = false;
local function SetSystemMessage(str)
	messageWindow:setSystemMessageText(str, 40);
	ignoreSetSysMsg = true;
end


local function AppendArray(inArr, arrType, addItem)
	
	
	local count = 0;
	if inArr then
		count = inArr:get_size();
	end
	
	local newArr = sdk.create_managed_array(arrType, count + 1);
	newArr:add_ref_permanent();
	
	for i = 0, count - 1 do			
		newArr[i] = inArr[i];
	end
	
	newArr[count] = addItem;
	
	return newArr;
	
end

local function ArrayFirstElements(inArr, arrType, numElements)

	local newArr = sdk.create_managed_array(arrType, numElements);
	newArr:add_ref_permanent();
	
	for i = 0, numElements - 1 do			
		newArr[i] = inArr[i];
	end
	
	return newArr;
end


local modGuids = {};




local OptionBaseDataType = sdk.find_type_definition("snow.gui.userdata.GuiOptionData.OptionBaseData");
local OptionNameField = OptionBaseDataType:get_field("OptionName");


local function AddNewTopMenuCategory(catList)
	
	if not catList then
		catList = optionWindow:get_OptionCategoryTypeList();
	end
	
	
	local catListCount = catList:get_Count();	
	
	--prob shouldnt hardcode this but i dont exactly see them adding new options menu categories any time soon
	if catListCount > 6 then
		--mod entry already exists
		return;
	end
	
	catList:Add(SAVE_DATA_IDX);
end


local function GetUnifiedOptionArrays(idx)
	
	local catBaseDict = GetUnifier()._SortedUnifiedOptionBaseDataMap;
	local catDict = GetUnifier()._SortedUnifiedOptionDataMap;
	
	local baseList = catBaseDict:get_Item(idx);
	local dataList = catDict:get_Item(idx);
	
	return baseList, dataList, catBaseDict, catDict;
end

local function SetUnifiedOptionArrays(idx, baseDatas, datas, shouldAppend, shouldReset)

	displayedList = baseDatas;

	local baseList, dataList, catBaseDict, catDict = GetUnifiedOptionArrays(idx);
	
	if shouldAppend then
		
		if shouldReset then
		
			baseList = ArrayFirstElements(baseList, sdk.typeof("snow.StmUnifiedOptionBaseData"), 1);
			dataList = ArrayFirstElements(dataList, sdk.typeof("snow.StmUnifiedOptionData"), 1);
			
			catBaseDict:set_Item(idx, baseList);
			catDict:set_Item(idx, dataList);
			
		else
			catBaseDict:set_Item(idx, AppendArray(baseList, sdk.typeof("snow.StmUnifiedOptionBaseData"), baseDatas));
			catDict:set_Item(idx, AppendArray(dataList, sdk.typeof("snow.StmUnifiedOptionData"), datas));
		end
	else
		catBaseDict:set_Item(idx, baseDatas);
		catDict:set_Item(idx, datas);
	end
end


local function SetOptStrings(opt)

	SetBaseDataOptionName(opt.baseData, opt.displayName);
	SetBaseDataOptionMessage(opt.baseData, opt.displayMessage);
	
	if opt.baseData._OptionItemName then
		opt.baseData._OptionItemName:force_release();
	end

	if opt.baseData._OptionItemSelectMessage then
		opt.baseData._OptionItemSelectMessage:force_release();
	end
	
	--for some reason the game will crash if its a header type with empty OptionItemName[]
	--even though its a dang header that doesnt need them jeez
	if opt.enumNames then
		opt.baseData._OptionItemName = CreateGuidArray(opt.enumCount, opt.enumNames);
	else
		opt.baseData._OptionItemName = defaultSelMsgGuidArr;
	end
	
	if opt.enumMessages then
		opt.baseData._OptionItemSelectMessage = CreateGuidArray(opt.enumCount, opt.enumMessages);
	else
		opt.baseData._OptionItemSelectMessage = defaultSelMsgGuidArr;
	end
end

local function PrintObj(obj)
	
	local output = "{\n";
	for key, value in pairs(obj) do
		output = output .. "		" .. tostring(key) .. " = " .. tostring(value) .. ",\n";
	end
	
	output = output .. "}";
	return output;
end

local function GetNewBaseData(opt)
	
	local unifiedData = sdk.create_instance("snow.StmUnifiedOptionBaseData", true):add_ref();
	local newBaseData = sdk.create_instance("snow.StmGuiOptionData.StmOptionBaseData"):add_ref();
	
	if opt then
	
		--log.debug(PrintObj(opt));
	
		if opt.float then
			--setting this to 10 is mouse sensitivity and will make it appear as a float
			newBaseData._OptionType = 10;
		end
		
		newBaseData._PartsType = opt.type;
		newBaseData._SliderFloatMin = opt.min;
		newBaseData._SliderFloatMax = opt.max;
		opt.baseData = newBaseData;
		SetOptStrings(opt);
	end
	
	unifiedData:call(".ctor", 0, nil, newBaseData);
	
	return unifiedData, newBaseData;	
end

local function GetNewData(opt)

	local unifiedData = sdk.create_instance("snow.StmUnifiedOptionData", true):add_ref();
	local newData = sdk.create_instance("snow.StmOptionData", true):add_ref();
	
	if opt then		
		newData._PartsType = opt.type;
		newData._MinSliderValue = opt.min;
		newData._MaxSliderValue = opt.max;
		newData._SelectNum = opt.max - 1;
		
		newData._SliderValue = opt.desiredValue;
		newData._OldSliderValue = opt.desiredValue;
		newData._SelectValue = opt.desiredValue;
		newData._OldSelectValue = opt.desiredValue;
		opt.data = newData;
	end
	
	unifiedData:call(".ctor", 0, nil, newData);
	return unifiedData, newData;
end



local function AddNewModOptionButton(mod)

	local unifiedBaseData, newBaseData = GetNewBaseData();
	local unifiedData, newData = GetNewData();
	
	
	mod.modNameSuid = SetBaseDataOptionName(newBaseData, mod.modName);
	SetBaseDataOptionMessage(newBaseData, mod.description);
	
	newData._SelectNum = 0;
	newBaseData._OptionItemName = OpenMenu_ARR;
	newBaseData._OptionItemSelectMessage = newBaseData._OptionItemName;
	
	modBaseDataList = AppendArray(modBaseDataList, sdk.typeof("snow.StmUnifiedOptionBaseData"), unifiedBaseData);
	modDataList = AppendArray(modDataList, sdk.typeof("snow.StmUnifiedOptionData"), unifiedData);
end

local function AddCreditsEntry()

	
	local unifiedBaseData, newBaseData = GetNewBaseData();
	local unifiedData, newData = GetNewData();
	
	
	SetBaseDataOptionName(newBaseData, "Created By: <COL RED>Bolt</COL>");
	SetBaseDataOptionMessage(newBaseData, "Hi, it's <COL YEL>me.</COL>\nI made the mod menu ツ\nRemember to endorse the mods you like!");
	
	newBaseData._PartsType = WATCHITEM;
	newData._PartsType = WATCHITEM;
	
	newData._SelectNum = 0;
	newBaseData._OptionItemName = defaultSelMsgGuidArr;
	newBaseData._OptionItemSelectMessage = newBaseData._OptionItemName;
	
	modBaseDataList = AppendArray(modBaseDataList, sdk.typeof("snow.StmUnifiedOptionBaseData"), unifiedBaseData);
	modDataList = AppendArray(modDataList, sdk.typeof("snow.StmUnifiedOptionData"), unifiedData);
end

local function GetBackButtonData()

	local unifiedBaseData, newBaseData = GetNewBaseData();
	local unifiedData, newData = GetNewData();
	
	newBaseData:write_dword(OptionName_OFFSET, Back_SUID);
	newBaseData:write_dword(OptionMessage_OFFSET, Return_SUID);
	
	newData._SelectNum = 1;
	newData._SelectValue = 1;
	newBaseData._OptionItemName = Go_ARR;
	newBaseData._OptionItemSelectMessage = newBaseData._OptionItemName;
	
	return unifiedBaseData, unifiedData;
end


local function GetSelectedModIndex()
	return mainScrollList:get_SelectedIndex() + 1;
end

local function GetIsModsTabSelected()
	if not optionWindow then return false end	
	return (optionWindow._scrL_TopMenu:get_SelectedIndex() == MOD_TAB_IDX) and optionWindow:isOpenOption();
end


local function CreateOptionDataArrays(mod)

	if mod.unifiedBaseArray then mod.unifiedBaseArray:force_release(); end
	if mod.unifiedArray then mod.unifiedArray:force_release(); end

	local count = mod.optionsCount + 1;
	local baseDataArray = sdk.create_managed_array(sdk.typeof("snow.StmUnifiedOptionBaseData"), count):add_ref_permanent();
	local dataArray = sdk.create_managed_array(sdk.typeof("snow.StmUnifiedOptionData"), count):add_ref_permanent();
	
	
	local backBaseData, backData = GetBackButtonData();	
	baseDataArray[0] = backBaseData;
	dataArray[0] = backData;
	
	
	for idx, opt in ipairs(mod.optionsOrdered) do	
		local unifiedBaseData, baseData = GetNewBaseData(opt);
		local unifiedData, data = GetNewData(opt);
    	baseDataArray[idx] = unifiedBaseData;
		dataArray[idx] = unifiedData;
   end
	
	
	
	mod.unifiedBaseArray = baseDataArray;
	mod.unifiedArray = dataArray;
	mod.backBtnData = backData._StmOptionData;
end


local desiredSelectIdx = -1
local desiredCursorIdx = -1;
local desiredScrollIdx = -1;
local function SetDesiredScrollIndexes(maintainIndex, itemCount)
	if maintainIndex then
		desiredSelectIdx = mainScrollList:get_SelectedIndex();
		desiredCursorIdx = mainScrollList:get_CursorIndex();
		desiredScrollIdx = mainScrollList:get_ScrollIndex();
		
		--more logic to clamp these values since the game will absolutely not hesitate to crash if any of this goes past the limit
		local maxDispItems = 10;
		local maxScroll = itemCount - maxDispItems;
		if maxScroll < 0 then maxScroll = 0; end
		if desiredScrollIdx > maxScroll then desiredScrollIdx = maxScroll; end
		
		if desiredSelectIdx >= itemCount then desiredSelectIdx = itemCount - 1; end
		if desiredCursorIdx >= maxDispItems then desiredCursorIdx = maxDispItems - 1; end
	else
		desiredSelectIdx = 0;
		desiredCursorIdx = 0;
		desiredScrollIdx = 0;
	end
end


local function UpdateScrollIndex(clear)

	if desiredScrollIdx < 0 then return end

	if optionWindow._State > 1 then	
		--desiredScrollIdx is also used later and used to replace the scroll index on setOptionList bc of course it has to be used there too thats not confusing or anything
		--not sure if all of this is necessary or not but at least it makes sense now and works
		local menuCursor = optionWindow:get_OptionMenuListCursor();
		menuCursor:set_scrollIndex(desiredScrollIdx);
		menuCursor:set_cursorIndex(desiredCursorIdx);
		menuCursor:setIndex(desiredSelectIdx, true);
		optionWindow:updateOptionCursor(menuCursor, true);
	end
	
	if clear then
		--reset this so it doesnt overrite the value in setOptionList anymore
		desiredScrollIdx = -1;
	end
end


local function SwapOptionArray(toBaseArray, toDataArray, maintainCursorPos)

	SetDesiredScrollIndexes(maintainCursorPos, toBaseArray:get_size());

	ignoreSetSysMsg = true;
	
	SetUnifiedOptionArrays(SAVE_DATA_IDX, toBaseArray, toDataArray);
	optionWindow:setOpenOption(SAVE_DATA_IDX);
	--optionWindow:setOptionList(optionWindow._DataList, 0); --not sure if this is really necessary
	
	UpdateScrollIndex();
end




local needsRepaint = false;
function _CModUiRepaint()
	needsRepaint = true;
end

local textType = sdk.find_type_definition("via.gui.Text");
local function FindItemText(em)

	local next = em:get_Next();
	
	--prob a better way to iterate these but eh
	if next then
		if next:get_type_definition() == textType then
			next:set_Message(ModsListName_Str);
		else		
			FindItemText(next);
		end
	end
	
end

--for whatever reason the top menu text doesnt seem to go through the same message ID stuff or something so I just did this instead /shrug
local function ReplaceTopMenuText()
	local elements = optionWindow._scrL_TopMenu:get_Items();
	FindItemText(elements[MOD_TAB_IDX]:get_Child());
end


local colList;
local function HandleCustomColors()
	if _CmodUiColors then
		for idx, col in ipairs(_CmodUiColors) do
			colList:Add(col);
		end
		
		_CmodUiColors = nil;
	end
end

local function InitCustomColors()
	--clear the custom colors from the list so we dont create duplicates
	colList = ColTagUserData:get_data(nil).DataList;
	colList.mSize = 3;
end

local function InitMods()
	
end


local function FirstOpen()
	
	log.debug("first open")

	defaultSelMsgGuidArr = CreateGuidArray(1, {""});
	
	--need to store this here so we can swap between arrays later
	mainBaseDataList, mainDataList = GetUnifiedOptionArrays(SAVE_DATA_IDX);
	mainBaseDataList:add_ref_permanent();
	mainDataList:add_ref_permanent();
	
	InitCustomColors();
	
	if not _CModUiList then _CModUiList = {}; end
	
	for idx, mod in ipairs(_CModUiList) do
		
		--pre run the callback once on init to pre fill the mod's optionsList
		--should be fine since the ui functions will simply return the initial values anyway
		_CModUiCurMod = mod;
		
		local guiResult, error = pcall(mod.guiCallback);
		if not guiResult then
			log.debug("ModGui Error in " .. mod.originalName .. ": " .. error);
			log.error("ModGui Error in " .. mod.originalName .. ": " .. error);
			mod.modName = "<COL RED>Error: </COL>" .. mod.originalName;
			mod.description = "This mod threw an error on initialization:\n" .. error;
			mod.optionsCount = 0;
			mod.optionsOrdered = {};
			mod.curOptIdx = 0;
		else
			mod.regenOptions = false;
			mod.optionsCount = mod.curOptIdx;
		end		
		
	
		CreateOptionDataArrays(mod);
		AddNewModOptionButton(mod);
   end
	
	AddCreditsEntry();
	
	uiOpen = true;
end









-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------HOOKS--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------


local modMenuIsOpen = false;

local function PreDef(args)
end
local function PostDef(retval)
	return retval;
end

local function PreOpt(args)
	--local str = args[3];
	--local type = sdk.to_int64(args[4]);
	--log.debug("Str: " .. sdk.to_managed_object(str):call("ToString()") .. " : " .. type);
	
	if ignoreSetSysMsg then
		ignoreSetSysMsg = false;
		return sdk.PreHookResult.SKIP_ORIGINAL;
	end
	
	if (sdk.to_int64(args[4]) == 40) and GetIsModsTabSelected() then
		if not modMenuIsOpen and optionWindow._State == 1 then
			args[3] = ModsListDesc_Ptr;
		end
	else
		modMenuIsOpen = false;
	end
end


local guidData1Field = guidType:get_field("mData1");
local suidArg;
local function PreMsg(args)
	suidArg = guidData1Field:get_data(args[2]);
end

local function PostMsg(retval)

	--log.debug(suidArg .. " : " .. sdk.to_managed_object(retval):call("ToString()"));

	local modString = modStrings[suidArg];
	if modString then
		return modString;
	end

	if suidArg == SAVE_DATA_SUID and GetIsModsTabSelected() then
		--log.debug("save data suid: " .. suidArg);
		if modMenuIsOpen and _CModUiCurMod then
			return modStrings[_CModUiCurMod.modNameSuid];
		else
			return ModsListName_Ptr;
		end
	end
	
	
	return retval;
end



local function PreSelect(args)

	if (not GetIsModsTabSelected()) then
		return;
	end
	
	if modMenuIsOpen then
	
		local pressIdx = optionWindow._scrL_MainOption:get_SelectedIndex();
		local mod = _CModUiCurMod;
	
		--back button is at index 0 so handle returning to main mod list
		if pressIdx == 0 then
			modMenuIsOpen = false;
			playSound(nil, uiConfirmSoundID);
			SwapOptionArray(modBaseDataList, modDataList);
			SaveData(); --force a config save when we exit a mod menu
			return sdk.PreHookResult.SKIP_ORIGINAL;
			
		elseif mod.optionsOrdered[pressIdx].isBtn then
			playSound(nil, uiConfirmSoundID);
			mod.optionsOrdered[pressIdx].value = true;
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
		
		--return if we clicked an option that wasnt a button
		return;
	end
	
	
	--go into a mod menu
	local selectedMod = _CModUiList[GetSelectedModIndex()];
	if not selectedMod then
		return;
	end
	
	
	_CModUiCurMod = selectedMod;
	modMenuIsOpen = true;	
	
	--this prevents the message text showing the save data message if the cursor hovers a header after the swap operation, 40 is options segment
	SetSystemMessage(Return_Str);
	playSound(nil, uiConfirmSoundID);
	
	SwapOptionArray(selectedMod.unifiedBaseArray, selectedMod.unifiedArray);
	
	
	
	return sdk.PreHookResult.SKIP_ORIGINAL; 
end

local function PreSkipIfOpen(args)
	if modMenuIsOpen then
		return sdk.PreHookResult.SKIP_ORIGINAL;
	end
end


local function PreInitTopMenu(args)

	log.debug("Mod Menu Init");

	SetOptionWindow();
	AddNewTopMenuCategory(sdk.to_managed_object(args[3]));
	topInitialized = true;
end

local function PostInitTopMenu(retval)
	ReplaceTopMenuText();
	
	if not uiOpen then
		FirstOpen();
	end
	
	return retval;
end


local function PreOptionChange(args)
	
	log.debug("pre opt: ".."");

	if GetIsModsTabSelected() then
		if displayedList ~= modBaseDataList and (not modMenuIsOpen) then
			
			--cant believe this worked but need to do a proper -reswap or else for some reason some of the data isnt fully reloaded
			--it feels kinda like its caching the list count somewhere before this so only the first item updates properly
			SwapOptionArray(modBaseDataList, modDataList);
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
	else
		modMenuIsOpen = false;
		SetUnifiedOptionArrays(SAVE_DATA_IDX, mainBaseDataList, mainDataList);
	end
	
end


local function PreSetList(args)	
	
	--noooo idea why or whats going on but it seems snow.gui.GuiOptionWindow.changeOptionState no longer gets called after a game update so i guessssss this works toooo
	PreOptionChange();

	if desiredScrollIdx >= 0 then
		--need to override select index here
		args[4] = sdk.to_ptr(desiredScrollIdx);
	end	
	
	--handle backing out of sub menu
	--2 is in the state of selecting settings
	if modMenuIsOpen and optionWindow._State == 1 then
		--i kinda cant believe this actually works
		--closes the mod menu but returns the state to selecting to emulate backing out of the sub menu
		optionWindow._State = 2;
		modMenuIsOpen = false;
		SwapOptionArray(modBaseDataList, modDataList);
		SetSystemMessage(_CModUiList[1].description);
		SaveData(); --force a config save when we exit a mod menu
		return sdk.PreHookResult.SKIP_ORIGINAL;
	end
end

local function PostSwitchState(retval)
	UpdateSelectedIdx();
	return retval;
end


local ignoreJmp = true;

sdk.hook(sdk.find_type_definition("snow.gui.GuiCommonMessageWindow"):get_method("setSystemMessageText(System.String, snow.gui.SnowGuiCommonUtility.Segment)"), PreOpt, PostDef, ignoreJmp);
--sdk.hook(sdk.find_type_definition("snow.gui.StmGuiInput"):get_method("convertIconTag_replaceOptionId(via.gui.Text, System.Guid)"), PreReplace, PostDef, ignoreJmp);
sdk.hook(sdk.find_type_definition("snow.gui.StmGuiInput"):get_method("convertIconTag_replaceOptionId(System.Guid)"), PreMsg, PostMsg, ignoreJmp);

local optionWindowType = sdk.find_type_definition("snow.gui.GuiOptionWindow");
sdk.hook(optionWindowType:get_method("ItemSelectDecideAction()"), PreSelect, PostDef, ignoreJmp);
sdk.hook(optionWindowType:get_method("setOpenOptionWindow(System.Collections.Generic.List`1<snow.StmOptionDef.StmOptionCategoryType>, snow.gui.GuiOptionWindow._void_OptionFunction, snow.gui.SnowGuiCommonUtility.Segment, System.Boolean)"), PreInitTopMenu, PostDef, ignoreJmp); --what a mouthfull
sdk.hook(optionWindowType:get_method("initTopMenu"), PreDef, PostInitTopMenu, ignoreJmp);
-- sdk.hook(optionWindowType:get_method("changeOptionState(snow.gui.GuiOptionWindow.OptionState)"), PreOptionChange, PostDef, ignoreJmp);
sdk.hook(optionWindowType:get_method("setOptionList(System.Collections.Generic.List`1<snow.StmUnifiedOptionData>, System.Int32)"), PreSetList, PostDef, ignoreJmp);
--ItemSelectDecideAction
--updateSelectValueSelect
--updateCategorySelect()
--changeOptionState(snow.gui.GuiOptionWindow.OptionState)






-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------HANDLE GUI--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

local function RegenModOpts(mod)

	if optionWindow._State > 2 then
		--prevent options from being regenerated while user is editing something
		return;
	end

	mod.optionsOrdered = {};
	mod.curOptIdx = 0;
	mod.indent = 0;
	mod.guiCallback();
	mod.optionsCount = mod.curOptIdx;
	mod.regenOptions = false;
	
	CreateOptionDataArrays(mod);
	SwapOptionArray(mod.unifiedBaseArray, mod.unifiedArray, true);
	return sdk.PreHookResult.SKIP_ORIGINAL;
end

local function Options(mod)
	
	
	if mod.regenOptions then		
		return RegenModOpts(mod);
	end
	
	local wasReset = false;
	
	--this is a really goofy way of detecting if the options were reset but there wasnt a function to hook for it
	--so this is a clever way i think
	if mod.backBtnData._SelectValue == 0 then
	
		mod.backBtnData._SelectValue = 1;
	
		if _CModUiCurMod.OnResetAllSettings then
			_CModUiCurMod.OnResetAllSettings();
		end
		
		for idx, opt in ipairs(mod.optionsOrdered) do
			opt.wasChanged = false;
		end
		
		mod.guiCallback();
		
		needsRepaint = true;
		wasReset = true;
	end
	
	
	for idx, opt in ipairs(mod.optionsOrdered) do
	
		local data = opt.data;
	
		if wasReset then
			opt.value = opt.desiredValue;
			data._SelectValue = opt.desiredValue;
			data._SliderValue = opt.desiredValue;
			data._OldSliderValue = opt.desiredValue;
			data._OldSelectValue = opt.desiredValue;
			opt.wasChanged = true;
			
			if opt.isBtn then
				opt.value = false;
			end
	
		elseif opt.type == SLIDER then
		
			local checkValue = opt.immediate and data._SliderValue or data._OldSliderValue;
			if checkValue ~= opt.value then
				opt.value = data._SliderValue;
				data._OldSliderValue = opt.value;
				opt.desiredValue = opt.value;
				opt.wasChanged = true;
				
			elseif opt.value ~= opt.desiredValue then
				data._OldSliderValue = opt.desiredValue;
				data._SliderValue = opt.desiredValue;
				opt.value = opt.desiredValue;
				opt.wasChanged = true;
			end
			
		elseif opt.type == ENUM and not opt.isBtn then
		
			local checkValue = opt.immediate and data._SelectValue or data._OldSelectValue;
			if checkValue ~= opt.value then
				opt.value = data._SelectValue;
				data._OldSelectValue = opt.value;
				opt.desiredValue = opt.value;
				opt.wasChanged = true;
				
			elseif opt.value ~= opt.desiredValue then
				data._OldSelectValue = opt.desiredValue;
				data._SelectValue = opt.desiredValue;
				opt.value = opt.desiredValue;
				opt.wasChanged = true;
			end
		end
		
	end
	
	mod.UpdateGui();
end


local function PreOptWindowUpdate(args)

	if not optionWindow then
		SetOptionWindow();
	end

	if not uiOpen then
		FirstOpen();
		uiOpen = true;
		
		if GetIsModsTabSelected() then
			SwapOptionArray(modBaseDataList, modDataList);
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
	end

	if _CModUiPromptCoRo then
		if not coroutine.resume(_CModUiPromptCoRo) then
			_CModUiPromptCoRo = nil;
		else
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
	end

	local mod = _CModUiCurMod;
	if not mod then
		return;
	end

	if needsRepaint then
		needsRepaint = false;
		SwapOptionArray(mod.unifiedBaseArray, mod.unifiedArray, true);
		return sdk.PreHookResult.SKIP_ORIGINAL;
	end

	HandleCustomColors();
	UpdateScrollIndex(true);
	
	if modMenuIsOpen then
		return Options(mod);
	end
end


sdk.hook(optionWindowType:get_method("updateOptionOperation()"), PreOptWindowUpdate, PostDef, ignoreJmp);



re.on_script_reset(function()
	
	if mainBaseDataList then
		SetUnifiedOptionArrays(SAVE_DATA_IDX, mainBaseDataList, mainDataList);
	end
	
end)



















































