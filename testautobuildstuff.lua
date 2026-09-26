-- this is https://raw.githubusercontent.com/Bucknbilly/scripts/refs/heads/main/testautobuildstuff.lua

--[[
https://discord.gg/7fDasxV2Ht
enjoy auto building
i used ai for help, no hate

  :::.      .,-:::::/   :::.    :::::::..       .::    .   .::::::.    :::::::..  .,::::::
  ;;`;;   ,;;-'````'    ;;`;;   ;;;;``;;;;      ';;,  ;;  ;;;' ;;`;;   ;;;;``;;;; ;;;;''''
 ,[[ '[[, [[[   [[[[[[/,[[ '[[,  [[[,/[[['       '[[, [[, [[' ,[[ '[[,  [[[,/[[['  [[cccc
c$$$cc$$$c"$$c.    "$$c$$$cc$$$c $$$$$$c           Y$c$$$c$P c$$$cc$$$c $$$$$$c    $$""""
 888   888,`Y8bo,,,o88o888   888,888b "88bo,        "88"888   888   888,888b "88bo,888oo,__
 YMM   ""`   `'YMUP"YMMYMM   ""` MMMM   "W"          "M "M"   YMM   ""` MMMM   "W" """"YUMMM
]]

local buildString = _G.buildString or "PUTPASTEHERE"
local buildOffset = _G.buildOffset or Vector3.new(0, 0, 0)

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")

local CONFIG = {
	BUILD_HEIGHT_OFFSET   = 12,
	RESIZE_TIMEOUT        = 30,
	RESIZE_STUCK_LIMIT    = 12,
	RESIZE_STEP_WAIT      = 0.15,
	RESIZE_FIRE_TIMEOUT   = 1.5,
	RESIZE_MAX_FIRES      = 400,
	POSITION_MATCH_TOL    = 0.6,
	COLOR_MATCH_TOL       = 0.02,
	OBSTACLE_OVERLAP_EPS  = 0.10,
	PLACE_MAX_ATTEMPTS    = 40,
	BLOCK_RETRY_CAP       = 6,
}

_G.stopautobuild = false

-- ============================================================================
-- MATERIALS
-- ============================================================================
local SymbolToMaterial = {
	["!"]=Enum.Material.SmoothPlastic,  ["@"]=Enum.Material.Plastic,
	["#"]=Enum.Material.CeramicTiles,   ["$"]=Enum.Material.Brick,
	["%"]=Enum.Material.WoodPlanks,     ["^"]=Enum.Material.Ice,
	["&"]=Enum.Material.Grass,          ["*"]=Enum.Material.Sand,
	["("]=Enum.Material.Snow,           [")"]=Enum.Material.Glass,
	["-"]=Enum.Material.Wood,           ["_"]=Enum.Material.Slate,
	["="]=Enum.Material.Pebble,         ["+"]=Enum.Material.Marble,
	["["]=Enum.Material.Granite,        ["]"]=Enum.Material.DiamondPlate,
	["{"]=Enum.Material.Metal,          ["}"]=Enum.Material.Asphalt,
	["~"]=Enum.Material.Concrete,       ["`"]=Enum.Material.Pavement,
	["?"]=Enum.Material.Neon,
}

local MaterialToPaintName = {
	[Enum.Material.SmoothPlastic]="smooth", [Enum.Material.Plastic]="plastic",
	[Enum.Material.CeramicTiles]="tiles",   [Enum.Material.Brick]="bricks",
	[Enum.Material.WoodPlanks]="planks",    [Enum.Material.Ice]="ice",
	[Enum.Material.Grass]="grass",          [Enum.Material.Sand]="sand",
	[Enum.Material.Snow]="snow",            [Enum.Material.Glass]="glass",
	[Enum.Material.Wood]="wood",            [Enum.Material.Slate]="stone",
	[Enum.Material.Pebble]="pebble",        [Enum.Material.Marble]="marble",
	[Enum.Material.Granite]="granite",      [Enum.Material.DiamondPlate]="steel",
	[Enum.Material.Metal]="metal",          [Enum.Material.Asphalt]="asphalt",
	[Enum.Material.Concrete]="concrete",    [Enum.Material.Pavement]="pavement",
	[Enum.Material.Neon]="neon",
}

