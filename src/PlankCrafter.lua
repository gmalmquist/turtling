#include Library.lua

LOG_ID = "minecraft:log"
PLANKS_ID = "minecraft:planks"

function checkEmpty()
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      return false
    end
  end
  return true
end

function acquireLogs()
  if not checkEmpty() then
    return
  end

  bak.moveTo(0, 0, 0)
  bak.setFacing(1, 0)

  turtle.select(1)
  if not bak.suck() then
    return false
  end
  return true
end

function depositPlanks()
  bak.moveTo(0, 0, 0)
  bak.setFacing(-1, 0)

  for i=1,16 do 
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if turtle.getItemDetail(i).name == PLANKS_ID then
        turtle.drop()
      end
    end
  end
end

function checkFuel()
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if turtle.getItemDetail(i).name == PLANKS_ID then
        if turtle.getFuelLevel() < 500 then
          turtle.refuel()
        end
      end
    end
  end
  return turtle.getFuelLevel() >= 500
end

while true do
  checkFuel()

  acquireLogs()
  checkFuel()
  turtle.craft()
  depositPlanks()
end
