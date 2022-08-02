




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



local suidCounter = 0;
local modStrings = {};
local modStringsToSuids = {};

local function GetNewId()
	suidCounter = suidCounter + 1;
	return suidCounter;
end

local function StringToSuid(str)

	local suid = modStringsToSuids[str];
	if suid then
		return suid;
	end

	--not entirely sure why these strings need to be permanent ref but the game crashes otherwise so whatever
	if not str then str = ""; end
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
local Return_SUID = StringToSuid("Return to the list of mods.")
local OpenMenu_ARR = CreateGuidArray(1, {OpenMenu_STRING});
local Go_ARR = CreateGuidArray(2, {Go_STRING, Go_STRING});




local GuiOptionWindowTypeSystem = sdk.typeof("snow.gui.GuiOptionWindow");
local viaGuiType = sdk.find_type_definition("via.gui.GUI");
local get_GameObject = viaGuiType:get_method("get_GameObject");
local goType = sdk.find_type_definition("via.GameObject");
local get_Components = goType:get_method("get_Components");
local get_Name = goType:get_method("get_Name");
local getComponent = goType:get_method("getComponent(System.Type)");


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

	SetBaseDataOptionName(opt.baseData, opt.name);
	SetBaseDataOptionMessage(opt.baseData, opt.message);
	
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

local function GetNewBaseData(opt)
	
	local unifiedData = sdk.create_instance("snow.StmUnifiedOptionBaseData", true):add_ref();
	local newBaseData = sdk.create_instance("snow.StmGuiOptionData.StmOptionBaseData"):add_ref();
	
	if opt then
	
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
	SetBaseDataOptionMessage(newBaseData, "Hi, it's <COL YEL>me.</COL>\n\nI made the mod menu ツ");
	
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
	return mainScrollList:get_CursorIndex() + 1;
end

local function GetIsModsTabSelected()
	if not optionWindow then return false end	
	return (optionWindow._scrL_TopMenu:get_CursorIndex() == MOD_TAB_IDX) and optionWindow:isOpenOption();
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


local scrollMenuObj = sdk.create_instance("snow.gui.SnowGuiCommonUtility.MenuScrollCursor", true):add_ref();
scrollMenuObj:set_dispMax(10);
local function SwapOptionArray(toBaseArray, toDataArray, maintainCursorPos)

	local arrSize = toBaseArray:get_size();

	if maintainCursorPos then
		local idx = GetSelectedModIndex();
		scrollMenuObj:set_cursorIndex((idx <= arrSize and idx or arrSize) - 1);
	else
		scrollMenuObj:set_cursorIndex(0);
	end
		
	
	scrollMenuObj:set_itemMax(arrSize);
	optionWindow:updateOptionCursor(scrollMenuObj, true);
	
	SetUnifiedOptionArrays(SAVE_DATA_IDX, toBaseArray, toDataArray);
	optionWindow:setOpenOption(SAVE_DATA_IDX);
	--optionWindow:setOptionList(optionWindow._DataList, 0); --not sure if this is really necessary
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


local function FirstOpen()	
	
	defaultSelMsgGuidArr = CreateGuidArray(1, {""});
	
	--need to store this here so we can swap between arrays later
	mainBaseDataList, mainDataList = GetUnifiedOptionArrays(SAVE_DATA_IDX);
	mainBaseDataList:add_ref_permanent();
	mainDataList:add_ref_permanent();	
	
	
	if not _CModUiList then _CModUiList = {}; end
	
	for idx, mod in ipairs(_CModUiList) do
		CreateOptionDataArrays(mod);
		AddNewModOptionButton(mod);
   end
	
	AddCreditsEntry();
	
	uiOpen = true;
end


--try to get it once on init just to make sure it gets filled if scripts are reset;
SetOptionWindow();
if optionWindow then
	FirstOpen();
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
	
	if (sdk.to_int64(args[4]) == 40) and GetIsModsTabSelected() then
		if not modMenuIsOpen and optionWindow._State == 1 then
			args[3] = ModsListDesc_Ptr;
		end
	else
		modMenuIsOpen = false;
	end
end



--GUID PLUGIN TEST
--[[
--I cannot believe this actually worked
local gid = ValueType.new(sdk.find_type_definition("System.Guid"));
gid:set_field("mData1", 69420);
local gPtr = sdk.to_ptr(gid:address());
re.msg(PtrToGuidTest(gPtr));
]]--

