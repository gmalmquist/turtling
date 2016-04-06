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

bak = {
  facing={x=0,z=1},
  position={x=0,y=0,z=0},
  aggressive=false,
}

function bak.Stack()
  local stack = {index=0}

  function stack.push(value)
    stack[stack.index] = value
    stack.index = stack.index + 1
    print("Pushed ", stack.index, " = ", value)
  end

  function stack.pop()
    if stack.index > 0 then
      stack.index = stack.index - 1
      value = stack[stack.index]
      stack[stack.index] = nil
      print("Popped ", stack.index, " = ", value)
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

function bak.forward()
  while not turtle.forward() do
    if not bak.aggressive or not turtle.dig() then
      return false
    end
  end
  bak._addpos(bak.facing.x, 0, bak.facing.z)
  return true
end

function bak.up()
  while not turtle.up() do
    if not bak.aggressive or not turtle.digUp() then
      return false
    end
  end
  bak._addpos(0, 1, 0)
  return true
end

function bak.down()
  while not turtle.down() do
    if not bak.aggressive or not turtle.digDown() then
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
  if abs(x) < abs(z) then
    tryMove(bak.faceX, x)
    tryMove(bak.faceZ, z)
  else
    tryMove(bak.faceZ, z)
    tryMove(bak.faceX, x)
  end
  mover = (y>0) and bak.up or bak.down
  for i=1,abs(y) do
    mover()
  end
end

function bak.moveTo(x, y, z)
  local p = bak.position
  local dx, dy, dz = x-p.x, y-p.y, z-p.z
  bak.moveBy(dx, dy, dz)
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
      if turtle.turtle.getItemDetail(i).name == name then
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

function bak.selectItemName(name)
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      if turtle.getItemDetail(i).name == name then
        turtle.select(i)
        return true
      end
    end
  end
  return false
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
