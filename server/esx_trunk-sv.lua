ESX = nil
local arrayWeight = Config.localWeight
local HolfzVehicleList = {}
local VehicleInventory = {}

TriggerEvent(
  "esx:getSharedObject",
  function(obj)
    ESX = obj
  end
)

AddEventHandler(
  "onMySQLReady",
  function()
    MySQL.Async.execute("DELETE FROM `trunk_inventory` WHERE `owned` = 0", {})
  end
)

ESX.RegisterServerCallback('holfz_trunk:checkvehicle',function(source,cb, vehicleplate)
	local isFound = false
	local _source = source
	local plate = vehicleplate
	if plate ~= " " or plate ~= nil or plate ~= "" then
		for _,v in pairs(HolfzVehicleList) do
			if(plate == v.vehicleplate) then
				isFound = true
				break
			end	
		end
	else
		isFound = true
	end
	cb(isFound)
end)

RegisterServerEvent('holfz_trunk:AddVehicleList')
AddEventHandler('holfz_trunk:AddVehicleList', function(plate)
	local plateisfound = false
	for _,v in pairs(HolfzVehicleList) do
		if(plate == v.vehicleplate) then
			plateisfound = true
			break
		end		
	end
	if not plateisfound then
		table.insert(HolfzVehicleList, {vehicleplate = plate})
	end
end)

RegisterServerEvent('holfz_trunk:RemoveVehicleList')
AddEventHandler('holfz_trunk:RemoveVehicleList', function(plate)
	for i=1, #HolfzVehicleList, 1 do
		--print(HolfzVehicleList[i].vehicleplate)
		if HolfzVehicleList[i].vehicleplate == plate then
			if HolfzVehicleList[i].vehicleplate ~= " " or plate ~= " " or HolfzVehicleList[i].vehicleplate ~= nil or plate ~= nil or HolfzVehicleList[i].vehicleplate ~= "" or plate ~= "" then
				table.remove(HolfzVehicleList, i)
				break
			end
		end
	end
end)

RegisterServerEvent("esx_trunk_inventory:getOwnedVehicule")
AddEventHandler(
  "esx_trunk_inventory:getOwnedVehicule",
  function()
    local vehicules = {}
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    MySQL.Async.fetchAll(
      "SELECT * FROM owned_vehicles WHERE owner = @owner",
      {
        ["@owner"] = xPlayer.identifier
      },
      function(result)
        if result ~= nil and #result > 0 then
          for _, v in pairs(result) do
            local vehicle = json.decode(v.vehicle)
            table.insert(vehicules, {plate = vehicle.plate})
          end
        end
        TriggerClientEvent("esx_trunk_inventory:setOwnedVehicule", _source, vehicules)
      end
    )
  end
)


function getItemWeight(item)
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

function getInventoryWeight(inventory)
  local weight = 0
  local itemWeight = 0
  if inventory ~= nil then
    for i = 1, #inventory, 1 do
      if inventory[i] ~= nil then
        itemWeight = Config.DefaultWeight
        if arrayWeight[inventory[i].name] ~= nil then
          itemWeight = arrayWeight[inventory[i].name]
        end
        weight = weight + (itemWeight * (inventory[i].count or 1))
      end
    end
  end
  return weight
end

function getTotalInventoryWeight(plate)
  local total
  TriggerEvent(
    "esx_trunk:getSharedDataStore",
    plate,
    function(store)
      local W_weapons = getInventoryWeight(store.get("weapons") or {})
      local W_coffre = getInventoryWeight(store.get("coffre") or {})
      local W_blackMoney = 0
      local blackAccount = (store.get("black_money")) or 0
      if blackAccount ~= 0 then
        W_blackMoney = blackAccount[1].amount / 10
      end
      total = W_weapons + W_coffre + W_blackMoney
    end
  )
  return total
end

AddEventHandler('serverlog', function(text)
	local gt = os.date('*t')
	local f,err = io.open("serverlog.log","a")
	if not f then return print(err) end
	local h = gt['hour'] if h < 10 then h = "0"..h end
	local m = gt['min'] if m < 10 then m = "0"..m end
	local s = gt['sec'] if s < 10 then s = "0"..s end
	local formattedlog = string.format("[%s:%s:%s] %s \n",h,m,s,text)
	f:write(formattedlog)
	f:close()
	-- uncomment line below, if you need (to show all logs in console also)
	print(formattedlog)
end)

ESX.RegisterServerCallback(
  "esx_trunk:getInventoryV",
  function(source, cb, plate)
    TriggerEvent(
      "esx_trunk:getSharedDataStore",
      plate,
      function(store)
        local blackMoney = 0
        local items = {}
        local weapons = {}
        weapons = (store.get("weapons") or {})

        local blackAccount = (store.get("black_money")) or 0
        if blackAccount ~= 0 then
          blackMoney = blackAccount[1].amount
        end

        local coffre = (store.get("coffre") or {})
        for i = 1, #coffre, 1 do
          table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
        end

        local weight = getTotalInventoryWeight(plate)
        cb(
          {
            blackMoney = blackMoney,
            items = items,
            weapons = weapons,
            weight = weight
          }
        )
      end
    )
  end
)

