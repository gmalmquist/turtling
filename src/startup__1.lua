-- Startup Script for Eggie (the tree-cutter).
#include Library.lua

if bak.loadState() then
  print("Returning to 0,0,0")

  bak.aggressive = false
  bak.eats = bak.Set({"minecraft:log", "minecraft:leaves", "minecraft:sapling"})
  while not bak.moveTo(0, 0, 0) do
    print(string.format("Unable to return to origin; fuel = %d.", turtle.getFuelLevel()))
    print("Please remove anything in the way, and make sure Turtle is fueled.")
  end

  print("Facing forward")
  bak.faceZ(1)

  print("Start-up sequence complete.")

  print("Starting tree farming application.")
  shell.run("Trees")
end