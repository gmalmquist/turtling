#include Library.lua

bak.loadGpsCalibration()
print("Loaded GPS information.")
print(string.format("Position = %d, %d, %d", bak.position.x, bak.position.y, bak.position.z))
print(string.format("Facing x=%d, z=%d", bak.facing.x, bak.facing.z))

print("Moving to origin")
if bak.moveTo(0, 0, 0) then
  print("Successfully moved to origin.")
else
  print("Something impeded movement to origin.")
end

print(string.format("Position = %d, %d, %d", bak.position.x, bak.position.y, bak.position.z))

bak.setFacing(0, 1)
print(string.format("Facing x=%d, z=%d", bak.facing.x, bak.facing.z))