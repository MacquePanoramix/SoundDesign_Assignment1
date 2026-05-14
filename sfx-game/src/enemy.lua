local enemy = {}

local locations = {}
local imgs = {}
local index = 0
local anim = nil
local dead = {}

function enemy.load()
  locations = {}
  dead = {}

  table.insert(imgs, love.graphics.newImage("img/enemy-1.png"))
  table.insert(imgs, love.graphics.newImage("img/enemy-2.png"))
  if anim ~= nil then
    anim:stop()
    anim = nil
  end
  anim = coil.add(function()
    while true do
      coil.wait(0.2)
      index = (index + 1) % 2
    end
  end)
end

function enemy.create(x, y)
  table.insert(locations, {x = x, y = y, direction = "left"})
end

function enemy.update(dt)
  for i, e in ipairs(locations) do
    if not game.level.touchSolid(e.x, e.y) then
      e.y = e.y + 1
    end

    if e.direction == "left" then
      e.x = e.x - 0.5

      if game.level.touchSolid(e.x - 0.5, e.y - 10) then
        e.direction = "right"
      end
    else
      e.x = e.x + 0.5

      if game.level.touchSolid(e.x + 0.5, e.y - 10) then
        e.direction = "left"
      end
    end
  end

  for i, e in _.ripairs(dead) do
    e.r = e.r + e.vr

    e.x = e.x + e.vx
    e.y = e.y + e.vy

    e.vy = e.vy + 0.3
    e.vy = math.min(e.vy, 6)

    e.vr = e.vr * 0.95

    if e.y > 300 then
      table.remove(dead, i)
    end
  end
end

function enemy.draw()
  for i, e in ipairs(locations) do
    love.graphics.draw(imgs[index + 1], e.x, e.y, 0, e.direction == "left" and 1 or -1, 1, 10, 20)
  end

  for i, e in ipairs(dead) do
    love.graphics.draw(imgs[1], e.x, e.y, e.r, e.direction == "left" and 1 or -1, 1, 10, 20)
  end
end

function enemy.stomp(x, y, mode)
  local result = false

  if mode == "fall" then
    for i, e in _.ripairs(locations) do
      if not result
      and x < e.x + 20
      and x + 20 > e.x
      and y < e.y + 20
      and y + 20 > e.y then

        result = true

        table.remove(locations, i)
        table.insert(dead, {
          x = e.x,
          y = e.y,
          vx = (math.random(-15, 15) / 10) * 1.5,
          vy = -(math.random(35) / 10) - 5,
          vr = (math.random(-2.5, 2.5) / 10) * 1.25,
          r = 0,
          direction = e.direction
        })

        playSfx(sfx.kill)
      end
    end
  end

  return result
end

function enemy.hurt(x, y)

  local result = false

  for i, e in ipairs(locations) do
    if not result
    and x < e.x + 20
    and x + 20 > e.x
    and y < e.y + 20
    and y + 20 > e.y then

      result = true
    end
  end

  return result
end

return enemy
