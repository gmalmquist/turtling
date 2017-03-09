-- Portable tree farming script.
#include /src/Library.lua

WALL_ID = "minecraft:planks"
DIRT_ID = "minecraft:dirt"
PATH_ID = "minecraft:cobblestone"
LITE_ID = "minecraft:torch"
SEED_ID = "minecraft:sapling"
CHEST_ID = "minecraft:chest"
GRASS_ID = "minecraft:grass"
LEAVES_ID = "minecraft:leaves"
WOOD_ID = "minecraft:log"
FLOOR_ID = "minecraft:planks"

bak.eats = bak.Set({
  DIRT_ID, LEAVES_ID, GRASS_ID, WOOD_ID,
  "minecraft:yellow_flower",
  "minecraft:red_flower",
  "minecraft:tallgrass"
})

function is(inspector, name, damage)
  local there, details = inspector()
  if not there then
    return string.len(name) == 0
  end
  return details.name == name and (damage == nil or details.damage == damage)
end

function isF(name, damage)
  return is(turtle.inspect, name, damage)
end

function isU(name, damage)
  return is(turtle.inspectUp, name, damage)
end

function isD(name, damage)
  return is(turtle.inspectDown, name, damage)
end

function isR(name, damage)
  bak.turnRight()
  local v = isF(name, damage)
  bak.turnLeft()
  return v
end

function isL(name, damage)
  bak.turnLeft()
  local v = isF(name, damage)
  bak.turnRight()
  return v
end

function isB(name, damage)
  bak.turnLeft()
  bak.turnLeft()
  local v = isF(name, damage)
  bak.turnLeft()
  bak.turnLeft()
  return v
end


function generateWall(rows, cols)
  local col_length = 2 * rows + 2
  local path_length = col_length * (cols+1) - 1

  local width = 2 * cols + 3
  local depth = 2 * rows + 3
  -- Place starting chests.
  if not (
    bak.turnLeft() and
    bak.replace(CHEST_ID) and
    bak.turnLeft() and
    bak.replace(CHEST_ID) and
    bak.turnRight() and
    bak.turnRight()
  ) then
    return false
  end

  if not (
    bak.up() and
    bak.turnLeft() and
    bak.forward() and
    bak.turnRight()
  ) then
    return false
  end

  for i=3,depth do
    bak.forward()
    bak.replaceDown(WALL_ID)
  end

  bak.turnRight()
  for i=2,width do
    bak.forward()
    bak.replaceDown(WALL_ID)
  end

  bak.turnRight()
  for i=2,depth do
    bak.forward()
    bak.replaceDown(WALL_ID)
  end

  bak.turnRight()
  for i=2,(width-2) do
    bak.forward()
    bak.replaceDown(WALL_ID)
  end

  bak.forward()
  bak.turnRight()
  bak.forward()
  bak.down()

  return true
end

function generatePath(rows, cols)
  local col_length = 2 * rows + 2
  local path_length = col_length * (cols+1) - 1

  local width = 2 * cols + 3
  local depth = 2 * rows + 3

  function layDownPath(index)
    local col_index = math.floor(index / (col_length))
    local col_pos = index % (col_length)
    local tx = col_index * 2
    local tz = col_pos
    if col_pos > 2 * rows then
      tz = 2 * rows
      tx = 2 * col_index + (col_pos - 2 * rows)
    end
    if col_index % 2 == 1 then
      tz = (2 * rows) - tz
    end
    print(string.format("%d: (x=%d, z=%d), ci=%d, cp=%d", index, tx, tz, col_index, col_pos))
    bak.moveTo(tx, 0, tz)
    bak.replaceDown(PATH_ID)

    if col_pos < 2 * rows and col_index < cols then 
      local face = 1
      local place = (col_pos % 2 == 0) and LITE_ID or SEED_ID
      bak.faceX(face)
      bak.forward()
      bak.replaceDown(DIRT_ID)
      bak.back()
      bak.replace(place)
    end
  end

  for i=0,(path_length-1) do
    layDownPath(i)
  end

  bak.moveTo(0, 0, 0)
  bak.faceZ(1)
  return true
end

function generatePlane(rows, cols)
  local col_length = 2 * rows + 2
  local path_length = col_length * (cols+1) - 1

  local width = 2 * cols + 3
  local depth = 2 * rows + 3

  bak.moveTo(-1, 0, 0)
  bak.replaceDown(FLOOR_ID)
  bak.moveTo(-1, 0, -1)
  bak.replaceDown(FLOOR_ID)
  bak.moveTo(0, 0, -1)
  bak.replaceDown(FLOOR_ID)
  for z=-2,depth-1 do
    bak.moveTo(-2, 0, z)
    bak.replaceDown(FLOOR_ID)
  end
  for x=-1,width-1 do
    bak.moveTo(x, 0, depth-1)
    bak.replaceDown(FLOOR_ID)
  end
  for z=0,depth+1 do
    bak.moveTo(width-1, 0, depth-1 - z)
    bak.replaceDown(FLOOR_ID)
  end
  for x=0,width do
    bak.moveTo(width-1-x, 0, -2)
    bak.replaceDown(FLOOR_ID)
  end
  bak.moveTo(0, 0, 0)
  return true
end

