-- Startup Script for roo (the tree-cutter 2.0).
#include Library.lua

-- GPS origin is at x=-358, y=0, z=468
-- Farm origin is at x=-395, y=71, z=461
bak.gpsOffset = {
  x= -358 - (-395) + 1,
  y=-72,
  z=461 - 468 + 12
}

bak.gpsScale = {
  x=1,
  y=1,
  z=-1
}

if bak.gpsSync() then 
  bak.eats = bak.Set({"minecraft:log", "minecraft:leaves", "minecraft:sapling"})
  while not bak.moveTo(0, 0, 0) do
    print(string.format("Unable to return to origin; fuel = %d.", turtle.getFuelLevel()))
    print("Please remove anything in the way, and make sure Turtle is fueled.")
  end

  print("Facing forward")
  bak.faceZ(1)

  print("Starting tree farming application.")
  shell.run("Trees")
else
  print("Error communicating with GPS.")
  print("Gonna try flying.")
  h = open("status.txt", "w")
  h.writeLine("I don't know where I am. Help, I'm scared.")
  h.close() 
  bak.aggressive = true 
  while bak.up() do
    if bak.gpsSync() then
      bak.moveTo(bak.position.x, 0, bak.position.z)
      bak.aggressive = false
      bak.moveTo(0, 0, 0)
    end
    print("rising ...")
  end

end