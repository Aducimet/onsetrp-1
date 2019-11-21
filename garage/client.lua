
local garageDealer
local GarageDealerIds = { }

function OnPackageStart()
	garageDealer = CreateWebUI(800.0, 200.0, 700.0, 450.0, 5, 10)
	LoadWebFile(garageDealer, "http://asset/"..GetPackageName().."/client/garage/garage.html")
	SetWebAlignment(garageDealer, 0.0, 0.0)
	SetWebAnchors(garageDealer, 0.0, 0.0, 1.0, 1.0)
    SetWebVisibility(garageDealer, WEB_HIDDEN)
end
AddEvent("OnPackageStart", OnPackageStart)

function OnPackageStop()
	DestroyWebUI(garageDealer)
end
AddEvent("OnPackageStop", OnPackageStop)

function OnKeyPress(key)
    if key == "E" then
        local NearestGarageDealer = GetNearestGarageDealer()
        if NearestGarageDealer ~= 0 then 
            CallRemoteEvent("garageDealerInteract", NearestGarageDealer)       
		end
	end
end
AddEvent("OnKeyPress", OnKeyPress)

AddRemoteEvent("garageDealerSetup", function(GarageDealerObject)
    GarageDealerIds = GarageDealerObject
end)


function GetNearestGarageDealer()
    local x, y, z = GetPlayerLocation()
	for k,v in pairs(GetStreamedNPC()) do
        local x2, y2, z2 = GetNPCLocation(v)
        local dist = GetDistance3D(x, y, z, x2, y2, z2)
		if dist < 150.0 then
            for k,i in pairs(GarageDealerIds) do
				if v == i then
					return v
				end
			end
		end
	end

	return 0
end

function tablefind(tab, el)
	for index, value in pairs(tab) do
		if value == el then
			return index
		end
	end
end

function openGarageDealer()
    ShowMouseCursor(true)
    SetInputMode(INPUT_UI)
    SetWebVisibility(garageDealer, WEB_VISIBLE)
    isGarageDealer = not isGarageDealer
    CallRemoteEvent("sendGarageList")

end
AddRemoteEvent("openGarageDealer", openGarageDealer)

function clearGarageList()
    ExecuteWebJS(garageDealer, 'clearGarage();')
end
AddRemoteEvent("clearGarageList", clearGarageList)

function getGarageList(id, name, price, color)
        ExecuteWebJS(garageDealer, 'addGarageList( "'..id..'", "'..name..'", "'..price..'", "'..color..'");')
end
AddRemoteEvent("getGarageList", getGarageList)

function closeGarageDealer()
    ShowMouseCursor(false)
    SetInputMode(INPUT_GAME)
    SetWebVisibility(garageDealer, WEB_HIDDEN)
    isGarageDealer = not isGarageDealer
end
AddEvent("closeGarageDealer", closeGarageDealer)
AddRemoteEvent("closeGarageDealer", closeGarageDealer)

function spawnCar(id)
    local id = tostring(id)

    if id == 'nil' then
        AddPlayerChat("Please select a car to spawn !")
    else
        CallRemoteEvent("spawnCarServer", id)
    end
end
AddEvent("spawnCar", spawnCar)

function sellCar(id)
    local id = tostring(id)

    if id == 'nil' then
        AddPlayerChat("Please select a car to sell !")
    else
        CallRemoteEvent("sellCarServer", id)
    end
end
AddEvent("sellCar", sellCar)