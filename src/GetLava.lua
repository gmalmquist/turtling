#include Library.lua

LAVA_BUCKET_ID = "minecraft:water_bucket"
EMPTY_BUCKET_ID = "minecraft:bucket"
DRUM_ID = "ExtraUtilities:drum"


function addLavaToDrum()
  local there, info = turtle.inspectUp()
  print(there, ", ", info.name)
  if there and info.name == "minecraft:flowing_water" then
    bak.selectItemName(EMPTY_BUCKET_ID)
    bak.placeUp()
  end
end


print("Trying to add lava to drum: ", addLavaToDrum())
