print("Loading library...")
os.loadAPI("Library")

SAPLING_ID = "minecraft:sapling"
LOG_ID = "minecraft:log"
PLANKS_ID = "minecraft:planks"
DIRT_ID = "minecraft:dirt"
GRASS_ID = "minecraft:grass"

treeRows = 4
treeCols = 4

function fuelDance()
  print("Waiting for fuel.")
  while not bak.refuel() do
    bak.turnRight()
  end
end

function ensureFuel()
  local level = turtle.getFuelLevel()
  if level < 500 then
    print("Need to refuel.")
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
  for i=1,16 do 
    if turtle.getItemCount(i) > 0 then
      name = turtle.getItemDetail(i).name
      if name ~= SAPLING_ID and name ~= DIRT_ID and name ~= PLANKS_ID then
        turtle.select(i)
        turtle.drop()
      end
    end
  end
end

function patrol()
  ensureFuel()
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
  unloadItems()
end

bak.aggressive = true

local a,b = turtle.inspectDown()
print(b.name)

for i=1,16 do
  if turtle.getItemCount(i) > 0 then
    print(turtle.getItemDetail(i).name)
  end
end

while true do
  patrol()
end

bak.aggressive = false

print("")
print("Done.")
