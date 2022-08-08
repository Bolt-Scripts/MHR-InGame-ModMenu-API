# ModOptionsMenu
 





## Example

Look at the `ModUI_ExampleTest.lua` file for a more detailed example to get your feet wet.

```lua

local modUI = require("ModOptionsMenu.ModMenuApi");

local someSettingValue = false;
local optionIdx = 1;

local options = {"Option1", "Option2"};

local name = "Example Mod";
local description = "It's just a test mod.";
local modObj = modUI.OnMenu(name, description, function()
	
	local changed;
	
	modUI.Header("Header");
	
	changed, someSettingValue = modUI.CheckBox("CheckBox", someSettingValue, "Some optional toolip style message here.");
	
	changed, optionIdx = modUI.Options("Options", optionIdx, options);

	--and so much more
	
end)
```

<br>

## API

### `local ModUI = require("ModOptionsMenu.ModMenuApi")`
Do something like this to import the api into your script.
It can be called anything you'd like.

---


### `ModUI.OnMenu(name, description, uiCallback)`
Register your mod to the options menu.

#### Params:
* `name` name of your mod that will be displayed in the menu
* `description` will be displayed in the system message box to describe your mod in the mod list
* `uiCallback` called every frame while your mod's menu is open. put your mod ui code in here

#### Returns: `an object containing the mod's data`

#### Notes:
	Technically you can register multiple mods through this but I would advise against it.
	Make sure to only call this once for the menu you want to add and NOT inside of some kind of update function.


---



### `ModUI.Header(text)`
Displays a non-interactable header message to divide your ui sections.
#### Notes:
	Displaying two headers right next to each other allows one to be selectable with a gamepad.

---



### `ModUI.FloatSlider(label, curValue, min, max, toolTip, isImmediateUpdate)`
Draws a float slider.

#### Params:
* `label` displayed name of this setting
* `curValue` the current/starting value that will be modified by the slider
* `min` minimum value the slider can go to
* `max` maximum value the slider can go to
* `(optional) toolTip` message displayed in the system message box while hovering this element
* `(optional) isImmediateUpdate`if true, the value will update immediately rather than waiting for the user to accept the change

#### Returns: `(tuple of) wasChanged, newValue`

#### Notes:
	Keep in mind this value only has precision to the nearest hundreth due to the game's limitations.

---



### `ModUI.Slider(label, curValue, min, max, toolTip, isImmediateUpdate)`
Draws an integer slider.

#### Params:
* `label` displayed name of this setting
* `curValue` the current/starting value that will be modified by the slider
* `min` minimum value the slider can go to
* `max` maximum value the slider can go to
* `(optional) toolTip` message displayed in the system message box while hovering this element
* `(optional) isImmediateUpdate` if true, the value will update immediately rather than waiting for the user to accept the change

#### Returns: `(tuple of) wasChanged, newValue`

---



### `ModUI.Options(label, curValue, optionNames, optionMessages, toolTip, isImmediateUpdate)`
Draws a cycle-able set of options for the user to choose between. 

#### Params:
* `label` displayed name of this setting
* `curValue` the current/starting index
* `optionNames` a lua table of the displayed names for each selectable option e.g. `{"Option1", "Option2"}`
* `(optional) optionMessages` a lua table of tooltips to go along with each option
* `(optional) toolTip` message displayed in the system message box while hovering this element
* `(optional) isImmediateUpdate` if true, the value will update immediately rather than waiting for the user to accept the change

#### Returns: `(tuple of) wasChanged, newIndex`

#### Notes:
	lua is NOT zero indexed, and neither is the input/output index of this function.
	The tables you give should be declared as variables OUTSIDE the scope of your UI callback.
	This is to avoid creating a new table every frame causing the UI to redraw every frame which breaks things.

---



### `ModUI.CheckBox(label, curValue, toolTip)`
An easily clickable checkbox useful for on/off values where the user doesn't have to manually select on or off

