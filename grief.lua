 local Players = game:GetService("Players")
  local lp = Players.LocalPlayer
  local ws = math.max(lp:GetNetworkPing()+0.007, 0.051)
  local isog = workspace:FindFirstChild("Cubes") ~= nil
  local cfolder = isog and workspace:FindFirstChild("Cubes") or workspace:FindFirstChild("Bricks")

  local function findbtools()
      local t = {}
      for _, v in pairs(lp.Character:GetChildren()) do
          if v:IsA("Tool") and v.Name=="Delete" then
              local s = v:FindFirstChild("Script") or v:FindFirstChild("LocalScript")
              local e = s and s:FindFirstChild("Event")
              if e then table.insert(t, {bt=v, e=e}) end
          end
      end
      for _, v in pairs(lp.Backpack:GetChildren()) do
          if v:IsA("Tool") and v.Name=="Delete" then
              local s = v:FindFirstChild("Script") or v:FindFirstChild("LocalScript")
              local e = s and s:FindFirstChild("Event")
              if e then table.insert(t, {bt=v, e=e}) end
          end
      end
      return t
  end

  getgenv().stopGrief = false
  local i = 0
  task.spawn(function()
      while not getgenv().stopGrief do
          local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
          local dtools = findbtools()
          local descendants = cfolder:GetDescendants()
          if #descendants == 0 or #dtools == 0 or not r then
              task.wait(1)
          else
              for _, v in pairs(descendants) do
                  if getgenv().stopGrief then break end
                  if v:IsA("BasePart") then
                      i = i+1
                      local dt = dtools[(i%#dtools)+1]
                      if dt.bt.Parent ~= lp.Character then dt.bt.Parent = lp.Character end
                      dt.e:FireServer(v, r.Position)
                      task.wait(ws/#dtools)
                  end
              end
              task.wait(0.5)
          end
      end
  end)

  Stop it with:

  getgenv().stopGrief = true