-- ============================================================================
-- UTILITIES
-- ============================================================================
local function hexToColor(hex)
	return Color3.new(
		tonumber(hex:sub(1,2),16)/255,
		tonumber(hex:sub(3,4),16)/255,
		tonumber(hex:sub(5,6),16)/255
	)
end

local function findBuildTools()
	local tools = {}
	for _, loc in pairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
		if loc then
			for _, item in pairs(loc:GetChildren()) do
				if item:IsA("Tool") and item.Name == "Build" then
					local ev = item:FindFirstChild("Script", true) and item.Script:FindFirstChild("Event")
					if ev then table.insert(tools, {tool=item, event=ev}) end
				end
			end
		end
	end
	return tools
end

local function findShapeTool()
	for _, loc in pairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
		if loc then
			for _, item in pairs(loc:GetChildren()) do
				if item:IsA("Tool") and item.Name == "Shape" then
					local ev = item:FindFirstChild("Script", true) and item.Script:FindFirstChild("Event")
					if ev then return {tool=item, event=ev} end
				end
			end
		end
	end
end

local function findPaintTool()
	for _, loc in pairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
		if loc then
			for _, item in pairs(loc:GetChildren()) do
				if item:IsA("Tool") and item.Name == "Paint" then
					local ev = item:FindFirstChild("Script", true) and item.Script:FindFirstChild("Event")
					if ev then return {tool=item, event=ev} end
				end
			end
		end
	end
end

local function findDeleteTool()
	for _, loc in pairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
		if loc then
			for _, item in pairs(loc:GetChildren()) do
				if item:IsA("Tool") and item.Name == "Delete" then
					local ev = item:FindFirstChild("Script", true) and item.Script:FindFirstChild("Event")
					if ev then return {tool=item, event=ev} end
				end
			end
		end
	end
end

local function getPlayerBricksFolder()
	local f = workspace:FindFirstChild("Bricks")
	return f and f:FindFirstChild(LocalPlayer.Name)
end

local function getBrickCount()
	local f = getPlayerBricksFolder()
	if not f then return 0 end
	local n = 0
	for _, b in ipairs(f:GetChildren()) do
		if b:IsA("BasePart") and b.Name == "Brick" then n = n + 1 end
	end
	return n
end

-- ============================================================================
-- CORNER MATH
-- ============================================================================
local function getCornerPosition(centerPos, size)
	local h = size / 2
	return centerPos - h + Vector3.new(0.5, 0.5, 0.5)
end

local function getBrickCorner(brick)
	return brick.Position - brick.Size / 2 + Vector3.new(0.5, 0.5, 0.5)
end

local function findBrickAtCorner(expectedCorner, tol)
	tol = tol or CONFIG.POSITION_MATCH_TOL
	local folder = getPlayerBricksFolder()
	if not folder then return nil end
	local best, bestDist = nil, tol
	for _, b in ipairs(folder:GetChildren()) do
		if b:IsA("BasePart") and b.Name == "Brick" then
			local d = (getBrickCorner(b) - expectedCorner).Magnitude
			if d < bestDist then bestDist = d; best = b end
		end
	end
	return best
end

-- ============================================================================
-- AABB OVERLAP
-- ============================================================================
local function getBounds(centerPos, size)
	local h = size / 2
	return centerPos - h, centerPos + h
end

local function boxesOverlap(minA, maxA, minB, maxB, eps)
	eps = eps or 0
	return (minA.X < maxB.X - eps and maxA.X > minB.X + eps)
	   and (minA.Y < maxB.Y - eps and maxA.Y > minB.Y + eps)
	   and (minA.Z < maxB.Z - eps and maxA.Z > minB.Z + eps)
