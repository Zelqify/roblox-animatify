local ignoreList = {"Color3uint8","AssemblyCenterOfMass","BrickColor", "SyncingEditorText", "Rotation", "LocalTransparencyModifier", "CFrame", "Mass","AssemblyMass","size"}
local pluginVersion = "1.0.0"
local toolbar = plugin:CreateToolbar("Animatify " .. pluginVersion)
local button = toolbar:CreateButton(
	"Animatify",
	"Animatify",
	"rbxassetid://12918135608"
)
local UI = script.Parent.UI
local Section2 = script.Parent.Section2
local Section3 = script.Parent.Section3
local Result = script.Parent.Result
local canExit = false
local WidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 800,270,300,200)
local Widget = plugin:CreateDockWidgetPluginGui("tweenify", WidgetInfo)
Widget.Title = "Animatify " .. pluginVersion
UI.Parent = Widget
Section2.Parent = Widget
Section2.Visible = false
Section3.Parent = Widget
Result.Parent = Widget
Result.Visible = false
Section3.Visible = false

local function convertToCFrame(String)
	local splittedString = string.split(String,",")
	local newCFrame = "CFrame.new(" .. String .. ")"
	return newCFrame
end
local function convertToPosition(String)
	local splittedString = string.split(tostring(String),",")
	local position = "Vector3.new(" .. splittedString[1] .. ", " .. splittedString[2] .. ", " .. splittedString[3] .. ")"
	return position
end
local function convertToColor3(String)
	local splittedString = string.split(tostring(String),",")
	local position = "Color3.new(" .. splittedString[1] .. ", " .. splittedString[2] .. ", " .. splittedString[3] .. ")"
	return position
end

local selectedObject = nil
local Selection = game:GetService("Selection")
local TweenService = game:GetService("TweenService")
local AnimatifyButton = UI.Animatify
local ACTIVE = false
local didChangeProperties = false
local valuesChanged = {}
local Backup = nil
local oldParent = nil
local isPreviewing = false
local Length = 1
local generatedCode = ""
function PluginCode()
	if Widget.Enabled == true then
		Widget.Enabled = false
	else
		Widget.Enabled = true
	end
end
function ButtonClicked()
	PluginCode()
end
button.Click:connect(ButtonClicked)
AnimatifyButton.MouseButton1Up:Connect(function()
	if ACTIVE then
		UI.Visible = false
		Section2.Visible = true
		didChangeProperties = false
		valuesChanged = {}
		Backup = selectedObject:Clone()
		oldParent = selectedObject.Parent
	end
end)
Section2.GoBack.MouseButton1Up:Connect(function()
	selectedObject:Destroy()
	selectedObject = nil
	UI.Visible = true
	Section2.Visible = false
	didChangeProperties = false
	valuesChanged = {}
	Backup.Parent = oldParent	
end)
Section2.Complete.MouseButton1Up:Connect(function()
	selectedObject:Destroy()
	selectedObject = nil
	Section3.Visible = true
	Backup.Parent = oldParent	
	Section2.Visible = false
	Length = tonumber(Section3.length.TextBox.Text)
	isPreviewing = true
end)
Section3.GoBack.MouseButton1Up:Connect(function()
	selectedObject = nil
	UI.Visible = true
	Section2.Visible = false
	Section3.Visible = false
	didChangeProperties = false
	valuesChanged = {}
	Backup.Parent = oldParent	
	isPreviewing = false
	Length = 1
end)
Section3.Tweenify.MouseButton1Up:Connect(function()
	if canExit == true then
		isPreviewing = false
	end
	Section3.Visible = false
	didChangeProperties = false
	Backup.Parent = oldParent
	isPreviewing = false
	Result.Visible = true
	--local objectLocation = "game." .. Backup:GetFullName()
	local generatedTable = {}
	for property,value in pairs(valuesChanged) do
		wait(1)
		local genIndex = "['" .. property .. "'] = " .. tostring(value)
		if property == "Vector3" or property == "Orientation" or property == "Position" or property == "Size" then
			genIndex = "['" .. property .. "'] = " .. convertToPosition(value)
		elseif property == "Color" then
			genIndex = "['" .. property .. "'] = " .. convertToColor3(value)
		end
		generatedTable[#generatedTable + 1] = genIndex
	end
	local genFix = table.concat(generatedTable, ", ")
	generatedCode = 'game:GetService("TweenService"):Create(script.Parent,TweenInfo.new(' .. Length .. ", Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {" .. genFix .. "}):Play()"
	local newScript = Instance.new("Script")
	newScript.Name = "Animatify"
	newScript.Source = generatedCode
	newScript.Parent = Backup
end)
Result.Exit.MouseButton1Up:Connect(function()
	UI.Visible = true
	Result.Visible = false
	selectedObject = nil
	didChangeProperties = false
	valuesChanged = {}
	isPreviewing = false
	Length = 1
end)
while true do
	wait()
	if Widget.Enabled == true then
		if #Selection:Get() == 1 then
			selectedObject = Selection:Get()[1]
			if selectedObject:IsA("BasePart") then
				if #valuesChanged >= 1 then return end
				UI.selectionobjectbg.selectionobject.Text = selectedObject.Name
				TweenService:Create(AnimatifyButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(225, 56, 53)}):Play()
				ACTIVE = true
			end
		else
			ACTIVE = false
			UI.selectionobjectbg.selectionobject.Text = "no object selected"
			TweenService:Create(AnimatifyButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(148, 148, 148)}):Play()
		end
		if Section2.Visible == true then
			if didChangeProperties == true then
				TweenService:Create(Section2.Complete, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(225, 56, 53)}):Play()
			else
				TweenService:Create(Section2.Complete, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(148, 148, 148)}):Play()
			end
		end
	end
	if ACTIVE == true then
		selectedObject.Changed:Connect(function(valuechanged)
			for _,v in pairs(ignoreList) do
				if v == valuechanged then return end
			end
			didChangeProperties = true
			valuesChanged[valuechanged] = selectedObject[valuechanged]
		end)
	end
	if isPreviewing == true then
		ACTIVE = false
		Section3.Visible = true
		Length = tonumber(Section3.length.TextBox.Text)
		if Length == nil then Length = 1 end
		local newBackup = Backup:Clone()
		canExit = false
		local Tween = TweenService:Create(Backup, TweenInfo.new(Length, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), valuesChanged)
		Tween:Play()
		wait(Length)
		print(isPreviewing)
		Backup:Destroy()
		newBackup.Parent = oldParent
		Backup = newBackup
		canExit = true
	end
end
