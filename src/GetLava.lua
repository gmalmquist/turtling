#include Library.lua

LAVA_ID = "minecraft:lava"
LAVA_FLOW_ID = "minecraft:flowing_lava"
LAVA_BUCKET_ID = "minecraft:water_bucket"
EMPTY_BUCKET_ID = "minecraft:bucket"
DRUM_ID = "ExtraUtilities:drum"


function retrieveLava()

  local lastFuel = 0

  function fuelDance()
    print("Fuel is low. :-(")
    bak.resetPosition()
    while turtle.getFuelLevel() < 500 do
      bak.smartRefuel{level=500}
      bak.turnRight()
    end
    bak.resetRotation()
  end

  function needMoreFuel()
    local level = turtle.getFuelLevel()
    if level ~= lastFuel then 
      print("Fuel: ", level)
      lastFuel = level
    end
    if level < 500 then
      if bak.smartRefuel{level=500} then
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
    visited.hash = function(pt)
      return pt.x .. "," .. pt.y .. "," .. pt.z
    end
    local pushed = 0

    local frontier = bak.Stack()
    frontier.push(bak.position)

    function expand(v)
      local adj = {
        {x=v.x, y=v.y, z=v.z-1},
        {x=v.x-1, y=v.y, z=v.z},
        {x=v.x+1, y=v.y, z=v.z},
        {x=v.x, y=v.y, z=v.z+1},
      }
      for i, p in ipairs(adj) do
        if not visited.contains(p) then 
          frontier.push(p)
        end
      end
    end

    while not needMoreFuel() and not frontier.isEmpty() do 
      if checkForLava() then
        print("Found lava, stopping.")
        break
      end

      bak.pushPosition()
      pushed = pushed + 1

      local vertex = frontier.pop()
      if not visited.contains(vertex) then
        visited.add(vertex)
        local p = bak.position
        expand(p)

        print("Vertex: ", vertex.x, ", ", vertex.y, ", ", vertex.z)
        print("Frontier: ", frontier.size())

        bak.moveTo(vertex.x, vertex.y, vertex.z)
      end
    end

    if frontier.isEmpty() then
      print("Completed search.")
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
end

retrieveLava()
