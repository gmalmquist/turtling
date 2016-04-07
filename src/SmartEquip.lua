function smartEquip()
  function selectBlankSpace()
    for i=1,16 do
      if turtle.getItemCount(i) == 0 then
        turtle.select(i)
        return true
      end
    end
    return false
  end

  if not selectBlankSpace() then
    return false
  end

  turtle.equipLeft()
  local hasLeft = (turtle.getItemCount() == 1)
  local leftName = "nothing"
  if hasLeft then
    leftName = turtle.getItemDetail().name
  end
  turtle.equipLeft()

  turtle.equipRight()
  local hasRight = (turtle.getItemCount() == 1)
  local rightName = "nothing"
  if hasRight then
    rightName = turtle.getItemDetail().name
  end
  turtle.equipRight()

  print("Starting with ", leftName, " and ", rightName)

  if hasLeft and hasRight then
    print("My hands are full.")
    return
  end

  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      local name = turtle.getItemDetail(i).name
      if not hasLeft and turtle.equipLeft() then
        print("Equiping ", name, " in left hand.")
        hasLeft = true
      elseif not hasRight and turtle.equipRight() then
        print("Equiping ", name, " in right hand.")
        hasRight = true
      else
        return
      end
    end
  end
end

smartEquip()