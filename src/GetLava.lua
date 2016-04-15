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
    while turtle.getFuelLevel() < 500 then
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
    if isBlock and (block.name == LAVA_ID or block.name == LAVA_FLOW_ID) do 
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
    local frontier = bak.Stack()

    function adjacent(p)
      return {
        {x = p.x, y = p.y, z = p.z-1},
        {x = p.x-1, y = p.y, z = p.z},
        {x = p.x+1, y = p.y, z = p.z},
        {x = p.x, y = p.y, z = p.z+1},
      }
    end

    function expand(vertex)
      for i,a in ipairs(adjacent(vertex))
        if not visited.contains(a) then
          frontier.push(a)
        end
      end
    end

    local pushed = 0
    frontier.push(bak.position)

    while not frontier.isEmpty() do
      if turtle.getFuelLevel() < 500 then

      end

      vertex = frontier.pop()
      if not visited.contains(vertex) do
        visited.add(vertex)

        pushed = pushed + 1
        bak.pushPosition()

        bak.moveTo(vertex.x, vertex.y, vertex.z)

        if checkForLava() or needMoreFuel() then
          break
        end

        expand(vertex)
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
  resetPosition()
  resetRotation()
end

retrieveLava()
