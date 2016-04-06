print("Loading library...")
os.loadAPI("Library")

SAPLING_ID = "minecraft:sapling"
LOG_ID = "minecraft:log"
PLANKS_ID = "minecraft:planks"

sizeX = 8
sizeZ = 8

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

function harvestTree()
  bak.pushPosition()
  bak.pushFacing()
  
  bak.forward()
  bak.moveBy(0,10,0)
  bak.moveBy(0,-10,0)

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
  if bak.selectItemName(SAPLING_ID) then
    return turtle.place()
  end
  return false
end

function patrol()
  ensureFuel()
  local cols = (sizeX/2)-1
  local rows = (sizeZ/2)-1
  for i=0,cols do
    for j=0,rows do
      local x = i*2
      local z = ((i%2==0) and j or (rows-j))*2
      bak.moveTo(x, 0, z+1)
      bak.turnRight()
      -- todo: handle the two non-empty cases.
      placeSapling()
      if j == rows then
        bak.moveTo(x, 0, z+1)
      end
    end
  end
  bak.resetPosition()
end

bak.aggressive = true

for i=1,16 do
  if turtle.getItemCount(i) > 0 then
    print(turtle.getItemDetail(i).name)
  end
end

if not bak.selectItemName(SAPLING_ID) then
  print("I have no saplings.")
else
  patrol()
end

bak.aggressive = false

print("")
print("Done.")