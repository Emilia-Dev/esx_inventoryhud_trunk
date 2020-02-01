ESX = nil
local GUI = {}
local PlayerData = {}
local lastVehicle = nil
local lastOpen = false
GUI.Time = 0
local vehiclePlate = {}
local arrayWeight = Config.localWeight
local CloseToVehicle = false
local entityWorld = nil
local globalplate = nil
local lastChecked = 0

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,["-"] = 84,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

Citizen.CreateThread(
     function()
          while ESX == nil do
               TriggerEvent(
                    "esx:getSharedObject",
                    function(obj)
                         ESX = obj
                    end
               )
               Citizen.Wait(0)
          end
     end
)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler(
     "esx:playerLoaded",
     function(xPlayer)
          PlayerData = xPlayer
          TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
          lastChecked = GetGameTimer()
     end
)

AddEventHandler(
     "onResourceStart",
     function()
          PlayerData = xPlayer
          TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
          lastChecked = GetGameTimer()
     end
)

RegisterNetEvent("esx:setJob")
AddEventHandler(
     "esx:setJob",
     function(job)
          PlayerData.job = job
     end
)

RegisterNetEvent("esx_trunk_inventory:setOwnedVehicule")
AddEventHandler(
     "esx_trunk_inventory:setOwnedVehicule",
     function(vehicle)
          vehiclePlate = vehicle
          --print("vehiclePlate: ", ESX.DumpTable(vehiclePlate))
     end
)

function getItemyWeight(item)
     local weight = 0
     local itemWeight = 0
     if item ~= nil then
          itemWeight = Config.DefaultWeight
          if arrayWeight[item] ~= nil then
               itemWeight = arrayWeight[item]
          end
     end
     return itemWeight
end

function VehicleInFront()
     local pos = GetEntityCoords(GetPlayerPed(-1))
     local entityWorld = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, 4.0, 0.0)
     local rayHandle =
          CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, GetPlayerPed(-1), 0)
     local a, b, c, d, result = GetRaycastResult(rayHandle)
     return result
end

function OpenMenuVehicle()
     local playerPed = GetPlayerPed(-1)
     local coords = GetEntityCoords(playerPed)
     local vehicle = VehicleInFront()
     globalplate = GetVehicleNumberPlateText(vehicle)

     myVeh = false
     local thisVeh = VehicleInFront()
     PlayerData = ESX.GetPlayerData()
     for i = 1, #vehiclePlate do
          local vPlate = all_trim(vehiclePlate[i].plate)
          local vFront = all_trim(GetVehicleNumberPlateText(thisVeh))
          --print('vPlate: ',vPlate)
          --print('vFront: ',vFront)
          --if vehiclePlate[i].plate == GetVehicleNumberPlateText(vehFront) then
          if vPlate == vFront then
               myVeh = true
          elseif lastChecked < GetGameTimer() - 60000 then
               TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
               lastChecked = GetGameTimer()
               Wait(2000)
               for i = 1, #vehiclePlate do
                    local vPlate = all_trim(vehiclePlate[i].plate)
                    local vFront = all_trim(GetVehicleNumberPlateText(thisVeh))
                    if vPlate == vFront then
                         myVeh = true
                    end
               end
          end
     end

     if not Config.CheckOwnership or (Config.AllowPolice and PlayerData.job.name == "police") or (Config.CheckOwnership and myVeh) then
          if globalplate ~= nil or globalplate ~= "" or globalplate ~= " " then
               --HolfzCanFixThis
		
               --First : Check if this plate already open ?
               ESX.TriggerServerCallback('holfz_trunk:checkvehicle',function(isBusy)
                    --If not open. Then sure! open for him
                    if not isBusy then
                         CloseToVehicle = true
                         local vehFront = VehicleInFront()
                         local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
                         local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 71)
						 
                         if vehFront > 0 and closecar ~= nil and GetPedInVehicleSeat(closecar, -1) ~= GetPlayerPed(-1) then
                              lastVehicle = vehFront
                              local model = GetDisplayNameFromVehicleModel(GetEntityModel(closecar))
                              local locked = GetVehicleDoorLockStatus(closecar)
                              local class = GetVehicleClass(vehFront)
                              ESX.UI.Menu.CloseAll()
          
                              if ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), "inventory") then
                                   --SetVehicleDoorShut(vehFront, 5, false)
                              else
                                   local isopen = GetVehicleDoorAngleRatio(vehicle, 5)
                                   if locked == 1 or model == "CARNOTFOUND" or IsPedHuman(vehicle) then
                                        if isopen ~= 0 then
											SetVehicleDoorOpen(vehFront, 5, false, false)
											ESX.UI.Menu.CloseAll()
          
                                             if globalplate ~= nil or globalplate ~= "" or globalplate ~= " " then
                                                  CloseToVehicle = true
												  TriggerServerEvent('holfz_trunk:AddVehicleList', globalplate)
												  lastOpen = true
                                                  TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
                                                  OpenCoffreInventoryMenu(
                                                       GetVehicleNumberPlateText(vehFront),
                                                       Config.VehicleLimit[class],
                                                       myVeh
                                                  )
                                             end
                                        elseif isopen == 0 and model ~= "CARNOTFOUND" then
                                             exports.pNotify:SendNotification(
                                                  {
                                                       text = "ต้องเปิดท้ายยานพาหนะก่อน",
                                                       type = "error",
                                                       timeout = 3000,
                                                       layout = "bottomCenter",
                                                       queue = "trunk"
                                                  }
                                             )
                                        end
                                   else
                                        exports.pNotify:SendNotification(
                                             {
                                                  text = _U("trunk_closed"),
                                                  type = "error",
                                                  timeout = 3000,
                                                  layout = "bottomCenter",
                                                  queue = "trunk"
                                             }
                                        )
                                   end
                              end
                         else
                              exports.pNotify:SendNotification(
                                   {
                                        text = _U("no_veh_nearby"),
                                        type = "error",
                                        timeout = 3000,
                                        layout = "bottomCenter",
                                        queue = "trunk"
                                   }
                              )
                         end
                         GUI.Time = GetGameTimer()
                    else -- If already open. Not open for him!.. Is player doing something bad ?
                         exports.pNotify:SendNotification(
                           {
                              text = _U("trunk_in_use"),
                              type = "error",
                              timeout = 3000,
                              layout = "bottomCenter",
                              queue = "trunk"
                           }
                         )
						return
                    end
               end, globalplate)
          end
     else
     --[[ Not their vehicle
     exports.pNotify:SendNotification(
          {
          text = _U("nacho_veh"),
          type = "error",
          timeout = 3000,
          layout = "bottomCenter",
          queue = "trunk"
          }
     )]]
     end
