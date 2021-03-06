function abs(x)
  return (x>0) and x or -x
end

function sign(x)
  if x < 0 then
    return -1
  elseif x > 0 then
    return 1
  else
    return 0
  end
end

function shallowEquals(a, b)
  if a == b then
    return true
  end
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= "table" then
    return false
  end
  for k, v in pairs(a) do
    if v ~= b[k] then
      return false
    end
  end
  for k, v in pairs(b) do
    if v ~= a[k] then
      return false
    end
  end
  return true
end

bak = {
  facing={x=0,z=1},
  position={x=0,y=0,z=0},
  aggressive=false,
  eats=nil,
  gpsOffset={x=0,y=0,z=0},
  -- NB: z has to be negative here, because the turnLeft/Right methods
  -- only work properly if they can make assumptions about right-hand rules.
  gpsScale={x=1,y=1,z=-1}
}

bak.suck = turtle.suck
bak.suckUp = turtle.suckUp
bak.suckDown = turtle.suckDown

function bak.findSlot(name, damage)
  for i=1,16 do
    local detail = turtle.getItemDetail(i)
    if detail then
      if detail.name == name and (damage == nil or detail.damage == damage) then
        return i
      end
    end
  end
  return nil
end

function bak.trySelect(name, damage)
  local slot = bak.findSlot(name, damage)
  if slot ~= nil then
    bak.select(slot)
    return true
  end
  return false
end

function bak.place(name, damage, placefunc)
  placefunc = placefunc or turtle.place
  if name == nil or bak.trySelect(name, damage) then
    placefunc()
    return true
  end
  return false
end

function bak.placeUp(name, damage)
  return bak.place(name, damage, turtle.placeUp)
end

function bak.placeDown(name, damage)
  return bak.place(name, damage, turtle.placeDown)
end

function bak.replace(name, damage, placef, inspectf, digf)
  placef = placef or bak.place
  inspectf = inspectf or turtle.inspect
  digf = digf or turtle.dig

  local blocked, details = inspectf()
  if blocked then
    if details.name == name and (damage == nil or details.damage == damage) then
      print(string.format("%s is already there.", name))
      return true -- the block we want is already there.
    end
    if bak.eatMaybe(inspectf, digf) then
      print(string.format("Ate %s below us.", details.name))
      return placef(name, damage)
    end
    return false -- we couldn't remove the existing block
  end
  -- we're not blocked, just try to put something down.
  print("Not blocked.")
  return placef(name, damage);
end

function bak.replaceUp(name, damage)
  return bak.replace(name, damage, bak.placeUp, turtle.inspectUp, turtle.digUp)
end

function bak.replaceDown(name, damage)
  return bak.replace(name, damage, bak.placeDown, turtle.inspectDown, turtle.digDown)
end

bak.dig = turtle.dig
bak.digUp = turtle.digUp
bak.digDown = turtle.digDown

bak.drop = turtle.drop
bak.dropDown = turtle.dropDown
bak.dropUp = turtle.dropUp

bak.select = turtle.select

function bak.Stack()
  local stack = {index=0}

  function stack.push(value)
    stack[stack.index] = value
    stack.index = stack.index + 1
  end

  function stack.pop()
    if stack.index > 0 then
      stack.index = stack.index - 1
      value = stack[stack.index]
      stack[stack.index] = nil
      return value
    end
    return nil
  end

  function stack.size()
    return stack.index
  end

  function stack.isEmpty()
    return stack.size() == 0
  end

  return stack
end

function bak.Set(init)
  local set = {store={}, length=0}

  function set._hash(value)
    if set.hash then
      return set.hash(value)
    end
    return value
  end

  function set.add(value)
    value = set._hash(value)
    if not set.store[value] then
      set.store[value] = 1
      set.length = set.length + 1
    end
  end

  function set.remove(value)
    value = set._hash(value)
    if set.store[value] then 
      set.store[value] = nil
      set.length = set.length - 1
    end
  end

  function set.contains(value)
    value = set._hash(value)
    if set.hash then
      return set.store[value]
    end
    for v in pairs(set.store) do
      if shallowEquals(value, v) then
        return true
      end 
    end
    return false
  end

  function set.size()
    return set.length
  end

  if init then
    for i,v in ipairs(init) do
      set.add(v)
    end
  end

  return set
end

