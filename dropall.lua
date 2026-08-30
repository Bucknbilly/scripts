local players = game:GetService("Players")
local coregui = game:GetService("CoreGui")

local plr = players.LocalPlayer
local backpack = plr:WaitForChild("Backpack")

local old = coregui:FindFirstChild("Item Spam Drop")
if old then
	old:Destroy()
end

local rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local window = rayfield:CreateWindow({
	Name = "Item Spam Drop",
	LoadingTitle = "Item Spam Drop",
	LoadingSubtitle = "loading",
	ConfigurationSaving = {
		Enabled = false
	},
	ToggleUIKeybind = "K",
	Icon = 0,
	Theme = "Default"
})

local tab = window:CreateTab("Main", "home")

local selected = nil
local running = false
local delaytime = 0.01

local status = tab:CreateParagraph({
	Title = "status",
	Content = "idle"
})

local selectedlabel = tab:CreateParagraph({
	Title = "selected",
	Content = "none"
})

local function gettools()
	local list = {}

	for _, v in ipairs(backpack:GetChildren()) do
		if v:IsA("Tool") then
			list[#list + 1] = v
		end
	end

	local char = plr.Character

	if char then
		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("Tool") then
				list[#list + 1] = v
			end
		end
	end

	return list
end

local function getnames()
	local counts = {}
	local names = {}

	for _, tool in ipairs(gettools()) do
		if not counts[tool.Name] then
			counts[tool.Name] = 0
			names[#names + 1] = tool.Name
		end

		counts[tool.Name] = counts[tool.Name] + 1
	end

	local result = {}

	for _, name in ipairs(names) do
		if counts[name] > 1 then
			result[#result + 1] = name .. " (x" .. counts[name] .. ")"
		else
			result[#result + 1] = name
		end
	end

	return result
end

local function getcopies(name)
	local result = {}

	for _, tool in ipairs(gettools()) do
		if tool.Name == name then
			result[#result + 1] = tool
		end
	end

	return result
end

tab:CreateSection("tool selection")

local dropdown = tab:CreateDropdown({
	Name = "pick a tool",
	Options = getnames(),
	CurrentOption = {},
	MultipleOptions = false,

	Callback = function(value)
		local name

		if type(value) == "table" then
			name = value[1]
		else
			name = value
		end

		if type(name) ~= "string" or name == "" then
			selected = nil

			selectedlabel:Set({
				Title = "selected",
				Content = "none"
			})

			return
		end

		name = name:gsub("%s*%(x%d+%)$", "")
		selected = name

		local amount = #getcopies(name)

		selectedlabel:Set({
			Title = "selected",
			Content = name .. " (" .. amount .. " available)"
		})
	end
})

tab:CreateSlider({
	Name = "shuffle speed",
	Suffix = "s",
	CurrentValue = 0.01,
	Increment = 0.01,
	Range = {0.01, 0.5},
	Flag = "ShuffleSpeed",

	Callback = function(value)
		delaytime = tonumber(value) or 0.01
	end
})

local function refresh()
	dropdown:Refresh(getnames())

	if selected then
		local amount = #getcopies(selected)

		if amount > 0 then
			selectedlabel:Set({
				Title = "selected",
				Content = selected .. " (" .. amount .. " available)"
			})
		else
			selected = nil

			selectedlabel:Set({
				Title = "selected",
				Content = "none"
			})
		end
	end
end

tab:CreateButton({
	Name = "refresh tool list",

	Callback = function()
		refresh()

		rayfield:Notify({
			Title = "refreshed",
			Content = "tool list updated",
			Duration = 2
		})
	end
})

local function run()
	if running then
		return
	end

	if not selected then
		rayfield:Notify({
			Title = "error",
			Content = "please select a tool first",
			Duration = 3
		})
		return
	end

	if #getcopies(selected) == 0 then
		rayfield:Notify({
			Title = "error",
			Content = "no copies of " .. selected .. " found",
			Duration = 3
		})
		return
	end

	running = true

	rayfield:Notify({
		Title = "started",
		Content = "running until stopped",
		Duration = 2
	})

	task.spawn(function()
		while running do
			local tools = getcopies(selected)

			for i = #tools, 2, -1 do
				local j = math.random(i)
				tools[i], tools[j] = tools[j], tools[i]
			end

			for i, tool in ipairs(tools) do
				if not running then
					break
				end

				if tool and tool.Parent then
					status:Set({
						Title = "status",
						Content = "shuffling " .. i .. "/" .. #tools
					})

					local char = plr.Character
					local humanoid = char and char:FindFirstChildOfClass("Humanoid")

					if humanoid then
						pcall(function()
							humanoid:EquipTool(tool)
						end)

						task.wait()

						if not running then
							break
						end

						pcall(function()
							tool:Activate()
						end)

						task.wait(delaytime)
					end
				end
			end

			task.wait()
		end

		status:Set({
			Title = "status",
			Content = "stopped"
		})
	end)
end

tab:CreateButton({
	Name = "shuffle & click all",
	Callback = run
})

tab:CreateButton({
	Name = "stop",

	Callback = function()
		if not running then
			return
		end

		running = false

		status:Set({
			Title = "status",
			Content = "stopped"
		})

		rayfield:Notify({
			Title = "stopped",
			Content = "shuffle stopped",
			Duration = 2
		})
	end
})

refresh()

rayfield:Notify({
	Title = "loaded",
	Content = "select a tool and start the shuffle",
	Duration = 3
})
