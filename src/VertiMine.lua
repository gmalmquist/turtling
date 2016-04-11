#include CommonMine.lua

function bak.vertiMine(options)
  bak.generiMine(options, function(context)
    local extent, offset = context.extent, context.offset
    local parity = false
    for i=0,(abs(extent.x)-1) do
      for j=0,(abs(extent.z)-1) do
      	parity = not parity
        context.ensureFuel()
        local ys = (parity and 0 or -extent.y) + offset.y
        local ye = (parity and -extent.y or 0) + offset.y
        local x = i * sign(extent.x) + offset.x
        local z = j * sign(extent.z) + offset.z
        bak.moveTo(x, ys, z)
        bak.moveTo(x, ye, z)
        if not parity and context.halfFull() then
          context.unloadInventory()
    	  end
      end
    end
  end)
end