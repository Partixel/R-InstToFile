if game:GetService("RunService"):IsRunning() then return end

local CollectionService, HttpService, Selection = game:GetService("CollectionService"), game:GetService("HttpService"), game:GetService("Selection")

local CoroutineErrorHandling = require(game:GetService("ReplicatedStorage"):FindFirstChild("CoroutineErrorHandling") and game:GetService("ReplicatedStorage").CoroutineErrorHandling:FindFirstChild("MainModule") or game:GetService("ServerStorage"):FindFirstChild("CoroutineErrorHandling") and game:GetService("ServerStorage").CoroutineErrorHandling:FindFirstChild("MainModule") or 4851605998)

local Classes = HttpService:JSONDecode(HttpService:RequestAsync({Url = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Watch/roblox/API-Dump.json", Method = "GET"}).Body).Classes

local Properties = {}
local NoVal, NilVal = {}, {}

do
	local Superclass, ExcludedTags, ExcludedProperties = {}, {Deprecated = true, ReadOnly = true, Hidden = true}, {Parent = true, ClassName = true, Source = true, Name = true}
	
	local function InstanceNew(Class)
		return Instance.new(Class)
	end
	
	local function GetDefaultVal(Inst, Key)
		return Inst[Key] == nil and NilVal or Inst[Key]
	end
	
	for _, Class in ipairs(Classes) do
		local Props = {Archivable = true}
		
		local Inst
		local Ran, Val = pcall(InstanceNew, Class.Name)
		if Ran then
			Inst = Val
		end
		
		for _, Member in ipairs(Class.Members) do
			if not ExcludedProperties[Member.Name] and Member.MemberType == "Property" then
				local Ignore
				if Member.Tags then
					for _, Tag in ipairs(Member.Tags) do
						if ExcludedTags[Tag] then
							Ignore = true
							break
						end
					end
				end
				if not Ignore then
					if Inst then
						local Ran, Val = pcall(GetDefaultVal, Inst, Member.Name)
						if Ran then
							Props[Member.Name] = Val
						end
					else
						Props[Member.Name] = NoVal
					end
				end
			end
		end
		
		if Properties[Class.Superclass] then
			Superclass[Props] = Class.Superclass
			local Super = Properties[Class.Superclass]
			while Super do
				for a, b in pairs(Super) do
					if not Props[a] then
						if Inst then
							local Ran, Val = pcall(GetDefaultVal, Inst, a)
							if Ran then
								Props[a] = Val
							end
						else
							Props[a] = b
						end
					end
				end
				Super = Properties[Superclass[Super]]
			end
		elseif Class.Name ~= "Instance" then
			warn("No superclass for " .. Class.Name)
		end
		Properties[Class.Name] = Props
	end
end

for a, b in pairs(Properties) do
	local Props = {}
	for c, d in pairs(b) do
		Props[#Props + 1] = {c, d}
	end
	Properties[a] = Props
end

local Stringify = require(2789644632)
local SyncLocations = {game.ReplicatedStorage, game.ServerScriptService, game.ServerStorage, game.StarterGui, game.StarterPack, game.StarterPlayer}

local function GetRelativePath(Obj1, Obj2)
	
	local Ancestor = Obj1
	
	while not Obj2:IsDescendantOf(Ancestor) do
		
		Ancestor = Ancestor.Parent
		
	end
	
	local Str, Str2 = "Obj", ""
	
	local Par = Obj1
	
	while Par ~= Ancestor do
		
		Str = Str .. ".Parent"
		
		Par = Par.Parent
		
	end
	
	Par = Obj2
	
	while Par ~= Ancestor do
		
		Str2 = "[" .. Stringify(Par.Name) .. "]" .. Str2
		
		Par = Par.Parent
		
	end
	
	return Str .. Str2
	
end

local function GetUUID(Obj, Silent)
	local Tags = {}
	for _, Tag in ipairs(type(Obj) == "table" and Obj or CollectionService:GetTags(Obj)) do
		if Tag:sub(1, 4) == "I2F_" then
			Tags[#Tags + 1] = Tag
		end
	end
	
	for i, Tag in ipairs(Tags) do
		local Objs = CollectionService:GetTagged(Tag)
		if #Objs > 1 then
			if not Silent then
				warn(Obj, "has the same tag as other instances, removing: " .. Tag)
				for _, Inst in ipairs(Objs) do
					if Inst ~= Obj then
						warn("	" .. Inst:GetFullName())
					end
				end
			end
			CollectionService:RemoveTag(Obj, Tag)
			table.remove(Tags, i)
		end
	end
	
	for i = 2, #Tags do
		if not Silent then
			warn(Obj, "has multiple tags, removing: " .. Tags[i])
		end
		CollectionService:RemoveTag(Obj, Tags[i])
	end
	
	return Tags[1]
end

for _, Location in ipairs(SyncLocations) do
	Location.DescendantAdded:Connect(function(Obj)
		wait()
		pcall(GetUUID, Obj, true)
	end)
end



local function GetModifiedProperties(Obj, InstanceRefs)
	
	local Modified = {}
	
	local FoundInstances
	
	for _, Property in ipairs(Properties[Obj.ClassName]) do
		
		local Prop = Property[1]
		
		local Val = Obj[Prop]
		
		if typeof(Val) == "Instance" then
			
			FoundInstances = true
			
			InstanceRefs[Obj] = InstanceRefs[Obj] or {}
			
			InstanceRefs[Obj][Prop] = Val
			
		elseif Val ~= Property[2] and not (Val == nil and Property[2] == NilVal) then
			
			Modified[Prop] = Val
			
		end
		
	end
	
	if not GetUUID(Obj) then
		
		CollectionService:AddTag(Obj, "I2F_" .. HttpService:GenerateGUID(false))
		
	end
	
	Modified.Tags = CollectionService:GetTags(Obj)
	
	return Modified, FoundInstances
	
end

local function CreateFromProperties(Name, ClassName, Parent, Properties, ExistingObj)
	
	local Obj
	
	if ExistingObj and ExistingObj.ClassName == ClassName then
		
		Obj = ExistingObj
		
		local Clone = Obj:Clone()
		
		Clone:ClearAllChildren()
		
		for _, Kid in ipairs(Obj:GetChildren()) do
			
			Kid.Parent = Clone
			
		end
		
		Clone.Parent = Obj.Parent
		
	else
		
		Obj = Instance.new(ClassName)
		
	end
	
	Obj.Name = Name
	
	if Properties.Tags then
		
		for _, Tag in ipairs(Properties.Tags) do
			
			CollectionService:AddTag(Obj, Tag)
			
		end
		
		Properties.Tags = nil
		
	end
	
	for a, b in pairs(Properties) do
		
		Obj[a] = b
		
	end
	
	Obj.Parent = Parent
	
	return Obj
	
end

local function FindFirstChildOfNameAndClass(Parent, Name, ClassName)
	
	for _, Kid in ipairs(Parent:GetChildren()) do
		
		local Ran, Result = pcall(function() if Kid.Name == Name and Kid.ClassName == ClassName then
			
			return true
			
		end end)
		
		if Ran and Result then return Kid end
		
	end
	
end

local function GetNameClassAndType(Str)
	
	local LastDot = Str:match("^.*()%.")
	
	if LastDot then
		
		local Name, ClassName = Str:sub(1, LastDot - 1), Str:sub(LastDot + 1)
		
		if ClassName == "lua" or ClassName == "properties" then
			
			local Type = ClassName
			
			LastDot = Name:match("^.*()%.")
			
			if LastDot then
				
				Name, ClassName = Name:sub(1, LastDot - 1), Name:sub(LastDot + 1)
				
				return Name, ClassName, Type
				
			else
				
				return Name, Name, Type
				
			end
			
		else
			
			return Name, ClassName
			
		end
		
	else
		
		return Str, Str
		
	end
	
end

local function FromJSON(SyncTable, First)
	
	if First == nil then
		
		SyncTable = HttpService:JSONDecode(SyncTable)
		
	end
	
	for a, b in pairs(SyncTable) do
		
		if type(b) == "string" then
			
			local _, _, Type = GetNameClassAndType(a)
			
			if Type == "properties" then
				
				SyncTable[a] = loadstring("return " .. b)()
				
			end
			
		else
			
			FromJSON(b, false)
			
		end
		
	end
	
	if First == nil then
		
		return SyncTable
		
	end
	
end

local function ToJSON(SyncTable, First)
	
	for a, b in pairs(SyncTable) do
		
		local _, _, Type = GetNameClassAndType(a)
		
		if Type then
			
			if type(b) ~= "string" then
				
				local Str = "{"
				
				local Properties, InstanceRefs = b[1], b[2]
				
				if Properties then
					
					Str = Str .. "{"
					
					local Keys, Tags = {}, nil
					
					for a, b in pairs(Properties) do
						
						if a == "Tags" then
							
							table.sort(b)
							
							Tags = "Tags"
							
						else
							
							Keys[#Keys + 1] = a
							
						end
						
					end
					
					table.sort(Keys)
					
					Keys[#Keys + 1] = Tags
					
					for k, Key in ipairs(Keys) do
						
						Str = Str .. Key .. " = " .. Stringify(Properties[Key], nil, {Space = " ", Tab = "", SecondaryNewLine = "", NewLine = "", BeforeTable = false, AfterTable = false}) .. (k == #Keys and "" or ", ")
						
					end
					
					Str = Str .. "}" .. (InstanceRefs and ", " or "")
					
				end
				
				if InstanceRefs then
					
					Str = Str .. "{"
					
					local Keys = {}
					
					for a, _ in pairs(InstanceRefs) do
						
						Keys[#Keys + 1] = a
						
					end
					
					table.sort(Keys)
					
					for k, Key in ipairs(Keys) do
						
						Str = Str .. Key .. " = " .. Stringify(InstanceRefs[Key], nil, {Space = " ", Tab = "", SecondaryNewLine = "", NewLine = "", BeforeTable = false, AfterTable = false}) .. (k == #Keys and "" or ", ")
						
					end
					
					Str = Str .. "}"
					
				end
				
				Str = Str .. "}"
				
				SyncTable[a] = Str
				
			end
			
		else
			
			ToJSON(b, false)
			
		end
		
	end
	
	if First == nil then
		
		return next(SyncTable) and HttpService:JSONEncode(SyncTable) or false
		
	end
	
end

local function ReplaceObjs(Created, Parent)
	
	local UUID = GetUUID(Created)
	
	if UUID then
		
		local Found
		
		for _, Match in ipairs(CollectionService:GetTagged(UUID)) do
			
			if Match ~= Created then
				
				Found = Match.Parent
				
				Match:Destroy()
				
			end
			
		end
		
		if Parent then
			
			Created.Parent = Parent
			
		elseif Found then
			
			Created.Parent = Found
			
		else
			
			Created.Parent = game:GetService("ReplicatedStorage")
			
			warn("Could not find the parent of " .. Created:GetFullName() .. " so it has been placed in game." .. game:GetService("ReplicatedStorage").Name)
			
		end
		
	else
		
		Parent = Parent and FindFirstChildOfNameAndClass(Parent, GetNameClassAndType(Created.Name)) or game
		
		if Parent then
			
			for _, Kid in ipairs(Created:GetChildren()) do
				
				ReplaceObjs(Kid, Parent)
				
			end
			
		else
			
			warn("Could not sync from " .. Created:GetFullName() .. "because parent does not exist")
			
		end
		
	end
	
end

local function CreateObjs(Parent, Table, InstanceRefs, Objs)
	
	local First = InstanceRefs == nil
	
	local Sel, OriginalParent
	
	if First then
		
		OriginalParent = Parent
		
		Parent = Instance.new("Folder")
		
		Parent.Name = OriginalParent.Name
		
		Parent.Parent = game.ReplicatedStorage
		
		Table = FromJSON(Table)
		
		Sel = game:GetService("Selection"):Get()
		
		for k, v in ipairs(Sel) do
			
			Sel[k] = GetUUID(v) or v
			
		end
		
	end
	
	InstanceRefs = InstanceRefs or {}
	
	Objs = Objs or {}
	
	local Rename = {}
	
	local Created = {}
	
	local Folders, Scripts = {}, {}
	
	for a, b in pairs(Table) do
		
		local Name, ClassName, Type = GetNameClassAndType(a)
		
		local Key = Name == ClassName and Name or Name .. "." .. ClassName
		
		local Num = ClassName:find("%%")
		
		local UUID
		
		if Num then
			
			ClassName, UUID = ClassName:sub(1, Num - 1), ClassName:sub(Num + 1)
			
		end
		
		if not Type then
			
			Folders[#Folders + 1] = {Key, Name, ClassName, b}
			
		elseif Type == "properties" then
			
			UUID = UUID or GetUUID(b[1].Tags)
			
			local Obj = CreateFromProperties(Name, ClassName, Parent, b[1] or {}, CollectionService:GetTagged(UUID)[1])
			
			Objs[Obj] = Key
			
			InstanceRefs[Obj] = b[2]
			
			Created[Key] = Obj
			
		else
			
			Scripts[#Scripts + 1] = {Key, Name, ClassName, b}
			
		end
		
	end
	
	for _, ScriptInfo in ipairs(Scripts) do
		
		local Script = Created[ScriptInfo[1]] or Instance.new(ScriptInfo[3])
		
		Script.Name = ScriptInfo[2]
		
		Script.Source = ScriptInfo[4]
		
		Script.Parent = Parent
		
		Objs[Script] = ScriptInfo[1]
		
		Created[ScriptInfo[1]] = Script
		
		
	end
	
	for a, b in pairs(Folders) do
		
		local Obj = Created[b[1]]
		
		if not Obj then
			
			Obj = Instance.new("Folder", Parent)
			
			Obj.Name = b[2] .. "." .. b[3]
			
		end
		
		if Obj then
			
			CreateObjs(Obj, b[4], InstanceRefs, Objs)
			
		else
			
			warn(Parent:GetFullName() .. "  -  " .. b[2] .. "  -  " .. b[3] .. " does not exist, cannot sync!\nPlease ensure it is tagged as 'ForceSync' if you wish it to sync OR ensure it exists so its scripts may sync")
			
		end
		
	end
	
	if First then
		
		for a, b in pairs(InstanceRefs) do
			
			for c, d in pairs(b) do
				
				if type(d) == "string" then
					
					local Ran, Error = pcall(function()
						
						a[c] = loadstring(d)(a)
						
					end)
					
					if a[c] then
						
						local Found
						
						for _, Kid in ipairs(a[c].Parent:GetChildren()) do
							
							if Kid.Name == a[c].Name then
								
								if Found then warn(a:GetFullName() .. "." .. c .. " may not have synced correctly as multiple objects with the same name exist!") break end
								
							end
							
						end
						
					else
						
						warn(a:GetFullName() .. " failed to sync it's " .. c .. "'s instance reference:\n" .. Error)
						
					end
					
				else
					
					for e, f in pairs(Objs) do
						
						local Par = e
						
						local Failed
						
						for g = #d, 1, -1 do
							
							if d[g] == Objs[Par] then
								
								Par = Par.Parent
								
							else
								
								Failed = true
								
								break
								
							end
							
						end
						
						if Objs[Par.Parent] then Failed = true end
						
						if not Failed then
							
							a[c] = e
							
							break
							
						end
						
					end
					
					if not a[c] then
						
						warn("Was unable to sync " .. a:GetFullName() .. "'s " .. c)
						
					end
					
				end
				
			end
			
		end
		
		ReplaceObjs(Parent, OriginalParent ~= game and OriginalParent or nil)
		
		Parent:Destroy()
		
		for k, v in ipairs(Sel) do
			
			if type(v) == "string" then
				
				Sel[k] = CollectionService:GetTagged(v)[1]
				
			end
			
		end
		
		Selection:Set(Sel)
		
		for _, v in ipairs(Sel) do
			
			local Old = v.Parent
			
			v.Parent = game:GetService("ReplicatedStorage")
			
			v.Parent = Old
			
		end
		
		Selection:Set(Sel)
		
	end
	
end

local ExcludedClasses = {MeshPart = true, UnionOperation = true}

local function SyncObjs(Model, SyncTable, Sync, InstanceRefs, Objs, Dupes)
	
	if CollectionService:HasTag(Model, "ForceNoSync") then
		
		return
		
	end
	
	for a, b in pairs(ExcludedClasses) do
		
		if Model:IsA(a) then
			
			warn("Failed to sync " .. Model:GetFullName() .. " - " .. Model.ClassName .. " cannot be recreated")
			
			return
					
		end
		
	end
	
	local First = InstanceRefs == nil
	
	Objs = Objs or {}
	
	InstanceRefs = InstanceRefs or {}
	
	Sync = Sync or CollectionService:HasTag(Model, "ForceSync") or Model:IsA("LuaSourceContainer")
	
	local MySyncTable = {}
	
	local Num
	
	if Sync then
		
		local Ran, Error = xpcall(function()
			
			local Modified, FoundInstances = GetModifiedProperties(Model, InstanceRefs)
			
			if Dupes[tostring(Model)] > 1 then
				
				Num = GetUUID(Model)
				
			end
			
			if Model:IsA("LuaSourceContainer") then
				
				SyncTable[(Model.Name == Model.ClassName and Model.Name or Model.Name .. "." .. Model.ClassName) .. (Num and "%" .. Num or "") .. ".lua"] = Model.Source
				
			end
			
			if Num then
				
				for k, Tag in ipairs(Modified.Tags) do
					
					if Tag:sub(1, 4) == "I2F_" then
						
						Modified.Tags[k] = Modified[#Modified]
						
						Modified.Tags[#Modified] = nil
						
						if #Modified.Tags == 0 then
							
							Modified.Tags = nil
							
							if not next(Modified) then
								
								Modified = nil
								
							end
							
						end
						
						break
						
					end
					
				end
				
			end
			
			if type(Modified) == "string" then return Modified end
			
			Objs[Model] = {(Model.Name == Model.ClassName and Model.Name or Model.Name .. "." .. Model.ClassName) .. (Num and "%" .. Num or "")}
			
			if not Model:IsA("LuaSourceContainer") or Modified or FoundInstances then
				
				local Properties = {Modified}
				
				Objs[Model][2] = Properties
				
				SyncTable[(Model.Name == Model.ClassName and Model.Name or Model.Name .. "." .. Model.ClassName) .. (Num and "%" .. Num or "") .. ".properties"] = Properties
				
				
			end
			
		end, CoroutineErrorHandling.ErrorHandler)
		
		if not Ran then
			warn(CoroutineErrorHandling.GetError(Error))
		elseif Error then
			warn(Error)
		end
		
	end
		
	local Kids = Model == game and SyncLocations or Model:GetChildren()
	
	local Dupes = {}
	
	for _, Kid in ipairs(Kids) do
		
		if not CollectionService:HasTag(Kid, "ForceNoSync") and (Sync or CollectionService:HasTag(Kid, "ForceSync") or Kid:IsA("LuaSourceContainer")) then
			
			Dupes[tostring(Kid)] = (Dupes[tostring(Kid)] or 0) + 1
			
		end
		
	end
	
	for _, Kid in ipairs(Kids) do
		
		SyncObjs(Kid, MySyncTable, Sync, InstanceRefs, Objs, Dupes)
		
	end
	
	if next(MySyncTable) then
		
		SyncTable[(Model.Name == Model.ClassName and Model.Name or Model.Name .. "." .. Model.ClassName) .. (Num and "%" .. Num or "")] = MySyncTable
		
	end
	
	if First then
		
		for a, b in pairs(InstanceRefs) do
			
			for c, d in pairs(b) do
				
				local Path = {}
				
				local Par = d
				
				while Objs[Par] do
					
					table.insert(Path, 1, Objs[Par][1])
					
					Par = Par.Parent
					
				end
				
				if #Path == 0 then
					
					warn(a:GetFullName() .. " is using a fuzzy reference in the " .. c .. " property, may cause issues if multiple objects within it's parent have the same name")
					
					Objs[a][2][2] = Objs[a][2][2] or {}
					
					Objs[a][2][2][c] = "local Obj = ... return " .. GetRelativePath(a, d)
					
				else
					
					Objs[a][2][2] = Objs[a][2][2] or {}
					
					Objs[a][2][2][c] = Path
					
				end
				
			end
			
		end
		
		return ToJSON(SyncTable)
		
	end
	
end

local Toolbar = plugin:CreateToolbar("InstToFile")

local CurrentSync

local I2F = Toolbar:CreateButton("Export", "Export from Roblox to Windows", "")

local F2I = Toolbar:CreateButton("Import", "Import from Windows to Roblox", "")

I2F.ClickableWhenViewportHidden = true

F2I.ClickableWhenViewportHidden = true

local Connected

local PlaceId = game:GetService("ServerStorage"):FindFirstChild("Inst2File_PlaceId") and game:GetService("ServerStorage")["Inst2File_PlaceId"].Value or game.PlaceId

for a = 1, 2 do
	
	local Button = a == 1 and I2F or F2I
	
	local Syncing
	
	Button.Click:Connect(function()
		
		if not Syncing then
			
			local Mine = {}
			
			CurrentSync = Mine
			
			Syncing = true
			
			Button:SetActive(true)
			
			local json = a == 1 and SyncObjs(game, {}) or nil
			
			if a == 1 and json == false then print("[InstToFile] Nothing to sync") return end
			
			print("[InstToFile] Connecting to local server")
			
			while CurrentSync == Mine do
				
				local Ran, Error = pcall(function()
					
					return game.HttpService:GetAsync("http://localhost:8888")
					
				end)
				
				if not Ran or Error ~= "active" then
					
					if Connected then
						
						Error = Error:lower()
						
						if Error:find("error") and not Error:find("timeout") then
							
							print(Error)
							
							wait(1)
							
						end
						
						Connected = nil
						
					end
					
				else
					
					Connected = true
					
					print("[InstToFile] Syncing to " .. (a == 1 and "Files" or "Instances"))
					
					if CurrentSync ~= Mine then break end
					
					local Ran, Error = pcall(function()
						
						if a == 1 then
							
							local Ran, Error = pcall(function() return HttpService:RequestAsync{Url = "http://localhost:8888/?placeid=" .. PlaceId, Body = json, Method = "POST"} end)
							
							if not Ran then error(Error) end
							
							if not Error.Success then error(Error.StatusMessage) end
							
							return Error.Body
							
						else
							
							local Ran, Error = pcall(function() return HttpService:RequestAsync{Url = "http://localhost:8888/?placeid=" .. (game:GetService("ReplicatedStorage"):FindFirstChild("SyncPlaceId") and game:GetService("ReplicatedStorage"):FindFirstChild("SyncPlaceId").Value or PlaceId) .. "\\", Method = "GET"} end)
							
							if not Ran then error(Error) end
							
							if not Error.Success then error(Error.StatusMessage) end
							
							return Error.Body
							
						end
						
					end)
					
					if Ran and ((a == 1 and Error == "synced") or (a == 2 and Error:sub(1, 6) ~= "failed")) then
						
						if a == 2 then
							
							local Ran, Error = xpcall(CreateObjs, CoroutineErrorHandling.ErrorHandler, game, Error)
							
							if Ran then
								
								print("[InstToFile] Successfully synced")
								
								CurrentSync = nil
								
								Button:SetActive(false)
								
								Syncing = nil
								
								return
								
							else
								
								print("[InstToFile] Error occured when syncing - " .. CoroutineErrorHandling.GetError(Error))
								
								break
								
							end
							
						else
							
							print("[InstToFile] Successfully synced")
							
							CurrentSync = nil
							
							Button:SetActive(false)
							
							Syncing = nil
							
							return
							
						end
						
					else
						
						print("[InstToFile] Error occured when syncing - " .. Error:sub(8))
						
						break
						
					end
					
				end
				
				wait(0.1)
				
			end
			
			Syncing = nil
			
			Button:SetActive(false)
			
		else
			
			CurrentSync = nil
			
			Syncing = nil
			
			I2F:SetActive(false)
			
			F2I:SetActive(false)
			
			print("[InstToFile] Stopped syncing")
			
		end
		
	end)
	
end