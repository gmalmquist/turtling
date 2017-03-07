#include Library.lua

GRAVEL = "minecraft:gravel"
FLINT = "minecraft:flint"
CHEST = "minecraft:chest"

function selectGravel()
  for i=1,16 do
    if turtle.getItemCount(i) > 0 and turtle.getItemDetail(i).name == GRAVEL then
      if i ~= turtle.getSelectedSlot() then
        turtle.select(i)
      end
      return true
    end
  end
  print("Missing gravel")
  return false
end

function faceChest()
  while true do
    local success, detail = turtle.inspect()
    if success and detail.name == CHEST then
      return true
    end
    turtle.turnRight()
  end
end

function unfaceChest()
  while true do
    local success, detail = turtle.inspect()
    if not success or detail.name == GRAVEL then
      return true
    end
    turtle.turnLeft()
  end
end

function depositFlint()
  for i=1,16 do
    if turtle.getItemCount(i) > 0 and turtle.getItemDetail(i).name == FLINT then
      if turtle.getItemCount(i) >= 8 then
        turtle.select(i)
        faceChest()
        while not turtle.drop() do
          print("Cannot drop flint (is chest full?)")
        end
        unfaceChest()
      end
    end
  end
end

function digGravel()
  local success, detail = turtle.inspect()
  if success and detail.name == GRAVEL then
    turtle.dig()
  end

  success, detail = turtle.inspectUp()
  if success and detail.name == GRAVEL then
    turtle.digUp()
  end 

  turtle.suckUp()
  turtle.suck()

  depositFlint()
end

while true do
  digGravel()
  if selectGravel() then
    turtle.placeUp()
    turtle.place()
  else
    os.sleep(1) -- Wait for more gravel.
  end
end
