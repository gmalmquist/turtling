#include Library.lua

SAPLING_ID = "minecraft:sapling"
LOG_ID = "minecraft:log"
PLANKS_ID = "minecraft:planks"
DIRT_ID = "minecraft:dirt"
GRASS_ID = "minecraft:grass"

treeRows = 4
treeCols = 4

function createFuel()
  print("Trying to create fuel.")
  bak.resetPosition()

  function storeNotLogs()
    bak.setFacing(-1, 0) -- Face the scratch chest.
    -- Dump anything except exactly one stack of logs.
    local sawLogs = false
    for i=1,16 do
      if turtle.getItemCount(i) > 0 then
        if sawLogs or turtle.getItemDetail(i).name ~= LOG_ID then
          turtle.select(i)
          bak.drop()
        elseif turtle.getItemDetail(i).name == LOG_ID then
          sawLogs = true
        end
      end
    end
    return sawLogs
  end

  function retrieveItems()
    print("Retrieving items.")
    bak.setFacing(-1, 0)
    while turtle.suck() do 
      -- Try and get everything back.
    end
  end

  if not storeNotLogs() then
    retrieveItems()
    bak.setFacing(0, -1)
    while turtle.suck() do
      -- See if we can find logs in the output.
    end

    if not storeNotLogs() then
      print("I don't seem to have any logs.")
      retrieveItems()
      return false
    end
  end

  -- Select an empty slot.
  for i=1,16 do 
    if turtle.getItemCount(i) == 0 then
      turtle.select(i)
      break
    end
  end

  if not turtle.craft() then
    print("Failed to craft planks.")
    return false
  end

  for i=1,16 do 
    local count = turtle.getItemCount(i)
    if count > 0 and turtle.getItemDetail(i).name == PLANKS_ID then
      print("Eating ", count, " planks.")
      turtle.select(i)
      turtle.refuel()
    end
  end

  retrieveItems()

  print("Fuel level: ", turtle.getFuelLevel())
  return true
end

function fuelDance()
  print("Waiting for fuel.")
  while not bak.refuelWith(PLANKS_ID) do
    bak.turnRight()
  end
end

function ensureFuel()
  local level = turtle.getFuelLevel()
  print("Fuel level is: ", level)
  if level < 500 then
    print("Need to refuel.")
    while turtle.getFuelLevel() < 500 and createFuel() do
      print("Made and ate some planks.")
    end
    if turtle.getFuelLevel() >= 500 then
      return true
    end
    if not bak.refuelWith(PLANKS_ID) then
      bak.resetPosition()
      fuelDance()
    end
  end
  return true
end

function gatherItems()
  for i=1,4 do
    turtle.suck()
    turtle.turnRight()
  end
end

function harvestTreeClever()
  bak.pushPosition()
  bak.pushFacing()

  function fuelMeMaybe()
    bak.pushPosition()
    bak.pushFacing()

    ensureFuel()

    bak.up()

    bak.popPosition()
    bak.popFacing()
  end

  bak.forward()
  if turtle.detectUp() and bak.up() then
    bak.mineDFS({
      blocks=bak.Set({"minecraft:log", "minecraft:leaves"}),
      boundary={minY=1},
      update=fuelMeMaybe
    })
  end

  bak.popPosition()
  bak.popFacing()
end

function harvestTree()
  bak.pushPosition()
  bak.pushFacing()
  
  bak.forward()

  bak.pushPosition()
  while turtle.detectUp() and bak.up() do
    for i=1,4 do
      turtle.dig()
      bak.turnRight()
    end
  end
  bak.popPosition()

  gatherItems()
  
  bak.popPosition()
  bak.popFacing()
end

function checkDirt()
  bak.pushFacing()
  bak.pushPosition()
  bak.forward()
  local hasBlock, block = turtle.inspectDown()
  if not hasBlock then
    if bak.selectItemName(DIRT_ID) then
      bak.placeDown()
    end
  elseif (block.name ~= DIRT_ID) and (block.name ~= GRASS_ID) then
    bak.digDown()
    if bak.selectItemName(DIRT_ID) then
      bak.placeDown()
    end
  end
  bak.popPosition()
  bak.popFacing()
end

function placeSapling()
  local isBlock, block = turtle.inspect()
  if isBlock then 
    if block.name == SAPLING_ID then
      return true -- Already a sapling here.
    else
      -- This might actually be something other than a tree,
      -- but we're still gonna mine it out of the way.
      harvestTree()
    end
  end

  -- Make sure there's dirt here.
  checkDirt()

  if bak.selectItemName(SAPLING_ID) then
    return turtle.place()
  end
  return false
end

function unloadItems()
  bak.resetPosition()
  bak.turnRight()
  bak.turnRight()
  local keptOneLog = false
  for i=1,16 do 
    if turtle.getItemCount(i) > 0 then
      name = turtle.getItemDetail(i).name
      if name ~= SAPLING_ID and name ~= DIRT_ID and name ~= PLANKS_ID then
        if name ~= LOG_ID or keptOneLog then
          turtle.select(i)
          turtle.drop()
        elseif name == LOG_ID then
          keptOneLog = true
        end
      end
    end
  end
end

function patrol()
  for c=1, treeCols do
    local parity = (c%2==1)
    local turn = parity and bak.turnRight or bak.turnLeft
    local x = (c-1)*2
    for r=1, treeRows do
      local z = (r*2)-1
      if not parity then
        z = (treeRows*2) - z
      end
      bak.moveTo(x, 0, z)
      
      bak.pushFacing()
      turn()
      bak.suck()
      placeSapling()
      bak.popFacing()
      bak.suck()

      bak.forward()
      bak.suck()
    end
    turn()
    for f=1,2 do
      bak.forward()
    end
  end
end

bak.aggressive = true

ensureFuel()
while true do
  bak.organizeInventory()
  patrol()
  ensureFuel()
  unloadItems()
end

bak.aggressive = false

print("")
print("Done.")
