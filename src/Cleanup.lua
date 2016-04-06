print("Loading library (Make sure you ran Library first).")
os.loadAPI("Library")
print(" bak = [", bak, "]")
bak.aggressive = true

print("Variables.")
clearUp = 8
clearSide = (16+13)

-- clearUp = 5
-- clearSide = 6

function checkFuel()
  local level = turtle.getFuelLevel()
  print("Fuel level is ", level)
  if level < 500 then
    print("Need to refuel.")
    return bak.refuel()
  end
  return true
end

function fuelDance()
  print("Waiting for fuel.")
  while not checkFuel() do
    bak.turnRight()
  end
end

function doCleanup()
  print("Cleaning.")
  if not checkFuel() then
    print("Out of fuel, trying to come back.")
    bak.resetPosition()
    fuelDance()
  end
  for layer=(clearUp-1),0,-1 do
    print("Layer ", layer)
    for row=0,(clearSide-1) do
      print("Row ", row)
      if row % 2 == 0 then
        bak.moveTo(row, layer, 0)
        bak.moveTo(row, layer, clearSide-1)
      else
        bak.moveTo(row, layer, clearSide-1)
        bak.moveTo(row, layer, 0)
      end
      if not checkFuel() then
        print("Out of fuel, trying to come back.")
        bak.resetPosition()
        fuelDance()
      end
    end
    if not bak.hasSlotsLeft() then
      print("Need to dump inventory.")
      bak.resetPosition()
      bak.setFacing(0, -1)
      bak.dumpInventory()
    end
  end
end

doCleanup()

print("Resetting.")
bak.resetPosition()

bak.aggressive = false

print("Done.")
