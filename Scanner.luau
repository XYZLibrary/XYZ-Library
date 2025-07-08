local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local function ConvertStringsToLower(...)

	local Clone = table.clone(...)

	for Index, String in pairs(Clone) do
		Clone[Index] = String:lower()
	end

	return Clone

end

local function GetFolderIn(Parent: Instance, Name: string)

	local MainFolder = Parent:FindFirstChild(Name)

	if not MainFolder then

		local NewFolder = Instance.new("Folder", Parent)
		NewFolder.Name = Name

		MainFolder = NewFolder

	end

	return MainFolder

end

local function CleanSeedName(CurrentName: string)

	CurrentName = CurrentName:gsub("%s*Seed%s*", "")
	CurrentName = CurrentName:gsub("%s*%[.-%]", "")
	CurrentName = CurrentName:gsub("%s+$", "")

	return CurrentName

end

local function IsDuplicate(Parent: Instance, Name: string)

	for _, Object in pairs(Parent:GetChildren()) do

		if Object.Name:lower():find(Name:lower()) then
			return true
		end

	end

	return false

end

local function ExtractSeedModel(Tool: Tool)

	local FindSeed = Tool:FindFirstChild("Handle") or Tool:FindFirstChildWhichIsA("Part")

	if FindSeed then
		
		local Extracted = FindSeed:Clone()

		Extracted:SetAttribute("ORIGINAL_NAME", Tool.Name)

		local CleanName = CleanSeedName(Tool.Name)

		Extracted.Name = CleanName

		return Extracted

	else

		return Tool:Clone()

	end

end

local function DisplayResults(Found: {}, FoundDuplicates: {})

	if #Found == 0 then

		if #FoundDuplicates ~= 0 then
			print(("None were found, just %* duplicate%*. (%*)"):format(#FoundDuplicates, #FoundDuplicates == 1 and "" or "s", table.concat(FoundDuplicates, ", ")))
		else
			print("None were found.")
		end

	else

		print(("Found %*!"):format(table.concat(Found, ", ")))

		if #FoundDuplicates ~= 0 then
			print(("And duplicate%*: %*"):format(#FoundDuplicates == 1 and "" or "s", table.concat(FoundDuplicates, ", ")))
		end

	end

end

local function ScanServer(ScanFor: {}, Configuration: {})
	
	local MainFolder = GetFolderIn(workspace, Configuration.Storages.Main or "HS")

	local Found = {}
	local FoundDuplicates = {}

	local PlantFolder = GetFolderIn(MainFolder, Configuration.Storages.Plants or "P")
	local SeedsFolder = GetFolderIn(MainFolder, Configuration.Storages.Seeds or "S")
	local Duplicates

	if Configuration.Duplicates.StoreDuplicates then
		Duplicates = GetFolderIn(MainFolder, Configuration.Storages.Duplicates or "D")
	end

	local function ScanPlants()

		for _, Farm: Folder in pairs(workspace:FindFirstChild("Farm"):GetChildren()) do

			local FarmPlants: Folder = Farm:FindFirstChild("Important"):FindFirstChild("Plants_Physical")

			if FarmPlants then

				for _, Plant: Model in pairs(FarmPlants:GetChildren()) do

					if table.find(ScanFor, Plant.Name:lower()) then

						Plant:Clone().Parent = PlantFolder

						table.insert(Found, "PLANT | " .. Plant.Name)

						print(("FOUND PLANT: %*"):format(Plant.Name))

					end

				end

			else

				print("Farm has no plants???")

			end

		end

	end

	local function ScanSeeds()

		for _, Player: Player in pairs(Players:GetPlayers()) do

			local Backpack: Backpack = Player:FindFirstChild("Backpack")

			if Backpack then

				for _, Object in pairs(Backpack:GetChildren()) do

					for _, HuntFor in pairs(ScanFor) do

						if Object.Name:lower():find(HuntFor) and Object.Name:lower():find("seed") then

							local CleanName = CleanSeedName(Object.Name)

							if IsDuplicate(SeedsFolder, CleanName) and Configuration.Duplicates.StoreDuplicates and not Configuration.Duplicates.IgnoreDuplicates then

								ExtractSeedModel(Object).Parent = Duplicates

								table.insert(FoundDuplicates, CleanName)

								print(("%* appears to be a duplicate. Adding to duplicates."):format(CleanName))

								return

							end

							table.insert(Found, "SEED | " .. (CleanName or "???"))

							ExtractSeedModel(Object).Parent = SeedsFolder

							print(("FOUND SEED: %*"):format(HuntFor))

						end

					end

				end

			else

				print(("%* has no backpack???"):format(Player.Name))

			end

		end

	end
	
	if Configuration.ScanType == "Seed" then
		
		ScanSeeds()
		
	elseif Configuration.ScanType == "Plant" then
		
		ScanPlants()
		
	else
		
		ScanPlants()
		ScanSeeds()
		
	end

	return Found, FoundDuplicates

end

local function StartScan(List: {}, Configuration: {})

	assert(type(List) == "table", "Please provide a table with things you want to scan.")

	if Configuration.Automation.Auto or false then
		
		print("[Automation]: started.")

		local Break = false

		while task.wait(Configuration.Automation.ScanStep or 10) do
			
			print("[Automation]: scanning...")

			if Break then
				break
			end

			DisplayResults(
				ScanServer(
					ConvertStringsToLower(List, Configuration), Configuration
				)
			)

		end

		local ChatConnection

		ChatConnection = LocalPlayer.Chatted:Connect(function(Message: string)

			if Message:lower():find(Configuration.Automation.StopOnChat:lower() or "") then

				Break = true

				ChatConnection:Disconnect()
				
				print("[Automation]: stopped.")

			end

		end)

	else

		DisplayResults(
			ScanServer(
				ConvertStringsToLower(List, Configuration), Configuration
			)
		)

	end

end

return StartScan
