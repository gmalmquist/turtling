-- Startup Script for Eggie (the tree-cutter).
#include Library.lua

-- GPS origin is at x=-358, y=0, z=468
-- Farm origin is at x=-395, y=71, z=461
bak.gpsSync({
  x=-395 - (-358),
  y=71 - 0,
  z=461 - 468
})

bak.eats = bak.Set({"minecraft:log", "minecraft:leaves", "minecraft:sapling"})
while not bak.moveTo(0, 0, 0) do
  print(string.format("Unable to return to origin; fuel = %d.", turtle.getFuelLevel()))
  print("Please remove anything in the way, and make sure Turtle is fueled.")
end

print("Facing forward")
bak.faceZ(1)

--print("Starting tree farming application.")
--shell.run("Trees")