bak.eats = bak.Set()

function bak.debugDump()
  local position = bak.position
  local facing = bak.facing
  print("Pos= ", position.x, ", ", position.y, ", ", position.z)
  print("Facing= ", facing.x, ", ", facing.z)
end

function bak._addpos(x, y, z)
  local p = bak.position
  p.x = p.x + x
  p.y = p.y + y
  p.z = p.z + z
end

function bak.getPosition()
  return bak.position.x, bak.position.y, bak.position.z
end

function bak.turnLeft()
  if not turtle.turnLeft() then
    return false
  end
  local face = bak.facing
  face.x, face.z = -face.z, face.x
  return true
end

function bak.turnRight()
  if not turtle.turnRight() then
    return false
  end
  local face = bak.facing
  face.x, face.z = face.z, -face.x
  return true
end

function bak.eatMaybe(inspector, digger)
  if bak.aggressive then
    -- No need to do further work.
    return digger()
  end

  local success, data = inspector()
  print(string.format("Can we aggressively eat %s?", data.name or data))
  if success and bak.eats and bak.eats.contains(data.name or "??") then 
    return digger()
  end

  if not success or not data.name then
    return bak.smartRefuel()
  end

  return false
end

function bak.forward()
  bak.suck()
  while not turtle.forward() do
    if not bak.eatMaybe(turtle.inspect, turtle.dig) then
      return false
    end
  end
  bak._addpos(bak.facing.x, 0, bak.facing.z)
  return true
end

function bak.back()
  if turtle.back() then
    bak._addpos(-bak.facing.x, 0, -bak.facing.z)
    return true
  end
  return false
end

function bak.up()
  bak.suckUp()
  while not turtle.up() do
    if not bak.eatMaybe(turtle.inspectUp, turtle.digUp) then
      return false
    end
  end
  bak._addpos(0, 1, 0)
  return true
end

function bak.down()
  bak.suckDown()
  while not turtle.down() do
    if not bak.eatMaybe(turtle.inspectDown, turtle.digDown) then
      return false
    end
  end
  bak._addpos(0, -1, 0)
  return true
end

function bak.faceX(x)
  if sign(x) == sign(bak.facing.x) then
    return true
  end
  if sign(x) == sign(-bak.facing.x) then
    return bak.turnRight() and bak.turnRight()
  end
  if sign(x) == sign(bak.facing.z) then
    return bak.turnRight()
  end
  return bak.turnLeft()
end

function bak.faceZ(z)
  if sign(z) == sign(bak.facing.z) then
    return true
  end
  if sign(z) == sign(-bak.facing.z) then
    return bak.turnRight() and bak.turnRight()
  end
  if sign(z) == sign(bak.facing.x) then
    return bak.turnLeft()
  end
  return bak.turnRight()
end

function bak.setFacing(x, z)
  if abs(x) ~= 0 then
    bak.faceX(x)
  else
    bak.faceZ(z)
  end
end

function bak.moveBy(x, y, z)
  function tryMove(facer, amount)
    if amount == 0 then
      return true
    end
    if not facer(amount) then
      return false
    end
    for i=1,abs(amount) do
      if not bak.forward() then
        return false
      end
    end
    return true
  end
  local success = true
  if abs(x) < abs(z) then
    success = success and tryMove(bak.faceX, x)
    success = success and tryMove(bak.faceZ, z)
  else
    success = success and tryMove(bak.faceZ, z)
    success = success and tryMove(bak.faceX, x)
  end
  mover = (y>0) and bak.up or bak.down
  for i=1,abs(y) do
    success = success and mover()
  end
  return success
end

function bak.moveTo(x, y, z)
  local p = bak.position
  local dx, dy, dz = x-p.x, y-p.y, z-p.z
  return bak.moveBy(dx, dy, dz)
end

function bak.resetPosition()
  bak.moveTo(0, 0, 0)
  bak.setFacing(0, 1)
end

bak.faceStack = bak.Stack()
bak.posStack = bak.Stack()

function bak.pushPosition()
  local x,y,z = bak.getPosition()
  bak.posStack.push({x=x, y=y, z=z})
end

function bak.popPosition()
  local p = bak.posStack.pop()
  bak.moveTo(p.x, p.y, p.z)
end

function bak.pushFacing()
  bak.faceStack.push({x=bak.facing.x, z=bak.facing.z})
