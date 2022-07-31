





local apiPackageName = "ModOptionsMenu.ModMenuApi";

local settings = {
	slide1 = 42;
	select1 = 0;
}


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
Not sure if more exist but you can try, I'd like to know
Also not sure if there exist any other text effects
YEL
RED
GRAY
--]]


--[[
	Here's a List of all the available api functions:
	
	ModUI.OnMenu(name, descript, uiCallback)
	ModUI.Slider(label, toolTip, curValue, min, max)
	ModUI.Button(label, prompt, toolTip)
	ModUI.Label(label, displayValue, toolTip)
	ModUI.Options(label, toolTip, curValue, count, optionNames, optionMessages)
	ModUI.PromptYN(promptMessage, callback(result))
	ModUI.PromptMsg(promptMessage, callback)
]]--




local buttonTxt = "Press Me";
local buttonPressed = false;
local labelValue = tostring(settings.slide1);



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


local name = "<COL RED>Test</COL> Mod";
local description = "It's just a test mod. What more do you want?";
local modObj = modUI.OnMenu(name, description, function()

	local changed = false;
	
	modUI.Header("Wow Custom Mod Settings This Is Crazy");
	settings.slide1, changed = modUI.Slider("Nice Slider", "Weeeee.", settings.slide1, 0, 69);
	
	if changed then
		--do something with slider value here
		
		labelValue = (settings.slide1 == 69) and "Nice" or tostring(settings.slide1);
		
		if (settings.slide1 == 69) then
			modUI.PromptMsg("That's Nice.", function()
				--optional callback
			end);
		end
	end
	
	if modUI.Button("This is a Button", buttonTxt, "It's just a button, really...") then
		
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
	

	modUI.Header("Another Header Just Because");
	modUI.Label("It's a label I guess", labelValue, "Exciting, right?");
	
	settings.select1, changed = modUI.Options("My Option Set", "Check out my cool options, half-off.",
		settings.select1, 3, optionNames, optionDescriptions);

	if changed then
		--do something with the selected index here
		log.debug("Selected: " .. settings.select1);
	end
	
end);







-------------------------------SAVE DATA STUFF---------------------

local function SaveSettings()
	json.dump_file("TestModSettings.json", settings);
end

local function LoadSettings()
	local loadedSettings = json.load_file("TestModSettings.json");
	if loadedSettings then
		settings = loadedSettings;
	end
end


LoadSettings();

re.on_config_save(function()
	SaveSettings();
end)