end
local count = 0

-- Key controls

-- Holfz : Old code sucks. Let me f**king (sorry for that) edit it
--Citizen.CreateThread(
  --function()
		--while true do
			--Wait(0)
			--if IsControlJustReleased(0, Config.OpenKey) and (GetGameTimer() - GUI.Time) > 1000 then
				--OpenMenuVehicle()
				--GUI.Time = GetGameTimer()
			--end
		--end
	--end
--)

Citizen.CreateThread(function()
	while true do
		Wait(0)
		if IsControlPressed(0, Keys["L"]) and (GetGameTimer() - GUI.Time) > 1000 then
			if count == 0 then
				OpenMenuVehicle()
				count = count + 1
			else
				Citizen.Wait(2000)
				count = 0
			end
		elseif lastOpen and IsControlPressed(0, 322) or IsControlPressed(0, Keys["X"]) then
               ClearPedTasks(PlayerPedId())
			--TriggerEvent("chatMessage", "[Debug]", {255,0,0}, "closed")
			vehicleNearby = false
			lastOpen = false
			ESX.UI.Menu.CloseAll()
			if lastVehicle > 0 then
				--SetVehicleDoorShut(lastVehicle, 5, false)
				local lastvehicleplatetext = GetVehicleNumberPlateText(lastVehicle)
				TriggerServerEvent('holfz_trunk:RemoveVehicleList', lastvehicleplatetext)
				lastVehicle = 0
			end
			GUI.Time = GetGameTimer()
		end	
	end
end)

Citizen.CreateThread(
     function()
          while true do
               Wait(0)
               local pos = GetEntityCoords(GetPlayerPed(-1))
               if CloseToVehicle then
                    local vehicle = GetClosestVehicle(pos["x"], pos["y"], pos["z"], 2.0, 0, 70)
                    if DoesEntityExist(vehicle) then
                         CloseToVehicle = true
                    else
                         --SetVehicleDoorShut(lastVehicle, 5, false)
                         CloseToVehicle = false
                         --lastOpen = false
                         ESX.UI.Menu.CloseAll()
                    end
               end
          end
     end
)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler(
     "esx:playerLoaded",
     function(xPlayer)
          PlayerData = xPlayer
          TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
          lastChecked = GetGameTimer()
     end
)

function OpenCoffreInventoryMenu(plate, max, myVeh)
     ESX.TriggerServerCallback(
          "esx_trunk:getInventoryV",
          function(inventory)
               text = _U("trunk_info", plate, (inventory.weight / 1000), (max / 1000))
               data = {plate = plate, max = max, myVeh = myVeh, text = text}
               TriggerEvent(
                    "esx_inventoryhud:openTrunkInventory",
                    data,
                    inventory.blackMoney,
                    inventory.items,
                    inventory.weapons
               )
          end,
          plate
     )
end

function all_trim(s)
     if s then
          return s:match "^%s*(.*)":match "(.-)%s*$"
     else
          return "noTagProvided"
     end
end

function dump(o)
     if type(o) == "table" then
          local s = "{ "
          for k, v in pairs(o) do
               if type(k) ~= "number" then
                    k = '"' .. k .. '"'
               end
               s = s .. "[" .. k .. "] = " .. dump(v) .. ","
          end
          return s .. "} "
     else
          return tostring(o)
     end
end