#### Params:
* `label` displayed name of this setting
* `curValue` the current/starting value
* `(optional) toolTip` message displayed in the system message box while hovering this element

#### Returns: `(tuple of) wasChanged, onOffValue`

---



### `ModUI.Toggle(label, curValue, toolTip, (optional)togNames[2], (optional)togMsgs[2], isImmediateUpdate)`
Basically a wrapper around ModUI.Options that only takes two options and returns the result as a boolean instead of an index

#### Params:
* `label` displayed name of this setting
* `curValue` the current/starting index
* `(optional) toolTip` message displayed in the system message box while hovering this element
* `(optional) togNames[2]` a lua table of the displayed names for each selectable option e.g. `{"Option1", "Option2"}`
* `(optional) togMsgs[2]` a lua table of tooltips to go along with each option
* `(optional) isImmediateUpdate` if true, the value will update immediately rather than waiting for the user to accept the change

#### Returns: `(tuple of) wasChanged, onOffValue`

#### Notes:
	The tables you give should be declared as variables OUTSIDE the scope of your UI callback.
	This is to avoid creating a new table every frame causing the UI to redraw every frame which breaks things.

---



### `ModUI.Button(label, prompt, isHighlight, toolTip)`
Draws clickable element in the GUI

#### Params:
* `label` displayed name of this setting
* `(optional) prompt` additional text to the right of the button
* `(optional) isHighlight` if true, the label will be highlighted in yellow to make it more apparent it's a button
* `(optional) toolTip` message displayed in the system message box while hovering this element

#### Returns: `(boolean) wasClicked`

---



### `ModUI.Label(label, displayValue, toolTip)`
Just draws some text

#### Params:
* `label` displayed name of this setting
* `(optional) displayValue` additional text to the right of the label, useful to display values and such
* `(optional) toolTip` message displayed in the system message box while hovering this element

---




### `ModUI.PromptYN(promptMessage, callback(result))`
Displays a system message prompt with an option to select yes or no.

#### Params:
* `promptMessage` text displayed within the prompt
* `callback(result)` function called when the user has selected their choice

#### Notes:
	The result in the callback will be true if the user selected `Yes`, and false if `No`.
---




### `ModUI.PromptMsg(promptMessage, callback)`
Displays a system message prompt.

#### Params:
* `promptMessage` text displayed within the prompt
* `callback` function called when the user has closed the prompt

#### Notes:
	The normal UI is not updated while the prompt is open.
---


<br>

## Rich Text:

The game has its own sort of 'rich text' functionality, currently I only really know how to use colors.<br>
I think there's a system for displaying button icons through text but you'd have to figure that out yourself.

### Built-in Colors:
* `YEL`
* `RED`
* `GRAY`
* More colors can be added (see `AddTextColor` below)

---
### `ModUI.AddTextColor(colName, colHexStr)`
#### Params:
* `colName` name of the color you wish to add, should be distinct
* `colHexStr` a string representing the color's hex code WITHOUT '#' symbol e.g. `"9F2B68"`
#### Notes:
	Call this BEFORE your UI code, otherwise will add the color every frame which would be BAD.
	Keep in mind these are shared across mods so use descriptive names.
	Use the name like the built in color codes e.g. if you added a color called 'purple' use `<COL purple>text</COL>`
---


<br>

## Layout Functions:
* `ModUI.IncreaseIndent()`
* `ModUI.DecreaseIndent()`
* `ModUI.SetIndent(indentLevel)`

#### Notes:
	You can have fairly dynamic UI layouts, but keep in mind every time something changes the entire UI needs to be rebuilt. Also the practical limits of how many elements you can have in one menu is untested currently.
---


<br>

## Rare Functions:

* ### `ModUI.Repaint()`
		Forces game to re-show the data and show changes.
		You probably don't need to use this anymore as almost any change should be automatically detected.

* ### `ModUI.ForceDeselect()`
		Forces game to deselect current option.

* ### `modObj.regenOptions`
		Can be set to true to force the API to regenerate the UI layout, but you probably dont need this.

---









