end

local function findObstaclesInSpace(centerPos, size)
	local folder = getPlayerBricksFolder()
	if not folder then return {} end
	local tMin, tMax = getBounds(centerPos, size)
	local maxHalf = math.max(size.X, size.Y, size.Z) / 2
	local out = {}
	for _, b in ipairs(folder:GetChildren()) do
		if b:IsA("BasePart") and b.Name == "Brick" then
			local d = b.Position - centerPos
			local bMaxHalf = math.max(b.Size.X, b.Size.Y, b.Size.Z) / 2
			local radius = maxHalf + bMaxHalf
			if math.abs(d.X) < radius and math.abs(d.Y) < radius and math.abs(d.Z) < radius then
				local bMin, bMax = getBounds(b.Position, b.Size)
				if boxesOverlap(tMin, tMax, bMin, bMax, CONFIG.OBSTACLE_OVERLAP_EPS) then
					table.insert(out, b)
				end
			end
		end
	end
	return out
end

-- ============================================================================
-- VERIFICATION
-- ============================================================================
local function verifyBlock(brick, bd)
	if not brick or not brick.Parent then return false end
	if (brick.Position - bd.centerPos).Magnitude > CONFIG.POSITION_MATCH_TOL then return false end
	if brick.Size ~= bd.size then return false end
	if math.abs(brick.Color.R - bd.color.R) > CONFIG.COLOR_MATCH_TOL then return false end
	if math.abs(brick.Color.G - bd.color.G) > CONFIG.COLOR_MATCH_TOL then return false end
	if math.abs(brick.Color.B - bd.color.B) > CONFIG.COLOR_MATCH_TOL then return false end
	if brick.Material ~= bd.material then return false end
	if brick.CanCollide ~= bd.canCollide then return false end
	if bd.sprays and #bd.sprays > 0 then
		local n = 0
		for _, c in ipairs(brick:GetChildren()) do
			if c.Name == "Spray" then n = n + 1 end
		end
		if n < #bd.sprays then return false end
	end
	return true
end

local function identifyPlanBlock(blocks, brick)
	local bc = getBrickCorner(brick)
	for i = 1, #blocks do
		local bd = blocks[i]
		local c = getCornerPosition(bd.centerPos, bd.size)
		if (c - bc).Magnitude < CONFIG.POSITION_MATCH_TOL then
			return bd, i
		end
	end
	return nil
end

-- ============================================================================
-- DELETE
-- ============================================================================
local function deleteBrick(brick)
	if not brick or not brick.Parent then return false end
	local dt = findDeleteTool()
	if not dt then return false end
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	pcall(function() dt.event:FireServer(brick, hrp.Position) end)
	return true
end

-- ============================================================================
-- NOCLIP
-- ============================================================================
local noclipConn = nil
local NOCOLLIDE_PARTS = {
	"Head","Left Arm","Right Arm","LeftHand","RightHand",
	"LeftLowerArm","RightLowerArm","LeftUpperArm","RightUpperArm"
}

local function setCollisionDefaults()
	local c = LocalPlayer.Character
	if not c then return end
	for _, part in ipairs(c:GetChildren()) do
		if part:IsA("BasePart") then
			local skip = false
			for _, n in ipairs(NOCOLLIDE_PARTS) do
				if part.Name == n then skip = true; break end
			end
			part.CanCollide = not skip
		end
	end
end