RegisterServerEvent("esx_trunk:getItem")
AddEventHandler(
  "esx_trunk:getItem",
  function(plate, type, item, count, max, owned)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if type == "item_standard" then
      TriggerEvent(
        "esx_trunk:getSharedDataStore",
        plate,
        function(store)
          local coffre = (store.get("coffre") or {})
          for i = 1, #coffre, 1 do
            if coffre[i].name == item then
              if (coffre[i].count >= count and count > 0) then
                xPlayer.addInventoryItem(item, count)
                if (coffre[i].count - count) == 0 then
                  table.remove(coffre, i)
                else
                  coffre[i].count = coffre[i].count - count
                end

                break
              else
                TriggerClientEvent(
                  "pNotify:SendNotification",
                  _source,
                  {
                    text = _U("invalid_quantity"),
                    type = "error",
                    queue = "trunk",
                    timeout = 3000,
                    layout = "bottomCenter"
                  }
                )
              end
            end
          end

          store.set("coffre", coffre)

          local blackMoney = 0
          local items = {}
          local weapons = {}
          weapons = (store.get("weapons") or {})

          local blackAccount = (store.get("black_money")) or 0
          if blackAccount ~= 0 then
            blackMoney = blackAccount[1].amount
          end

          local coffre = (store.get("coffre") or {})
          for i = 1, #coffre, 1 do
            table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
          end

          local weight = getTotalInventoryWeight(plate)

          text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
          data = {plate = plate, max = max, myVeh = owned, text = text}
          TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
        end
      )
    end

    if type == "item_account" then
      TriggerEvent(
        "esx_trunk:getSharedDataStore",
        plate,
        function(store)
          local blackMoney = store.get("black_money")
		  
          if (blackMoney[1].amount >= count and count > 0) then
            blackMoney[1].amount = blackMoney[1].amount - count
            store.set("black_money", blackMoney)
            xPlayer.addAccountMoney(item, count)

            local blackMoney = 0
            local items = {}
            local weapons = {}
            weapons = (store.get("weapons") or {})

            local blackAccount = (store.get("black_money")) or 0
            if blackAccount ~= 0 then
              blackMoney = blackAccount[1].amount
            end

            local coffre = (store.get("coffre") or {})
            for i = 1, #coffre, 1 do
              table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
            end

            local weight = getTotalInventoryWeight(plate)

            text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
            data = {plate = plate, max = max, myVeh = owned, text = text}
            TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
          else
            TriggerClientEvent(
              "pNotify:SendNotification",
              _source,
              {
                text = _U("invalid_amount"),
                type = "error",
                queue = "trunk",
                timeout = 3000,
                layout = "bottomCenter"
              }
            )
          end
        end
      )
    end

    if type == "item_weapon" then
      TriggerEvent(
        "esx_trunk:getSharedDataStore",
        plate,
        function(store)
          local storeWeapons = store.get("weapons")

          if storeWeapons == nil then
            storeWeapons = {}
          end

          local weaponName = nil
          local ammo = nil

          for i = 1, #storeWeapons, 1 do
            if storeWeapons[i].name == item then
              weaponName = storeWeapons[i].name
              ammo = storeWeapons[i].ammo

              table.remove(storeWeapons, i)

              break
            end
          end

          store.set("weapons", storeWeapons)

          xPlayer.addWeapon(weaponName, ammo)

          local blackMoney = 0
          local items = {}
          local weapons = {}
          weapons = (store.get("weapons") or {})

          local blackAccount = (store.get("black_money")) or 0
          if blackAccount ~= 0 then
            blackMoney = blackAccount[1].amount
          end

          local coffre = (store.get("coffre") or {})
          for i = 1, #coffre, 1 do
            table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
          end

          local weight = getTotalInventoryWeight(plate)

          text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
          data = {plate = plate, max = max, myVeh = owned, text = text}
          TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
        end
      )
    end
  end
)

