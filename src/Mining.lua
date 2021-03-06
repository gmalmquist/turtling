print("Loading library...")
os.loadAPI("Library")


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
    if not bak.refuel() then
      bak.resetPosition()
      bak.setFacing(-1, 0)
      if bak.suck() and bak.smartRefuel{level=level, item="minecraft:planks"} then
        return true
      end
      fuelDance()
    end
  end
  return true
end

function bak.mineChunk(extent)
  bak.aggressive = true
  ensureFuel()

  parity = false
  for i=0,(extent.x-1) do
    for j=0,(extent.z-1) do
    	parity = not parity
      ensureFuel()
      local ys = parity and 0 or -extent.y
      local ye = parity and -extent.y or 0
      bak.moveTo(i, ys, j)
      bak.moveTo(i, ye, j)
      if not parity then
        bak.resetPosition()
        bak.setFacing(0, -1)
        bak.dumpInventory()
  	end
    end
  end

  bak.aggressive = false
end
