





local apiPackageName = "ModOptionsMenu.ModMenuApi";

local settings;
local function CreateNewSettings()
	settings = {
		slide1 = 42;
		slide2 = 314;
		select1 = 1;
		check1 = false;
		toggle1 = false;
		hide = false;
	}
end
CreateNewSettings();


local function LoadSettings()
	local loadedSettings = json.load_file("TestModSettings.json");
	if loadedSettings then
		settings = loadedSettings;
	end
end
LoadSettings();
settings.select1 = 1;

--no idea how this works but google to the rescue
--can use this to check if the api is available and do an alternative to avoid complaints from users
function IsModuleAvailable(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end


local modUI = nil;

if IsModuleAvailable(apiPackageName) then
	modUI = require(apiPackageName);
end


if not modUI then
	re.msg("No ModUI API package found. \nYou may need to download it or something.");
	return;
end


--[[
Known colors for "rich text": There really arent that many
But you can add more with ModUI.AddTextColor
YEL
RED
GRAY
--]]

--Technicallyyyy I think theres some weird formatting to get key icons to display but eh


--[[
	Here's a List of all the available api functions:
	all tooltip type things should be optional
	
	ModUI.OnMenu(name, descript, uiCallback)
	ModUI.FloatSlider(label, curValue, min, max, toolTip, isImmediateUpdate) -- keep in mind this value only has precision to the nearest hundreth
	ModUI.Slider(label, curValue, min, max, toolTip, isImmediateUpdate)
	ModUI.Button(label, prompt, isHighlight, toolTip)
	ModUI.CheckBox(label, curValue, toolTip)
	ModUI.Toggle(label, curValue, toolTip, (optional)togNames[2], (optional)togMsgs[2], isImmediateUpdate)
	ModUI.Label(label, displayValue, toolTip)
	ModUI.Options(label, curValue, optionNames, optionMessages, toolTip, isImmediateUpdate)
	ModUI.PromptYN(promptMessage, callback(result))
	ModUI.PromptMsg(promptMessage, callback)
	
	ModUI.Repaint() -- forces game to re-show the data and show changes
	ModUI.ForceDeselect() -- forces game to deselect current option
	modObj.regenOptions -- can be set to true to force the API to regenerate the UI layout, but you probably dont need this
	
	--call this BEFORE your UI code
	--keep in mind these are shared across mods so use descriptive names
	--do NOT include # in your hex color code string
	ModUI.AddTextColor(colName, colHexStr)
	
	ModUI.IncreaseIndent()
	ModUI.DecreaseIndent()
	ModUI.SetIndent(indentLevel)
]]--




local buttonTxt = "Press Me";
local buttonPressed = false;
local labelValue = tostring(settings.slide1);


--Colors
modUI.AddTextColor("purp", "9F2B68");


local optionNames = {
	"Basic Option",
	"Neat Option",
	"Epic Option",
};

local optionDescriptions = {
	"It's a basic, run-of-the-mill, option.",
	"Neato.",
	"Epic gamer moments only.",
};


local name = "<COL purp>Rad Example Mod</COL>";
local description = "It's just a test mod. What more do you want?\nAuthored by: Bolt";
local modObj = modUI.OnMenu(name, description, function()

	local changed = false;
	
	modUI.Header("Wow Custom Mod Settings This Is Crazy");
	changed, settings.slide1 = modUI.Slider("Nice Slider", settings.slide1, 0, 69, "Weeeee.");
	
	if changed then
		--do something with slider value here
		
		labelValue = (settings.slide1 == 69) and "Nice" or tostring(settings.slide1);
		
		if (settings.slide1 == 69) then
			
			modUI.PromptMsg("That's Nice.", function()
				--optional callback
				modUI.ForceDeselect();
				modUI.Repaint();
			end);
		end
	end
	
	if modUI.Button("This is a Button", buttonTxt, false, "It's just a button, really...") then
		
		if buttonTxt == "Cool it." then
			modUI.PromptYN("Did you mean to do that?", function(result)
				buttonTxt = (result and "Rude." or "It's Okay.");							
				modUI.Repaint();
			end);
		else
			buttonPressed = not buttonPressed;
			buttonTxt = buttonPressed and "<COL YEL>おめでとうね</COL>" or "Cool it.";
		end
		
		--need to repaint if text changes or something so it updates responsively
		modUI.Repaint();
	end
	
	if modUI.version >= 1.2 then
		changed, settings.slide2 = modUI.FloatSlider("Precise Slider", settings.slide2, 69, 420, "Well, it's only really accurate to 2 decimal places...");
		
	
		if modUI.Button("[Hide Section 2]", "", true, "Crazy.") then
			settings.hide = not settings.hide;
		end	
	end
	
	
	if not settings.hide then
		modUI.Header("Another Header Just Because");
		
		changed, settings.check1 = modUI.CheckBox("Hey, A CheckBox!", settings.check1, "Why didn't I think of this sooner?!");
		
		modUI.Label("<COL YEL>It's a label I Guess</COL>", labelValue, "Exciting, right?");
		
		changed, settings.select1  = modUI.Options("My Option Set", settings.select1, optionNames, optionDescriptions,
			"Check out my cool options, half-off.");
	
		if changed then
			--do something with the selected index here
			log.debug("Selected: " .. settings.select1);
		end
		
		changed, settings.toggle1 = modUI.Toggle("Toggle me, senpai!", settings.toggle1, "OwO");
		if changed and settings.toggle1 then
			modUI.ForceDeselect();
			modUI.PromptMsg("Pervert...");
			settings.toggle1 = false;
		end
	end
	
end);


--add a callback here in order to hook when the user resets all settings
modObj.OnResetAllSettings = (function()	
	CreateNewSettings();
end)





-------------------------------SAVE DATA STUFF---------------------

local function SaveSettings()
	json.dump_file("TestModSettings.json", settings);
end


re.on_config_save(function()
	SaveSettings();
end)