end

function bak.popFacing()
  local f = bak.faceStack.pop()
  bak.setFacing(f.x, f.z)
end

function bak.refuel(count)
  foundFuel = false
  count = count or (64*16)
  local slot = turtle.getSelectedSlot()
  for i=1,16 do
    local toConsume = turtle.getItemCount(i)
    if toConsume > count then
      toConsume = count
    end
    if toConsume > 0 then
      turtle.select(i)
      if turtle.refuel(toConsume) then
        count = count - toConsume
        foundFuel = true
      end
    end
  end
  turtle.select(slot)
  return foundFuel
end

function bak.refuelWith(name)
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      if turtle.getItemDetail(i).name == name then
        turtle.select(i)
        turtle.refuel()
        return true
      end
    end
  end
  return false
end

function bak.hasSlotsLeft()
  local slots = 0
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      slots = slots + 1
    end
  end
  return slots
end

function bak.dumpInventory()
  local slot = turtle.getSelectedSlot()
  for i=1,16 do
    turtle.select(i)
    turtle.drop()
  end
  turtle.select(slot)
end

function bak.getItemName(i)
  if turtle.getItemCount(i) == 0 then
    return ""
  end
  return turtle.getItemDetail(i).name
end

function bak.selectItemName(name)
  for i=1,16 do
    if bak.getItemName(i) == name then
      turtle.select(i)
      return true
    end
  end
  return false
end

function bak.getTotalItemCount(name)
  local count = 0
  for i=1,16 do
    if bak.getItemName(i) == name then
      count = count + turtle.getItemCount(i)
    end
  end
  return count
end

function bak.useItems(name, maxItems, useFunc)
  while bak.selectItemName(name) and maxItems > 0 do
    local count = turtle.getItemCount()
    local toUse = (count < maxItems) and count or maxItems
    if useFunc() then
      maxItems = maxItems - toUse
    else
      return false
    end
  end
  return maxItems <= 0
end

function bak.smartRefuel(options)
  options = options or {}

  function itemFilter(name)
    if options.item and name ~= options.item then
      return false
    end
    return not options.itemFilter or options.itemFilter(name)
  end

  function needsFuel()
    return not options.level or turtle.getFuelLevel() < options.level
  end

  local foundFuel = false

  for i=1,16 do 
    if not needsFuel() then
      return true
    end
    if turtle.getItemCount(i) > 0 then
      local name = turtle.getItemDetail(i).name
      if itemFilter(name) then
        turtle.select(i)
        turtle.refuel()
        foundFuel = true
      end
    end
  end

  if options.level then
    return not needsFuel()
  end

  return foundFuel
end

function bak.organizeInventory()
  local itemMap = {}

  for i=1,16 do 
    if turtle.getItemCount(i) > 0 then
      local name = turtle.getItemDetail(i).name

      if itemMap[name] then
        turtle.select(i)
        turtle.transferTo(itemMap[name])
        if turtle.getItemCount(i) > 0 then
          itemMap[name] = i
        end
      else
        itemMap[name] = i
      end
    end
  end
end

function bak.calibrateGps()
  local pos = {
    x = bak.position.x,
    y = bak.position.y,
    z = bak.position.z
  }

  local rot = {
    x = bak.facing.x,
    z = bak.facing.z
  }

  bak.gpsSync()

  local dx = (pos.x - bak.position.x) * bak.gpsScale.x
  local dy = (pos.y - bak.position.y) * bak.gpsScale.y
  local dz = (pos.z - bak.position.z) * bak.gpsScale.z

  bak.gpsOffset.x = bak.gpsOffset.x + dx
  bak.gpsOffset.y = bak.gpsOffset.y + dy
  bak.gpsOffset.z = bak.gpsOffset.z + dz

  print(string.format(
    "Recalibrated: offset = %d, %d, %d",
    bak.gpsOffset.x,
    bak.gpsOffset.y,
    bak.gpsOffset.z
  ))

  bak.gpsSync()
  bak.saveGpsCalibration()
  bak.moveTo(pos.x, pos.y, pos.z)
end

