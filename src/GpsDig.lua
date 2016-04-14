#include Library.lua

function executeGpsDig(options)
  options = options or {}
  start = options.start or { x=0, y=0, z=0 }
  delta = options.delta or { x=1, y=3, z=-1 }

  function excavate()
    bak.aggressive = 1
    print("Excavating.")

    function saveProgress(i, j, k)
      local h = fs.open("dig-progress.dat", "w")
      h.writeLine(string.format("%d", i))
      h.writeLine(string.format("%d", j))
      h.writeLine(string.format("%d", k))
      h.close()
    end

    function loadProgress()
      if not fs.exists("dig-progress.dat") then
        print("No saved dig progress exists.")
        return 0, 0, 0
      end

      local h = fs.open("dig-progress.dat", "r")
      local text = h.readAll()
      h.close()

      if text == "" then
        return 0, 0, 0
      end
      
      local lines = {}
      local i = 1
      
      for token in string.gmatch(text, "[^\n]+") do
       lines[i] = token
       i = i + 1
      end

      if i ~= 4 then
        print("Save file is corrupt.")
        return false
      end

      return tonumber(lines[1]), tonumber(lines[2]), tonumber(lines[3])
    end

    function fullRefuel()
      for i=1,16 do
        if turtle.getFuelLevel() >= turtle.getFuelLimit() then
          return
        end

        if turtle.getItemCount(i) > 0 then
          turtle.select(i)
          turtle.refuel()
        end
      end
    end

    function safeRefuel()
      -- Required fuel to go up and down one column.
      local requiredFuelForColumn = delta.y*2 + 2

      -- Required fuel for gps computation.
      -- In the best-case this is 8, so we're doubling
      -- to be conservative.
      local requiredFuelForGps = 16

      -- Required fuel to get from the origin to the mining start position, and back.
      local requiredFuelToOffset = (abs(start.x) + abs(start.y) + abs(start.z)) * 2

      -- Make sure we have double the estimated fuel required to be safe.
      local safetyMultiplier = 2

      local minimumFuel = (requiredFuelForColumn + requiredFuelForGps + requiredFuelToOffset) * safetyMultiplier

      fullRefuel()

      while not bak.smartRefuel{level=minimumFuel} do
        -- Get as far as we can toward the origin
        bak.moveTo(0, 0, 0)

        print(string.format("Fuel: %d / %d", turtle.getFuelLevel(), minimumFuel))
        bak.turnRight()
      end
    end

    function fuelDance()
      fullRefuel()
      while turtle.getFuelLevel() <= 0 and not bak.smartRefuel() do
        print(string.format("Fuel: %d", turtle.getFuelLevel()))
        bak.turnRight()
      end
    end

    function exchangeSupplies()
      -- Go back to the chests, drop of mining stuff, collect fuel.
      local x, y, z = bak.position.x, bak.position.y, bak.position.z

      while not bak.moveTo(0, 0, 0) do
        fullRefuel()
        bak.turnRight()
      end

      bak.faceX(-1)
      for i=1,16 do
        if turtle.getItemCount(i) > 0 and turtle.getItemDetail(i).name ~= "minecraft:planks" then
          if turtle.getItemDetail(i).name ~= "ComputerCraft:CC-Peripheral" then
            bak.select(i)
            bak.drop()
          end
        end
      end

      bak.faceZ(1)
      while bak.suck() do
      end
      safeRefuel()

      bak.faceZ(1)
      for i=1,16 do 
        if turtle.getItemCount(i) > 0 and turtle.getItemDetail(i).name ~= "ComputerCraft:CC-Peripheral" then
          bak.select(i)
          bak.drop()
        end
      end

      fuelDance()
      bak.moveTo(start.x, start.y, start.z)
      bak.moveTo(x, y, z)
    end

    initI, initJ, initK = loadProgress()


    bak.moveTo(start.x, start.y, start.z)

    for i=initI,abs(delta.x) do
      local x = start.x + i * sign(delta.x)
      for k=initK,abs(delta.z) do
        local z = start.z + k * sign(delta.z)
        if i % 2 == 1 then
          z = start.z + (abs(delta.z) - k) * sign(delta.z)
        end
        if k % 2 == 0 then
          exchangeSupplies()
        end
        for j=initJ,abs(delta.y) do
          saveProgress(i, j, k)
          local y = start.y + j * sign(delta.y)
          if k % 2 == 1 then
            y = start.y + (abs(delta.y) - j) * sign(delta.y)
          end

          fuelDance() -- Refuel if necessary.
          bak.moveTo(x, y, z)
        end
      end
    end

    print("Done, going home.")

    bak.moveTo(0, 0, 0)
    exchangeSupplies()
    bak.moveTo(0, 0, 0)
  end

  -- Start:

  if bak.loadGpsCalibration() then
    print("Loaded GPS information.")

    -- bak.aggressive = true

    print("Moving to origin")
    bak.aggressive = true
    if bak.moveTo(0, 0, 0) then
      print("Successfully moved to origin.")
      bak.setFacing(0, 1)

      print("Calling excavation routine.")
      excavate()
    else
      print("Something impeded movement to origin.")
    end
  else
    print("Failed to load GPS location. Something is wrong.")
    bak.aggressive = true 
    while not bak.loadGpsCalibration() do
      if not bak.up() then
        bak.turnRight()
      end
    end
    bak.moveTo(0, 0, 0)
  end
end