local suidArg;
local function PreMsg(args)
	--use custom plugin to grab first 32 bits of the guid from the args ptr which is plenty for what we need
	suidArg = PtrToGuidTest(args[2]);
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
	
		local pressIdx = optionWindow._scrL_MainOption:get_CursorIndex();
		local mod = _CModUiCurMod;
	
		--back button is at index 0 so handle returning to main mod list
		if pressIdx == 0 then
			modMenuIsOpen = false;
			SwapOptionArray(modBaseDataList, modDataList);
			return sdk.PreHookResult.SKIP_ORIGINAL;
			
		elseif mod.optionsOrdered[pressIdx].isBtn then
			mod.optionsOrdered[pressIdx].value = true;
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
		
		--return if we clicked an option that wasnt the back button
		return;
	end
	
	
	--go into a mod menu
	local selectedMod = _CModUiList[GetSelectedModIndex()];
	if not selectedMod then
		return;
	end
	
	
	_CModUiCurMod = selectedMod;
	modMenuIsOpen = true;	
	
	SwapOptionArray(selectedMod.unifiedBaseArray, selectedMod.unifiedArray);
	
	--this prevents the message text showing the save data message if the cursor hovers a header after the swap operation, 40 is options segment
	messageWindow:setSystemMessageText("", 40);
	
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


local function PreSwitchState(args)	
	
	--2 is in the state of selecting settings
	if modMenuIsOpen and optionWindow._State == 1 then
		--i kinda cant belivee this actually works
		optionWindow._State = 2;
		modMenuIsOpen = false;
		SwapOptionArray(modBaseDataList, modDataList);
		return sdk.PreHookResult.SKIP_ORIGINAL;
	end
end





local ignoreJmp = true;

sdk.hook(sdk.find_type_definition("snow.gui.GuiCommonMessageWindow"):get_method("setSystemMessageText(System.String, snow.gui.SnowGuiCommonUtility.Segment)"), PreOpt, PostDef, ignoreJmp);
--sdk.hook(sdk.find_type_definition("snow.gui.StmGuiInput"):get_method("convertIconTag_replaceOptionId(via.gui.Text, System.Guid)"), PreReplace, PostDef, ignoreJmp);
sdk.hook(sdk.find_type_definition("snow.gui.StmGuiInput"):get_method("convertIconTag_replaceOptionId(System.Guid)"), PreMsg, PostMsg, ignoreJmp);

local optionWindowType = sdk.find_type_definition("snow.gui.GuiOptionWindow");
sdk.hook(optionWindowType:get_method("ItemSelectDecideAction()"), PreSelect, PostDef, ignoreJmp);
sdk.hook(optionWindowType:get_method("setOpenOptionWindow(System.Collections.Generic.List`1<snow.StmOptionDef.StmOptionCategoryType>, snow.gui.GuiOptionWindow._void_OptionFunction, snow.gui.SnowGuiCommonUtility.Segment, System.Boolean)"), PreInitTopMenu, PostDef, ignoreJmp); --what a mouthfull
sdk.hook(optionWindowType:get_method("initTopMenu"), PreDef, PostInitTopMenu, ignoreJmp);
sdk.hook(optionWindowType:get_method("changeOptionState"), PreOptionChange, PostDef, ignoreJmp);
sdk.hook(optionWindowType:get_method("setOptionList(System.Collections.Generic.List`1<snow.StmUnifiedOptionData>, System.Int32)"), PreSwitchState, PostDef, ignoreJmp);
--ItemSelectDecideAction
--updateSelectValueSelect
--updateCategorySelect()
--changeOptionState(snow.gui.GuiOptionWindow.OptionState)



-----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------HANDLE GUI--------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

local function UpdateOpt(opt)
	SetOptStrings(opt);
	opt.needsUpdate = false;
end

local function RegenModOpts(mod)

	mod.optionsOrdered = {};
	mod.curOptIdx = 0;
	mod.guiCallback();
	mod.optionsCount = mod.curOptIdx;
	mod.regenOptions = false;
	
	CreateOptionDataArrays(mod);
	SwapOptionArray(mod.unifiedBaseArray, mod.unifiedArray, true);
end

local function Options(mod)
	
	
	if mod.regenOptions then
		RegenModOpts(mod);
		return sdk.PreHookResult.SKIP_ORIGINAL;
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
	
		if opt.needsUpdate then
			UpdateOpt(opt);
		end
	
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
		
			if data._SliderValue ~= opt.value then
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
		
			if data._SelectValue ~= opt.value then
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
	
	mod.curOptIdx = 0;
	mod.guiCallback();
	
	if mod.curOptIdx ~= mod.optionsCount then
		mod.regenOptions = true;
	end
end


local function PreOptWindowUpdate(args)

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



















