function setup(rows, cols)
  if rows <= 0 or cols <= 0 then
    print(string.format("Invalid dimensions: %d x %d", rows, cols))
    return
  end

  local width = 2 * cols + 3
  local depth = 2 * rows + 3

  local col_length = 2 * rows + 2
  local path_length = col_length * (cols+1) - 1

  bak.aggressive = true
  if generatePlane(rows, cols) then
    print("Generated plane.")
  else
    print("Could not generate plane.")
    return false
  end

  if generateWall(rows, cols) then
    print("Generated wall.")
  else
    print("Could not set up wall.")
    return false
  end

  if generatePath(rows, cols) then
    print("Generated path.")
  else
    print("Could not generate path.")
    return false
  end
  bak.aggressive = false
  return true
end

function localize()
  local axes = {
    left = {x=-1, z=0},
    right = {x=1, z=0},
    forward = {x=0, z=1},
    back = {x=0, z=-1}
  }

  function done(facing)
    bak.position = {x=0, y=0, z=0}
    bak.facing = facing
    print(string.format("Localized, facing x=%d, z=%d", facing.x, facing.z))
    bak.faceZ(1)
    return true
  end

  function step()
    if isD(WALL_ID) then
      bak.forward()
      if isD("") then
        bak.back() -- air
        bak.turnRight()
      end
      return false
    end

    if isD(CHEST_ID) then
      bak.turnRight()
      bak.forward()
      bak.down()
      if isD(PATH_ID) then
        return done(axes.forward)
      end
      bak.up()
      bak.back()
      bak.turnLeft()
      bak.turnLeft()
      bak.forward()
      bak.down()
      return done(axes.right)
    end

    if isD(PATH_ID) then
      if isF(CHEST_ID) and isL(CHEST_ID) then
        return done(axes.left)
      end

      if isF(CHEST_ID) and isR(CHEST_ID) then
        return done(axes.back)
      end

      if isL(CHEST_ID) and isB(CHEST_ID) then
        return done(axes.forward)
      end

      if isR(CHEST_ID) and isB(CHEST_ID) then
        return done(axes.right)
      end
    end

    if isF(WALL_ID) then
      bak.up()
      bak.forward()
      bak.turnRight()
      return false
    end

    if isD(PATH_ID) then
      if isF("") then
        bak.forward()
      else
        bak.turnRight()
      end
      return false
    end

    if isU(WOOD_ID) or isU(LEAVES_ID) then
      bak.up()
      return false
    end

    if isD("") or isD(WOOD_ID) or isD(LEAVES_ID) then
      bak.down()
      return false
    end

    if isD(DIRT_ID) or isD(GRASS_ID) then
      if isF("") then
        bak.forward()
      else
        bak.turnRight()
      end
      return false
    end

    print("I have no idea where I am.")
    return true
  end

  while true do
    if step() then
      break
    end
  end
end

function resupply()
  localize()
  bak.faceZ(-1)
  local keep = bak.Set({
    "minecraft:coal",
    DIRT_ID,
    LITE_ID,
    SEED_ID
  })
  local dumped = true
  while true do
    for i=1,16 do
      local detail = turtle.getItemDetail(i)
      if detail ~= nil and not keep.contains(detail.name) then
        bak.select(i)
        dumped = bak.drop() and dumped
      end
      if detail ~= nil and keep.contains(detail.name) then
        keep.remove(detail.name) -- only keep one stack.
      end
    end
    if dumped then
      break
    end
  end
  bak.faceX(-1)
  -- Make sure we have the minimum amount of fuel to safely function.
  while turtle.getFuelLevel() < 8 * 8 * 2 * 8 * 2 do
    turtle.suck()
    if bak.trySelect("minecraft:coal") then
      bak.refuel()
    end
  end
  bak.faceZ(1)
end

function maintainTrees()
  local col = 0
  local i = 0

  function tendSapling()
    if isF(SEED_ID) then
      return
    end
    bak.forward()
    if not (isD(DIRT_ID) or isD(GRASS_ID)) then
      bak.replaceDown(DIRT_ID)
    end
    while isU(LEAVES_ID) or isU(WOOD_ID) do
      bak.up()
      for j=1,4 do
        if isF(LEAVES_ID) or isF(WOOD_ID) then
          bak.dig()
          bak.suck()
        end
        bak.turnRight()
      end
    end
    while not (isD(DIRT_ID) or isD(GRASS_ID)) do
      bak.down()
    end
    for j=1,4 do
      bak.suck()
      bak.turnRight()
    end
    bak.faceX(1)
    bak.back()
    bak.replace(SEED_ID)
  end

  function turnCorner()
    bak.faceX(1)
    if isF(WALL_ID) then
      return true -- done
    end
    bak.forward()
    bak.forward()
    if col % 2 == 0 then
      bak.turnRight()
    else
      bak.turnLeft()
    end
    return false
  end

  while true do
    if isF("") then
      i = i + 1
      if i % 2 == 0 then
        bak.faceX(1)
        if isF(WALL_ID) then
          return -- at the end.
        end
        tendSapling()
      end
      if col % 2 == 0 then
        bak.faceZ(1)
      else
        bak.faceZ(-1)
      end
      bak.forward()
    elseif isF(WALL_ID) then
      if turnCorner() then
        return -- we reached the end.
      end
      col = col + 1
    end
  end
end


function maintainenceLoop()
  while true do
    resupply()
    maintainTrees()
  end
end


function main(args)
  print("Running Portable Tree Farm program.")
  if (# args) == 0 then
  end

  if (# args) == 3 and args[1] == "setup" then
    local rows = tonumber(args[2])
    local cols = tonumber(args[3])
    return setup(rows, cols)
  end

  if (# args) == 1 and args[1] == "work" then
    maintainenceLoop()
    return
  end

  print("Usage:")
  print("  TreeFarm setup <rows> <cols>")
  print("  TreeFarm work")
end

main({...})