function bak.saveGpsCalibration()
  local h = fs.open("gps-calib.dat", "w")
  h.writeLine(string.format("%d", bak.gpsOffset.x))
  h.writeLine(string.format("%d", bak.gpsOffset.y))
  h.writeLine(string.format("%d", bak.gpsOffset.z))
  h.writeLine(string.format("%d", bak.gpsScale.x))
  h.writeLine(string.format("%d", bak.gpsScale.y))
  h.writeLine(string.format("%d", bak.gpsScale.z))
  h.close()
end

function bak.loadGpsCalibration()
  if not fs.exists("gps-calib.dat") then
    print("No saved gps calibration exists.")
    return false
  end
  print("Loading calibration information from file.")
  local h = fs.open("gps-calib.dat", "r")

  local text = h.readAll()

  if text == "" then
    print("Save file is empty, no calibration to load.")
    return true
  end

  local lines = {}
  local i = 1
  
  for token in string.gmatch(text, "[^\n]+") do
   lines[i] = token
   i = i + 1
  end

  if i ~= 7 then
    print("Save file is corrupt.")
    return false
  end

  bak.gpsOffset.x = tonumber(lines[1])
  bak.gpsOffset.y = tonumber(lines[2])
  bak.gpsOffset.z = tonumber(lines[3])
  bak.gpsScale.x = tonumber(lines[4])
  bak.gpsScale.y = tonumber(lines[5])
  bak.gpsScale.z = tonumber(lines[6])
  h.close()
  print(string.format(
    "x=%d, y=%d, z=%d, scale=(%d, %d, %d)",
    bak.gpsOffset.x,
    bak.gpsOffset.y,
    bak.gpsOffset.z,
    bak.gpsScale.x,
    bak.gpsScale.y,
    bak.gpsScale.z
  ))

  return bak.gpsSync()
end

function bak.gpsSync()
  -- First check to see if we have a modem equipped in either hand.
  -- If not, see if our inventory has a modem, and equip it.
  -- Then ask for GPS position.

  local offset = bak.gpsOffset
  local scale = bak.gpsScale

  function query()
    local x, y, z = gps.locate()
    if not x then
      print("Failed to find GPS location.")
      return false
    end

    local gx, gy, gz = x, y, z

    h = fs.open("current-pos.txt", "w")
    h.writeLine(string.format("x=%d", gx))
    h.writeLine(string.format("y=%d", gy))
    h.writeLine(string.format("z=%d", gz))
    h.close()

    x = (x + offset.x) * scale.x
    y = (y + offset.y) * scale.y
    z = (z + offset.z) * scale.z

    print(string.format("GPS location: %d, %d, %d.", x, y, z))

    bak.position.x = x
    bak.position.y = y
    bak.position.z = z

    local ox, oy, oz = x, y, z

    print("Determining turtle orientation")

    local ups = 0
    local stuck = true
    local turns = 0
    while stuck do
      for i=1,4 do
        if bak.forward() then
          x, y, z = gps.locate()

          local dx = sign((x - gx) * scale.x)
          local dz = sign((z - gz) * scale.z)

          x = (x + offset.x) * scale.x
          y = (y + offset.y) * scale.y
          z = (z + offset.z) * scale.z

          bak.facing.x = dx
          bak.facing.z = dz

          bak.position.x = x
          bak.position.y = y
          bak.position.z = z

          print(string.format("Pos x=%d, y=%d, z=%d", x, y, z))
          print(string.format("Facing x=%d, z=%d", bak.facing.x, bak.facing.z))

          bak.moveTo(ox, oy, oz)
          return true
        end
        bak.turnRight()
        turns = turns + 1
      end

      if stuck then
        if not bak.up() then 
          print("Turtle appears to be trapped, and cannot determine its rotation.")
          return false
        end
        ups = ups + 1
      end
    end

    for i=1,ups do
      bak.down()
    end

    return false
  end

  function isModemSelected()
    local detail = turtle.getItemDetail()
    return (detail ~= nil and detail.name == "ComputerCraft:CC-Peripheral" and detail.damage == 1)
  end

  for i=1,16 do
    turtle.select(i)
    if isModemSelected() then
      print("Equipping modem to make gps query.")
      turtle.equipLeft() -- equip modem
      local result = query()
      print("Unequipping modem again.")
      turtle.equipLeft() -- unequip modem
      return result
    end
  end

  -- Find an empty spot in the inventory.
  local foundEmptySlot = false
  for i=1,16 do
    if turtle.getItemCount(i) == 0 then
      turtle.select(i)
      foundEmptySlot = true
      break
    end
  end

  if foundEmptySlot then 
    turtle.equipLeft()
    if isModemSelected() then
      print("Found a modem in my left hand.")
      hasModem = true
    end
    turtle.equipLeft()

    if hasModem then
      return query()
    end

    turtle.equipRight()
    if isModemSelected() then
      print("Found a modem in my right hand.")
      hasModem = true
    end
    turtle.equipRight()

    if hasModem then
      return query()
    end

    print("Turtle has no modem in inventory or in equipment.")
    return false
  else 
    print("Turtle has no space to check to see if it has a modem.")
    print("Trying to query, hoping for the best.")
    return query()
  end