local function enableNoclip()
	if noclipConn then noclipConn:Disconnect() end
	noclipConn = RunService.Stepped:Connect(function()
		local c = LocalPlayer.Character
		if not c then return end
		for _, part in ipairs(c:GetChildren()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)
end

local function disableNoclip()
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	setCollisionDefaults()
	local c = LocalPlayer.Character
	if c then
		local h = c:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end
end

-- ============================================================================
-- TOOL FORCING
-- ============================================================================
local toolConn = nil
local isBuilding = false

local function startToolForcing()
	isBuilding = true
	if LocalPlayer.Character then
		for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if t:IsA("Tool") and (t.Name=="Build" or t.Name=="Paint" or t.Name=="Shape" or t.Name=="Delete") then
				t.Parent = LocalPlayer.Character
			end
		end
	end
	if toolConn then toolConn:Disconnect() end
	toolConn = LocalPlayer.Backpack.ChildAdded:Connect(function(t)
		if not isBuilding then return end
		if t:IsA("Tool") and (t.Name=="Build" or t.Name=="Paint" or t.Name=="Shape" or t.Name=="Delete") then
			task.wait(0.01)
			if LocalPlayer.Character and t.Parent == LocalPlayer.Backpack then
				t.Parent = LocalPlayer.Character
			end
		end
	end)
end

local function stopToolForcing()
	isBuilding = false
	if toolConn then toolConn:Disconnect(); toolConn = nil end
end

-- ============================================================================
-- POSITION LOCK
-- ============================================================================
local posLock = nil

local function lockPosition(pos)
	if posLock then posLock:Disconnect() end
	posLock = RunService.RenderStepped:Connect(function()
		local c = LocalPlayer.Character
		if c and c:FindFirstChild("HumanoidRootPart") then
			local h = c.HumanoidRootPart
			h.CFrame = CFrame.new(pos)
			h.AssemblyLinearVelocity = Vector3.zero
			h.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end

local function unlockPosition()
	if posLock then posLock:Disconnect(); posLock = nil end
end

-- ============================================================================
-- PAINT / SPRAY
-- ============================================================================
local function paintBlock(brick, color, material)
	local pt = findPaintTool()
	if not pt then return false end
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local matName = MaterialToPaintName[material] or "smooth"
	for _ = 1, 2 do
		pcall(function()
			pt.event:FireServer(brick, Enum.NormalId.Left, hrp.Position,
				"both 🤝", color, matName, "")
		end)
		task.wait(0.05)
	end
	return true
end

local function sprayBlock(brick, face, text, colorHex)
	local pt = findPaintTool()
	if not pt then return false end
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local c = hexToColor(colorHex)
	pcall(function()
		pt.event:FireServer(brick, face, hrp.Position, "both 🤝", c, "spray", text)
	end)
	return true
end

-- ============================================================================
-- RESIZE (race-free, waits for server ack each step, oscillation-aware)
-- ============================================================================
local function resizeBlock(blockData)
	local st = findShapeTool()
	if not st then return false end

	local expectedCorner = getCornerPosition(blockData.centerPos, blockData.size)
	local target = blockData.size

	local deadline = tick() + CONFIG.RESIZE_TIMEOUT
	local fires = 0
	local recentSizes = {}

	local function pushSize(s)
		table.insert(recentSizes, s)
		if #recentSizes > 8 then table.remove(recentSizes, 1) end
	end

	local function seenOften(s)
		local c = 0
		for _, v in ipairs(recentSizes) do
			if (v - s).Magnitude < 0.01 then c = c + 1 end
		end
		return c >= 3
	end

	local function waitForChange(brick, before, timeout)
		local t0 = tick()
		while tick() - t0 < timeout do
			if not brick or not brick.Parent then return false end
			if brick.Size ~= before then return true end
			task.wait(0.03)
		end
		return false
	end

	while tick() < deadline do
		if _G.stopautobuild then unlockPosition(); return false end

		local brick = findBrickAtCorner(expectedCorner)
		if not brick then unlockPosition(); return false end
		if brick.Size == target then unlockPosition(); return true end

		if seenOften(brick.Size) then
			warn("[Autobuild] Resize oscillating at " .. tostring(brick.Size) ..
				" (target " .. tostring(target) .. ") - giving up")
			unlockPosition()
			return false
		end
		pushSize(brick.Size)

		if fires >= CONFIG.RESIZE_MAX_FIRES then
			warn("[Autobuild] Resize exceeded fire cap")
			unlockPosition()
			return false
		end

		local normalId, dir
		if brick.Size.X ~= target.X then
			normalId = Enum.NormalId.Right
			dir = brick.Size.X < target.X and "increase" or "decrease"
		elseif brick.Size.Y ~= target.Y then
			normalId = Enum.NormalId.Top
			dir = brick.Size.Y < target.Y and "increase" or "decrease"
		elseif brick.Size.Z ~= target.Z then
			normalId = Enum.NormalId.Back
			dir = brick.Size.Z < target.Z and "increase" or "decrease"
		else
			unlockPosition()
			return true
		end

		local outerCorner = brick.Position + brick.Size / 2
		lockPosition(outerCorner + Vector3.new(0, 8, 0))
		task.wait(0.05)

		local sizeBefore = brick.Size
		pcall(function()
			st.event:FireServer(brick, normalId, outerCorner, dir)
		end)
		fires = fires + 1

		local changed = waitForChange(brick, sizeBefore, CONFIG.RESIZE_FIRE_TIMEOUT)
		if not changed then
			task.wait(0.15)
		else
			task.wait(CONFIG.RESIZE_STEP_WAIT)
		end
	end

	unlockPosition()
	return false
end

-- ============================================================================
-- PARSE
-- ============================================================================
local function parseBlocks(buildStr)
	local blocks = {}
	for blockData in buildStr:gmatch("|([^|]+)") do
		local colorHex       = blockData:sub(1, 6)
		local materialSymbol = blockData:sub(7, 7)
		local rest           = blockData:sub(8)
		local canCollide     = true
		if rest:sub(1,1) == "^" then canCollide = false; rest = rest:sub(2) end

		local sizeData, posData, extraData = rest:match("^([%d,]+)%.([%-%.%d,]+)%.?(.*)")
		if sizeData and posData then
			local sx, sy, sz = sizeData:match("([%d]+),([%d]+),([%d]+)")
			local px, py, pz = posData:match("([%-]?%d+%.?%d*),([%-]?%d+%.?%d*),([%-]?%d+%.?%d*)")
			if sx and px then
				local size = Vector3.new(tonumber(sx), tonumber(sy), tonumber(sz))
				local centerPos = Vector3.new(tonumber(px), tonumber(py), tonumber(pz)) + buildOffset

				local is4x4x4 = (size == Vector3.new(4,4,4))
				local function mod4(n) return ((n % 4) + 4) % 4 end
				local onGrid = mod4(centerPos.X) == 2 and mod4(centerPos.Y) == 2 and mod4(centerPos.Z) == 2
				local needsResize = not (is4x4x4 and onGrid)

				local sprays = {}
				if extraData and extraData ~= "" then
					local faceMap = {L=Enum.NormalId.Left, R=Enum.NormalId.Right, T=Enum.NormalId.Top,
									 Bo=Enum.NormalId.Bottom, F=Enum.NormalId.Front, Ba=Enum.NormalId.Back}
					for face, text, color in extraData:gmatch('(%a+)"([^"]*)""([^"]*)"') do
						local nid = faceMap[face]
						if nid then
							table.insert(sprays, {face=nid, text=text or "", colorHex=color})
						end
					end
				end

				table.insert(blocks, {
					id           = #blocks + 1,
					size         = size,
					centerPos    = centerPos,
					color        = hexToColor(colorHex),
					material     = SymbolToMaterial[materialSymbol] or Enum.Material.SmoothPlastic,
					canCollide   = canCollide,
					needsResize  = needsResize,
					sprays       = sprays,
					placedBrick  = nil,
				})
			end
		end
	end
	return blocks
end

-- ============================================================================
-- PREVIEWS
-- ============================================================================
local function createPreviews(blocks)
	local folder = Instance.new("Folder")
	folder.Name = "BuildPreview"
	folder.Parent = workspace
	for i, bd in ipairs(blocks) do
		local p = Instance.new("Part")
		p.Name = "Preview_" .. i
		p.Size = bd.size
		p.CFrame = CFrame.new(bd.centerPos)
		p.Anchored = true
		p.CanCollide = false
		p.Material = bd.material
		p.Color = bd.color
		p.Transparency = 0.5
		p.Parent = folder
		bd.preview = p
	end
	return folder
end

local function cleanup(previewFolder)
	unlockPosition()
	stopToolForcing()
	disableNoclip()
	if previewFolder then pcall(function() previewFolder:Destroy() end) end
end

-- ============================================================================
-- ADJACENT PLACEMENT FINDER
-- ============================================================================
local function findAdjacentPlacement(blockData)
	local folder = getPlayerBricksFolder()
	if not folder then return nil, nil end
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, nil end

	local half1 = blockData.size / 2
	local best, bestFace, bestDist = nil, nil, math.huge

	for _, brick in ipairs(folder:GetChildren()) do
		if brick:IsA("BasePart") and brick.Name == "Brick" and brick.Size == blockData.size then
			if brick.Material == blockData.material and brick.CanCollide == blockData.canCollide then
				local dr = brick.Color.R - blockData.color.R
				local dg = brick.Color.G - blockData.color.G
				local db = brick.Color.B - blockData.color.B
				if math.abs(dr) < 0.01 and math.abs(dg) < 0.01 and math.abs(db) < 0.01 then
					local diff = blockData.centerPos - brick.Position
					local half2 = brick.Size / 2
					local expX = half1.X + half2.X
					local expY = half1.Y + half2.Y
					local expZ = half1.Z + half2.Z
					local face
					if math.abs(math.abs(diff.X) - expX) < 1
					   and math.abs(diff.Y) < half1.Y + 0.5
					   and math.abs(diff.Z) < half1.Z + 0.5 then
						face = diff.X > 0 and Enum.NormalId.Right or Enum.NormalId.Left
					elseif math.abs(math.abs(diff.Y) - expY) < 1
					   and math.abs(diff.X) < half1.X + 0.5
					   and math.abs(diff.Z) < half1.Z + 0.5 then
						face = diff.Y > 0 and Enum.NormalId.Top or Enum.NormalId.Bottom
					elseif math.abs(math.abs(diff.Z) - expZ) < 1
					   and math.abs(diff.X) < half1.X + 0.5
					   and math.abs(diff.Y) < half1.Y + 0.5 then
						face = diff.Z > 0 and Enum.NormalId.Back or Enum.NormalId.Front
					end
					if face then
						local d = (brick.Position - hrp.Position).Magnitude
						if d <= 25 and d < bestDist then
							best, bestFace, bestDist = brick, face, d
						end
					end
				end
			end
		end
	end
	return best, bestFace
end

-- ============================================================================
-- PLACE (single block, assumes target space is clear)
-- ============================================================================
local function placeBlock(blockData, buildTools)
	local bt = buildTools[1]
	if not bt then return false end

	local expectedCorner = getCornerPosition(blockData.centerPos, blockData.size)
	local tpPos = blockData.needsResize and expectedCorner or blockData.centerPos
	lockPosition(tpPos + Vector3.new(0, CONFIG.BUILD_HEIGHT_OFFSET, 0))
	task.wait(0.05)

	local placePos = blockData.needsResize and expectedCorner or blockData.centerPos
	local placeMode
	if not blockData.canCollide then
		placeMode = blockData.needsResize and "detailed nocollide" or "nocollide"
	else
		placeMode = blockData.needsResize and "detailed" or "normal"
	end

	local adjacent, adjacentFace = findAdjacentPlacement(blockData)
	local adjMode = blockData.canCollide and "normal" or "nocollide"

	local initialCount = getBrickCount()
	local attempts, maxAttempts = 0, CONFIG.PLACE_MAX_ATTEMPTS
	local retryDelay = blockData.canCollide and 0.05 or 0.2

	local function fire()
		if adjacent and adjacentFace then
			pcall(function() bt.event:FireServer(adjacent, adjacentFace, placePos, adjMode) end)
		else
			pcall(function() bt.event:FireServer(workspace.Terrain, Enum.NormalId.Top, placePos, placeMode) end)
		end
	end

	fire()
	while getBrickCount() == initialCount and attempts < maxAttempts do
		task.wait(retryDelay)
		if getBrickCount() > initialCount then break end
		attempts = attempts + 1
		fire()
	end

	if getBrickCount() == initialCount then return false end
	task.wait(0.03)

	local newBrick = findBrickAtCorner(expectedCorner, 0.6) or findBrickAtCorner(expectedCorner, 1.0)
	if not newBrick then return false end
	blockData.placedBrick = newBrick

	if blockData.needsResize and newBrick.Size ~= blockData.size then
		resizeBlock(blockData)
		newBrick = findBrickAtCorner(expectedCorner) or newBrick
		blockData.placedBrick = newBrick
	end

	paintBlock(newBrick, blockData.color, blockData.material)

	if blockData.sprays and #blockData.sprays > 0 then
		task.wait(0.03)
		for _, spray in ipairs(blockData.sprays) do
			sprayBlock(newBrick, spray.face, spray.text, spray.colorHex)
			task.wait(0.03)
		end
	end

	if not blockData.canCollide then
		task.wait(0.03)
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local pt = findPaintTool()
		if pt and hrp then
			pcall(function()
				pt.event:FireServer(newBrick, Enum.NormalId.Back, hrp.Position,
					"material", blockData.color, "collide", "")
			end)
		end
	end

	return true
end

-- ============================================================================
-- NEAREST UNBUILT
-- ============================================================================
local function getNearestUnbuiltIndex(blocks, done)
	local c = LocalPlayer.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local best, bestDist = nil, math.huge
	for i, bd in ipairs(blocks) do
		if not done[i] then
			local d = (hrp.Position - bd.centerPos).Magnitude
			if d < bestDist then bestDist = d; best = i end
		end
	end
	return best
end

-- ============================================================================
-- CORE BUILD LOOP
-- ============================================================================
local function runBuildLoop(blocks, opts)
	opts = opts or {}
	local buildTools = findBuildTools()
	if #buildTools == 0 then return false end
	if not findShapeTool() then return false end
	if not findPaintTool() then return false end

	local total = #blocks
	local done = {}
	local attempts = {}
	local placed = 0
	local gaveUp = 0

	if opts.initialDone then
		for i in pairs(opts.initialDone) do
			done[i] = true
			placed = placed + 1
		end
	end

	while placed + gaveUp < total do
		if _G.stopautobuild then return true end

		buildTools = findBuildTools()
		if #buildTools == 0 or not findShapeTool() or not findPaintTool() then
			return false
		end

		local i = getNearestUnbuiltIndex(blocks, done)
		if not i then break end
		local bd = blocks[i]

		local expectedCorner = getCornerPosition(bd.centerPos, bd.size)
		local existing = findBrickAtCorner(expectedCorner)

		if existing and verifyBlock(existing, bd) then
			bd.placedBrick = existing
			done[i] = true
			placed = placed + 1
			if bd.preview then pcall(function() bd.preview:Destroy() end) end
		else
			if existing then
				deleteBrick(existing)
				task.wait(0.1)
			end

			local obstacles = findObstaclesInSpace(bd.centerPos, bd.size)
			for _, obs in ipairs(obstacles) do
				local pm, pidx = identifyPlanBlock(blocks, obs)
				if pm and pidx ~= i then
					if done[pidx] then
						done[pidx] = nil
						placed = placed - 1
					end
					pm.placedBrick = nil
				end
				deleteBrick(obs)
				task.wait(0.05)
			end

			local ok = placeBlock(bd, buildTools)

			if ok and verifyBlock(bd.placedBrick, bd) then
				done[i] = true
				placed = placed + 1
				attempts[i] = nil
				if bd.preview then pcall(function() bd.preview:Destroy() end) end
			else
				attempts[i] = (attempts[i] or 0) + 1
				if attempts[i] >= CONFIG.BLOCK_RETRY_CAP then
					gaveUp = gaveUp + 1
					done[i] = true
					placed = placed + 1
					warn("[Autobuild] Gave up on block " .. i .. " after " .. attempts[i] .. " attempts")
				end
			end
		end

		unlockPosition()
		task.wait(0.05)
	end

	if gaveUp > 0 then
		warn("[Autobuild] Finished with " .. gaveUp .. " unbuildable block(s). Use Repair to retry.")
	end
	return true
end

-- ============================================================================
-- MAIN
-- ============================================================================
local function main()
	_G.stopautobuild = false

	local blocks = parseBlocks(buildString)
	if #blocks == 0 then return end

	local previewFolder = createPreviews(blocks)
	startToolForcing()
	enableNoclip()

	runBuildLoop(blocks)

	cleanup(previewFolder)
end

-- ============================================================================
-- REPAIR
-- ============================================================================
local function repairAllBlocks(bs)
	if _G.autobuildRunning then
		_G.stopautobuild = true
		task.wait(0.5)
	end
	_G.stopautobuild = false

	local blocks = parseBlocks(bs)
	if #blocks == 0 then
		warn("[Autobuild Repair] No blocks parsed")
		_G.autobuildRunning = false
		return
	end

	local buildTools = findBuildTools()
	if #buildTools == 0 or not findShapeTool() or not findPaintTool() or not findDeleteTool() then
		warn("[Autobuild Repair] Missing Build / Paint / Shape / Delete tool(s)")
		_G.autobuildRunning = false
		return
	end

	startToolForcing()
	enableNoclip()

	local folder = getPlayerBricksFolder()
	local alreadyGood = {}
	local deleted = 0

	if folder then
		for _, brick in ipairs(folder:GetChildren()) do
			if brick:IsA("BasePart") and brick.Name == "Brick" then
				local bd, idx = identifyPlanBlock(blocks, brick)
				if not bd then
					deleteBrick(brick); deleted = deleted + 1; task.wait(0.05)
				elseif not verifyBlock(brick, bd) then
					deleteBrick(brick); deleted = deleted + 1; task.wait(0.05)
				else
					bd.placedBrick = brick
					alreadyGood[idx] = true
				end
			end
		end
	end

	local goodCount = 0
	for _ in pairs(alreadyGood) do goodCount = goodCount + 1 end

	print(string.format("[Autobuild Repair] Deleted %d bad/orphan brick(s); %d already correct",
		deleted, goodCount))

	runBuildLoop(blocks, {initialDone = alreadyGood})

	cleanup(nil)
	_G.autobuildRunning = false
	print("[Autobuild Repair] Done.")
end

-- ============================================================================
-- EXPOSE API
-- ============================================================================
_G.AUTOBUILD_REPAIR = function()
	local bs = _G.buildString
	if not bs or bs == "" or bs == "PUTPASTEHERE" then
		warn("[Autobuild Repair] _G.buildString is not set")
		_G.autobuildRunning = false
		return
	end
	task.spawn(function()
		repairAllBlocks(bs)
	end)
end

_G.AUTOBUILD_VERIFY = verifyBlock
_G.AUTOBUILD_FIND_BRICK = findBrickAtCorner
_G.AUTOBUILD_GET_CORNER = getCornerPosition

-- ============================================================================
-- ENTRY
-- ============================================================================
if _G.AUTOBUILD_SKIP_MAIN then
	_G.AUTOBUILD_SKIP_MAIN = nil
elseif buildString and buildString ~= "" and buildString ~= "PUTPASTEHERE" then
	main()
end
