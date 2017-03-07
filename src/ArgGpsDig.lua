#include GpsDig.lua

local dx, dy, dz = ...

executeGpsDig{
  start={x=0, y=0, z=0},
  delta={x=tonumber(dx), y=tonumber(dy), z=tonumber(dz)}
}
