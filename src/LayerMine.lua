#include CommonMine.lua

function bak.layerMine(options)
  bak.generiMine(options, function(context)
    local extent, offset = context.extent, context.offset
    local parity = false

    for layer=0, abs(extent.y) do
      for col=0, (abs(extent.x)-1) do
        parity = not parity
        context.ensureFuel()

        local x = col * sign(extent.x) + offset.x
        local y = layer * -sign(extent.y) + offset.y

        local zs = (parity and 0 or extent.z) + offset.z
        local ze = (parity and extent.z or 0) + offset.z

        bak.moveTo(x, y, zs)
        bak.moveTo(x, y, ze)

        if not parity and context.halfFull() then
          context.unloadInventory()
        end
      end
    end

  end)
end