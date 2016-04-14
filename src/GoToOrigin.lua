#include Library.lua

bak.loadGpsCalibration()
print("Loaded GPS information.")

-- bak.aggressive = true

print("Moving to origin")
if bak.moveTo(0, 0, 0) then
  print("Successfully moved to origin.")
  bak.setFacing(0, 1)
else
  print("Something impeded movement to origin.")
end
