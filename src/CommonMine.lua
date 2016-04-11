 #include Library.lua

function bak.generiMine(options, doMine)
  local extent = options.extent or {x=8, y=7, z=8}
  local offset = options.offset or {x=0, y=0, z=0}

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
        bak.setFacing(-sign(extent.x), 0)
        if bak.suck() and bak.smartRefuel{level=level, item="minecraft:planks"} then
          return true
        end
        fuelDance()
      end
    end
    return true
  end

  function halfFull()
    local slotsFull = 0
    for i=1,16 do 
      if turtle.getItemCount(i) > 0 then
        slotsFull = slotsFull + 1
      end
    end
    return slotsFull >= 8
  end

  function unloadInventory()
    bak.resetPosition()
    bak.setFacing(0, -sign(extent.z))
    bak.dumpInventory()
  end

  bak.aggressive = true
  ensureFuel()

  local context = {
    extent=extent,
    offset=offset,
    fuelDance=fuelDance,
    ensureFuel=ensureFuel,
    halfFull=halfFull,
    unloadInventory=unloadInventory
  }

  doMine(context)

  unloadInventory()
  bak.aggressive = false
  print("Done mining.")
end