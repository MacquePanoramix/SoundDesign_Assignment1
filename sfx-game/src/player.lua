local player = {}

local img = {
  still = {frame = {}},
  walk = {frame = {}},
  jump = {frame = {}},
  fall = {frame = {}}
}
local interactive = true
local direction = "right"
local mode = "still"
local index = 0
local x = 30
local y = 50
local vx = 0
local vy = 0
local speed = {
  walk = 2,
  fall = 6,
  jump = 5
}
local walkSfx = nil
local inWater = false
local drops = {}
local isHurt = false
local hurtCount = 0

local task = nil

function doWalkSfx()
  if walkSfx ~= nil then
    walkSfx:stop()
  end

  walkSfx = coil.add(function()
    while true do
      playSfx(sfx.walk)

      coil.wait(0.2)
    end
  end)
end

function player.load()
  -- add images
  for i, type in pairs(_.keys(img)) do
    table.insert(img[type]["frame"], love.graphics.newImage("img/player-"..type.."-1.png"))
    table.insert(img[type]["frame"], love.graphics.newImage("img/player-"..type.."-2.png"))
    img[type]["width"] = img[type]["frame"][1]:getWidth()
    img[type]["height"] = img[type]["frame"][1]:getHeight()
  end

  -- animation task
  if task ~= nil then
    task:stop()
  end
  task = coil.add(function()
    while true do
      coil.wait(0.2)

      index = (index + 1) % 2
    end
  end)

  -- init
  interactive = true
  direction = "right"
  mode = "still"
  index = 0
  x = 30
  y = 50
  vx = 0
  vy = 0
end

function player.update(dt)

  for i, drop in _.ripairs(drops) do
    drop.x = drop.x + drop.vx
    drop.y = drop.y + drop.vy

    drop.vy = drop.vy + 0.3
    drop.vy = math.min(drop.vy, 10)

    if drop.y > 250 then
      table.remove(drops, i)
    end
  end

  if interactive then
    x = x + vx
    y = y + vy

    x = math.max(0, x)
    x = math.min(game.level_width - 20, x)

    if(vx ~= 0) then
      if(vx > 0) then
        while game.level.touchSolid(x, y - 20) do
          x = _.round(x - 1)
        end
      else
        while game.level.touchSolid(x, y - 20) do
          x = _.round(x + 1)
        end
      end
    end

    if mode == "jump" then
      vy = vy + 0.18
    else
      vy = vy + 0.5
    end

    vy = math.min(vy, speed.fall)

    if mode == "jump" and vy >= 0 then
      mode = "fall"
    end

    if mode == "jump" then

    elseif mode == "fall" then
      if game.level.touchSolid(x, y + 10) then
        if vx == 0
        or direction == "left" and vx > speed.walk
        or direction == "right" and vx < speed.walk then
          mode = "still"
          vx = 0
        else
          mode = "walk"
          doWalkSfx()
        end

        vy = 0
      end
    else
      while game.level.touchSolid(x, y) do
        y = _.round(y - 1)
      end
    end

    if(game.level.touchCoin(x, y)) then
      player.grabCoin()
    end

    if(game.level.touchBalloon(x, y)) then
      player.rideBalloon()
    end

    if(game.level.touchWater(x, y)) then
      if not inWater then
        inWater = true
        player.splash()
      end
    else
      if inWater then
        inWater = false
        player.splash()
      end
    end

    if not isHurt
    and game.enemy.stomp(x, y, mode) then
      mode = "jump"
      vy = -(speed.jump * 0.5)
    end

    if game.enemy.hurt(x, y) then
      player.hurt()
    end


    if (direction == "right"
    and (x + game.x) > (450 * 0.52))
    or (direction == "left"
    and (x + game.x) < (450 * 0.48)) then
      game.x = game.x - vx
      game.x = math.min(0, game.x)
      game.x = math.max(-game.level_width + 470, game.x)
    end
  end
end

function player.draw()
  if isHurt then
    hurtCount = hurtCount + 1

    if hurtCount % 4 < 2 then
      love.graphics.setColor(255, 255, 255, 50)
    else
      love.graphics.setColor(255, 255, 255)
    end

    if hurtCount > 20 then
      isHurt = false
      hurtCount = 0
    end
  end

  love.graphics.draw(img[mode]["frame"][index + 1], x, y,
    0, direction == "right" and 1 or -1, 1,
    img[mode]["width"] * 0.5, img[mode]["height"]
  )

  love.graphics.setColor(255, 255, 255)

  for i, drop in ipairs(drops) do
    love.graphics.setColor(150, 200, 255, drop.alpha)
    love.graphics.rectangle("fill", drop.x, drop.y, drop.size, drop.size)
  end
  love.graphics.setColor(255, 255, 255)
end

function player.keypressed(key)
  if(interactive) then
    if _.find({"left", "right"}, key) ~= nil then
      direction = key

      if mode == "still" then
        mode = "walk"

        doWalkSfx()
      end

      vx = speed.walk
      if direction == "left" then
        vx = vx * -1
      end
    end

    if (mode == "still" or mode == "walk")
    and (key == "x" or key == "up" or key == "space") then
      mode = "jump"
      vy = -speed.jump

      playSfx(sfx.jump)
      if walkSfx ~= nil then
        walkSfx:stop()
      end
    end
  end
end

function player.keyreleased(key)
  if(interactive) then
    if _.find({"left", "right"}, key) ~= nil then
      if mode == "walk" then
        mode = "still"
      end

      vx = 0
    end

    if mode == "jump" and (key == "x" or key == "up" or key == "space") then
      mode = "fall"
    end

    if walkSfx ~= nil then
      walkSfx:stop()
    end
  end
end

function player.rideBalloon()
  interactive = false

  mode = "jump"
  direction = "right"
  x = game.level.balloon.x + (game.level.balloon.w * 0.1)
  y = game.level.balloon.y + (game.level.balloon.h * 1.6)

  playSfx(sfx['end'])

  flux.to(game.level.balloon, 2, {y = -80})
    :ease("quadin")
    :onupdate(function()
      y = game.level.balloon.y + (game.level.balloon.h * 1.6)
    end)
    :oncomplete(game.level.finish)
end

function player.grabCoin()
  playSfx(sfx.coin)
end

function player.splash()
  playSfx(sfx.splash)

  for i = 1, 5 + math.random(10) do
    table.insert(drops, {
      x = x + math.random(-5, 5),
      y = y + math.random(-5, 5),
      vx = (math.random(-25, 25) / 10) * 1.5,
      vy = (-(math.random(30) / 10) - 3) * 1.5,
      size = math.random(2, 5),
      alpha = math.random(150, 255)
    })
  end
end

function player.hurt()
  if not isHurt then
    isHurt = true
    mode = "jump"
    vy = -(speed.jump * 0.5)
    vx = speed.walk * 2
    if direction == "right" then
      vx = -vx
    end

    playSfx(sfx.hurt)
  end
end

return player