end

function bak.mineDFS(options)
  local diggable = options.blocks;
  local boundary = options.boundary;
  local update = options.update;

  function inBounds(p)
    if not boundary then
      return true
    end
    if (boundary.minX and p.x < boundary.minX) or
       (boundary.minY and p.y < boundary.minY) or
       (boundary.minZ and p.z < boundary.minZ) or
       (boundary.maxX and p.x > boundary.maxX) or
       (boundary.maxY and p.y > boundary.maxY) or 
       (boundary.maxZ and p.z > boundary.maxZ) then
       return false
    end
    return true
  end

  function isDiggable(name)
    if diggable and not diggable.contains(name) then
      print(" ", name, " is not diggable.")
    end
    return not diggable or diggable.contains(name)
  end

  function getPos()
    return {x=bak.position.x, y=bak.position.y, z=bak.position.z}
  end

  local visited = {}
  local frontier = bak.Stack()
  frontier.push(getPos())

  function pos2str(p)
    return "(" .. p.x .. ", " .. p.y .. ", " .. p.z .. ")"
  end

  function pushMaybe(adjacent, inspector)
    if visited[adjacent] or not inBounds(adjacent) then
      print("  ", pos2str(adjacent), " is visited or out of bounds.")
      return false
    end
    local success, data = inspector()
    print("  ", pos2str(adjacent), " existence: ", success, " (", data, ")")
    if success and isDiggable(data.name) then 
      print("  pushing ", pos2str(adjacent))
      frontier.push(adjacent)
      return true
    end
    return false
  end

  while not frontier.isEmpty() do
    if update then
      update()
    end

    local vertex = frontier.pop()
    if not visited[vertex] then
      visited[vertex] = 1
      print("Expanding: <", vertex.x, ", ", vertex.y, ", ", vertex.z, ">")
      print("  frontier size: ", frontier.size())

      bak.moveTo(vertex.x, vertex.y, vertex.z)
      pushMaybe({
        x=vertex.x, 
        y=vertex.y - 1, 
        z=vertex.z
      }, turtle.inspectDown)
      for i=1,4 do 
        pushMaybe({
          x=vertex.x + bak.facing.x, 
          y=vertex.y, 
          z=vertex.z + bak.facing.z
        }, turtle.inspect)
        bak.turnRight()
      end
      pushMaybe({
        x=vertex.x, 
        y=vertex.y + 1, 
        z=vertex.z
      }, turtle.inspectUp)
    end
  end

end

function bak.testBasicMovement()
  print("Testing relative movement.")
  bak.debugDump()
  bak.moveBy(0, 0, 2)
  bak.debugDump()
  bak.moveBy(2, 0, 0)
  bak.debugDump()
  bak.moveBy(0, 2, 0)
  bak.debugDump()
  bak.moveBy(-2, -2, -2)
  bak.debugDump()

  print(" ")
  print("Testing absolute movement.")
  bak.debugDump()
  bak.moveTo(0, 5, 0)
  bak.debugDump()
  bak.moveTo(0, 1, 0)
  bak.debugDump()
  bak.moveTo(0, 0, -1)
  bak.debugDump()
  bak.moveTo(-2, 1, 2)
  bak.debugDump()
  bak.moveTo(0, 0, 0)
  bak.debugDump()
  bak.setFacing(0, 1)
  bak.debugDump()
end

function bak.testAggroMovement()
  bak.aggressive = true

  bak.moveTo(0, 0, 5)
  bak.moveBy(0, 10, 0)
  bak.moveBy(1, 0, 0)
  bak.resetPosition()

  bak.aggressive = false
end
