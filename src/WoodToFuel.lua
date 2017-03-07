#include Library.lua

FRONT_CENTER_ID = "BuildCraft|Transport:pipeBlock"
CHEST_ID = "minecraft:chest"
LOG_ID = "minecraft:log"
PLANKS_ID = "minecraft:planks"

function facingBlock(name) 
  local success, detail = turtle.inspect()
  return (success and detail.name == name) or (not success and name == "")
end

function localize()
  while facingBlock("") do
    bak.turnRight()
  end

  if facingBlock(FRONT_CENTER_ID) then
    return true
  end
  if facingBlock(CHEST_ID) then
    bak.turnRight()
    if facingBlock("") then
      -- We're in front of the wood chest.
      print("In front of wood chest.")
      bak.forward()
      bak.turnLeft()
      return facingBlock(FRONT_CENTER_ID)
    else
      -- We must be in front of the other chest.
      print("In front of planks chest.")
      bak.turnLeft()
      bak.turnLeft()
      if not facingBlock("") then
        print("I don't know where I am.")
        return false
      end
      bak.forward()
      bak.turnRight()
      return facingBlock(FRONT_CENTER_ID)
    end
  end
end

function craftThePlanks()
  if not localize() then
    print("Unable to find starting point.")
    return false
  end

  bak.turnLeft()

  function dropAll(name) 
    for i=1,16 do
      if turtle.getItemCount(i) > 0 and turtle.getItemDetail(i).name == name then
        bak.select(i)
        bak.drop()
      end
    end
  end

  while true do
    -- Go to the wood chest
    bak.forward()
    bak.turnRight()
    -- Grab wood
    dropAll(LOG_ID)
    while not bak.suck() do
      print("Unable to collect wood.")
    end

    bak.select(1)
    while not turtle.craft() do
      print("Unable to craft wood")
      dropAll()
    end

    -- Go to the other chest
    bak.turnRight()
    bak.forward()
    bak.forward()
    bak.turnLeft()

    -- Drop off planks
    dropAll(PLANKS_ID)
    bak.turnLeft()
    bak.forward()

    local pause = 60 * 20
    print(string.format("Pausing for %d seconds to not make too many planks.", pause))
    os.sleep(pause)
  end
end

craftThePlanks()