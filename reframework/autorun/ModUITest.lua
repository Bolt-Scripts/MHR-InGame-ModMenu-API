







local settings = {
	slide1 = 42;
	select1 = 0;
}


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



--[[
Known Colors:
YEL
RED
GRAY
--]]


local buttonTxt = "Press Me";
local buttonPressed = false;
local labelValue = tostring(settings.slide1);




local modUI = require("ModOptionsMenu.ModMenuApi");

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
modUI.OnMenu(name, description, function()

	local changed = false;
	
	modUI.Header("Wow Custom Mod Settings This Is Crazy");
	settings.slide1, changed = modUI.Slider("Nice Slider", "Tip.", settings.slide1, 0, 69);
	
	if changed then
		--do something with slider value here
		
		labelValue = (settings.slide1 == 69) and "Nice" or tostring(settings.slide1);
		
	end
	
	if modUI.Button("This is a Button", buttonTxt, "It's just a button, really...") then
		buttonPressed = not buttonPressed;
		buttonTxt = buttonPressed and "<COL YEL>おめでとうね</COL>" or "Cool it.";
		
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