RegisterServerEvent("esx_trunk:putItem")
AddEventHandler(
  "esx_trunk:putItem",
  function(plate, type, item, count, max, owned, label)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xPlayerOwner = ESX.GetPlayerFromIdentifier(owner)

    if type == "item_standard" then
      local playerItemCount = xPlayer.getInventoryItem(item).count

      if (playerItemCount >= count and count > 0) then
        TriggerEvent(
          "esx_trunk:getSharedDataStore",
          plate,
          function(store)
            local found = false
            local coffre = (store.get("coffre") or {})

            for i = 1, #coffre, 1 do
              if coffre[i].name == item then
                coffre[i].count = coffre[i].count + count
                found = true
              end
            end
            if not found then
              table.insert(
                coffre,
                {
                  name = item,
                  count = count
                }
              )
            end
            if (getTotalInventoryWeight(plate) + (getItemWeight(item) * count)) > max then
              TriggerClientEvent(
                "pNotify:SendNotification",
                _source,
                {
                  text = _U("insufficient_space"),
                  type = "error",
                  queue = "trunk",
                  timeout = 3000,
                  layout = "bottomCenter"
                }
              )
            else
              -- Checks passed, storing the item.
              store.set("coffre", coffre)
              xPlayer.removeInventoryItem(item, count)

              MySQL.Async.execute(
                "UPDATE trunk_inventory SET owned = @owned WHERE plate = @plate",
                {
                  ["@plate"] = plate,
                  ["@owned"] = owned
                }
              )
            end
          end
        )
      else
        TriggerClientEvent(
          "pNotify:SendNotification",
          _source,
          {
            text = _U("invalid_quantity"),
            type = "error",
            queue = "trunk",
            timeout = 3000,
            layout = "bottomCenter"
          }
        )
      end
    end

    if type == "item_account" then
      local playerAccountMoney = xPlayer.getAccount(item).money

      if (playerAccountMoney >= count and count > 0) then
        TriggerEvent(
          "esx_trunk:getSharedDataStore",
          plate,
          function(store)
            local blackMoney = (store.get("black_money") or nil)
            if blackMoney ~= nil then
              blackMoney[1].amount = blackMoney[1].amount + count
            else
              blackMoney = {}
              table.insert(blackMoney, {amount = count})
            end

            if (getTotalInventoryWeight(plate) + blackMoney[1].amount / 10) > max then
              TriggerClientEvent(
                "pNotify:SendNotification",
                _source,
                {
                  text = _U("insufficient_space"),
                  type = "error",
                  queue = "trunk",
                  timeout = 3000,
                  layout = "bottomCenter"
                }
              )
            else
              -- Checks passed. Storing the item.
              xPlayer.removeAccountMoney(item, count)
              store.set("black_money", blackMoney)

              MySQL.Async.execute(
                "UPDATE trunk_inventory SET owned = @owned WHERE plate = @plate",
                {
                  ["@plate"] = plate,
                  ["@owned"] = owned
                }
              )
            end
          end
        )
      else
        TriggerClientEvent(
          "pNotify:SendNotification",
          _source,
          {
            text = _U("invalid_amount"),
            type = "error",
            queue = "trunk",
            timeout = 3000,
            layout = "bottomCenter"
          }
        )
      end
    end

    if type == "item_weapon" then
      TriggerEvent(
        "esx_trunk:getSharedDataStore",
        plate,
        function(store)
          local storeWeapons = store.get("weapons")

          if storeWeapons == nil then
            storeWeapons = {}
          end

          table.insert(
            storeWeapons,
            {
              name = item,
              label = label,
              ammo = count
            }
          )
          if (getTotalInventoryWeight(plate) + (getItemWeight(item))) > max then
            TriggerClientEvent(
              "pNotify:SendNotification",
              _source,
              {
                text = _U("invalid_amount"),
                type = "error",
                queue = "trunk",
                timeout = 3000,
                layout = "bottomCenter"
              }
            )
          else
            store.set("weapons", storeWeapons)
            xPlayer.removeWeapon(item)

            MySQL.Async.execute(
              "UPDATE trunk_inventory SET owned = @owned WHERE plate = @plate",
              {
                ["@plate"] = plate,
                ["@owned"] = owned
              }
            )
          end
        end
      )
    end

    TriggerEvent(
      "esx_trunk:getSharedDataStore",
      plate,
      function(store)
        local blackMoney = 0
        local items = {}
        local weapons = {}
        weapons = (store.get("weapons") or {})

        local blackAccount = (store.get("black_money")) or 0
        if blackAccount ~= 0 then
          blackMoney = blackAccount[1].amount
        end

        local coffre = (store.get("coffre") or {})
        for i = 1, #coffre, 1 do
          table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
        end

        local weight = getTotalInventoryWeight(plate)

        text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
        data = {plate = plate, max = max, myVeh = owned, text = text}
        TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
      end
    )
  end
)

ESX.RegisterServerCallback(
  "esx_trunk:getPlayerInventory",
  function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local blackMoney = xPlayer.getAccount("black_money").money
    local items = xPlayer.inventory

    cb(
      {
        blackMoney = blackMoney,
        items = items
      }
    )
  end
)

function all_trim(s)
  if s then
    return s:match "^%s*(.*)":match "(.-)%s*$"
  else
    return "noTagProvided"
  end
end
