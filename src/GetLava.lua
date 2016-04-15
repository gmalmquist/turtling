#include Library.lua

LAVA_ID = "minecraft:lava"
LAVA_FLOW_ID = "minecraft:flowing_lava"
LAVA_BUCKET_ID = "minecraft:water_bucket"
EMPTY_BUCKET_ID = "minecraft:bucket"
DRUM_ID = "ExtraUtilities:drum"


function retrieveLava()

  function fuelDance()
    print("Fuel is low. :-(")
    bak.resetPosition()
    while turtle.getFuelLevel() < 500 do
      bak.turnRight()
    end
    bak.resetRotation()
  end

  function needMoreFuel()
    local level = turtle.getFuelLevel()
    print("Fuel: ", level)
    if level < 500 then
      if turtle.smartRefuel{level=500} then
        return false
      end
      return true
    end
    return false
  end

  function descend()
    print("Descending.")
    while not turtle.detectDown() do 
      turtle.down()
    end
  end

  function checkForLava()
    local isBlock, block = turtle.inspectDown()
    if isBlock and (block.name == LAVA_ID or block.name == LAVA_FLOW_ID) then
      print("Found lava.")
      bak.selectItemName(EMPTY_BUCKET_ID)
      bak.placeDown()
      return true
    end
    return false
  end

  function huntForLava()
    print("Hunting for lava.")
    local visited = bak.Set()
    local pushed = 0

    while not needMoreFuel() do 
      if checkForLava() then
        break
      end

      bak.pushPosition()
      pushed = pushed + 1

      local p = bak.position 
      local vertex = {x=p.x, y=p.y, z=p.z}
      if visited.contains(vertex) then
        break
      end
      visited.add(vertex)

      local wentForward = false
      for i=1,4 do 
        if not bak.forward() then
          bak.turnRight()
        else
          wentForward = true
          break
        end
      end

      if not wentForward then
        break
      end
    end

    for i=1,pushed do
      bak.popPosition()
    end

    if needMoreFuel() then
      fuelDance()
    end
  end


  if needMoreFuel() then
    fuelDance()
  end

  descend()
  huntForLava()
  bak.resetPosition()
  bak.resetRotation()
end

retrieveLava()
