local level = {}

local sb = {}
local solid = {}
local mountain = {
  quad = nil,
  img = nil,
  x = 0,
  y = nil,
  h = nil
}
local coins = {
  index = 0,
  img = nil,
  cells = {},
  locations = {},
  anim = nil
}
local water = {
  index = 0,
  imgs = {},
  locations = {},
  anim = nil
}
local width = nil
local sfxComplete = false
local TILE_SIZE = 20
local IS_SOLID = {"=", "X", "M", "B"}
local TILE_NAME = {}
TILE_NAME["#"] = "clouds"
TILE_NAME["|"] = "grass"
TILE_NAME["="] = "surface"
TILE_NAME["X"] = "ground"
TILE_NAME["M"] = "metal"
TILE_NAME["B"] = "brick"
TILE_NAME["W"] = "water"
TILE_NAME["C"] = "coin"
TILE_NAME["E"] = "enemy"

level.balloon = {
  img = nil,
  x = nil,
  y = nil,
  w = 20,
  h = 40
}

function level.load(num)
  local types = _.keys(TILE_NAME)
  local surface_y = nil

  sb = {}
  solid = {}
  width = nil
  coins.locations = {}
  water.locations = {}

  table.insert(water.imgs, love.graphics.newImage("img/water-1.png"))
  table.insert(water.imgs, love.graphics.newImage("img/water-2.png"))
  if water.anim ~= nil then
    water.anim:stop()
  end
  water.anim = coil.add(function()
    while true do
      coil.wait(0.2)
      water.index = (water.index + 1) % 2
    end
  end)

  -- create sprite batches
  for i, type in ipairs(types) do
    local file = "img/"..TILE_NAME[type]..".png"

    if love.filesystem.getInfo(file) then
      sb[type] = love.graphics.newSpriteBatch(love.graphics.newImage(file))
    end
  end

  -- read level data
  local y = 0
  for line in love.filesystem.lines("data/level_"..num..".txt") do
    line = _.trim(line)

    if not width then
      width = line:len()
      game.level_width = width * TILE_SIZE
    end

    local x = 0
    for char in line:gmatch"." do
      -- only look at characters we know
      if _.find(types, char) ~= nil then
        if TILE_NAME[char] == "coin" then
          if coins.img == nil then
            -- init coin
            coins.img = love.graphics.newImage("img/coin.png")

            coins.anim = coil.add(function()
              while true do
                coil.wait(.08)

                coins.index = (coins.index + 1) % #coins.cells
              end
            end)

            for i = 0, 9 do
              table.insert(coins.cells, love.graphics.newQuad(
                i * 10, 0, 10, 10, 100, 10
              ))
            end
          end

          -- add coin location
          table.insert(coins.locations, {x = x * TILE_SIZE, y = y * TILE_SIZE})

        elseif TILE_NAME[char] == "water" then

          table.insert(water.locations, {x = x * TILE_SIZE, y = y * TILE_SIZE})

        elseif TILE_NAME[char] == "enemy" then

          game.enemy.create(x * TILE_SIZE, y * TILE_SIZE)

        else
          if TILE_NAME[char] == "surface" and not surface_y then
            surface_y = y
          end

          -- add tile to sprite batch for drawing
          sb[char]:add(x * TILE_SIZE, y * TILE_SIZE, 0, 1, 1, TILE_SIZE * 0.5)

          -- make list of solid tiles
          if _.find(IS_SOLID, char) ~= nil then
            table.insert(solid, {
              x = x,
              y = y,
              name = TILE_NAME[char]
            })
          end
        end
      end

      x = x + 1
    end
    y = y + 1
  end

  -- setup mountain
  mountain.y = surface_y
  mountain.img = love.graphics.newImage("img/mountains.png")
  mountain.img:setWrap("repeat", "repeat")
  mountain.h = mountain.img:getHeight()
  mountain.quad = love.graphics.newQuad(0, 0,
    width * TILE_SIZE, mountain.h,
    mountain.img:getDimensions()
  )

  -- setup end balloon
  level.balloon.img = love.graphics.newImage("img/balloon.png")
  level.balloon.x = (width - 20) * TILE_SIZE
  level.balloon.y = 6 * TILE_SIZE

  -- see if all sfx are there
  sfxComplete = true
  _.each(reqs[tonumber(game.num)], function(name)
    if sfx[name] == nil then
      sfxComplete = false
    end
  end)
end

function level.draw()
  love.graphics.setBackgroundColor(41 / 255, 173 / 255, 255 / 255)

  -- draw mountains
  love.graphics.draw(mountain.img, mountain.quad, mountain.x - (game.x * 0.5), (mountain.y * TILE_SIZE) - mountain.h)

  -- draw sprite batches
  for i in pairs(sb) do
    love.graphics.draw(sb[i])
  end

  -- draw coins
  for i, coin in ipairs(coins.locations) do
    love.graphics.draw(coins.img, coins.cells[coins.index + 1], coin.x - 5, coin.y + 5)
  end

  -- draw balloon
  love.graphics.draw(level.balloon.img, level.balloon.x, level.balloon.y)
end

function level.drawWater()
  for i, w in ipairs(water.locations) do
    love.graphics.draw(water.imgs[water.index + 1], w.x, w.y + 1, 0, 1, 1, 0.5 * TILE_SIZE)
  end
end

function level.touchSolid(x, y)
  local result = false

  x = x + (0.5 * TILE_SIZE)

  for i, tile in ipairs(solid) do
    if not result and x >= (tile.x * TILE_SIZE)
    and x <= (tile.x * TILE_SIZE) + TILE_SIZE
    and y > (tile.y * TILE_SIZE)
    and y < (tile.y * TILE_SIZE) + TILE_SIZE then
      result = true
    end
  end

  return result
end

function level.touchBalloon(x, y)
  local result = false

  if sfxComplete
  and x >= level.balloon.x
  and x <= level.balloon.x + level.balloon.w
  and y >= level.balloon.y
  and y <= level.balloon.y + level.balloon.h then
    result = true
  end

  return result
end

function level.touchCoin(x, y)
  local result = false

  y = y - 20
  x = x - 10

  for i, coin in _.ripairs(coins.locations) do
    if x < coin.x + 10
    and x + 20 > coin.x
    and y < coin.y + 10
    and y + 20 > coin.y then
      result = true

      table.remove(coins.locations, i)
    end
  end

  return result
end

function level.touchWater(x, y)
  local result

  x = x + (0.5 * TILE_SIZE)

  for i, w in ipairs(water.locations) do
    if not result and x >= w.x
    and x <= (w.x + TILE_SIZE)
    and y >= w.y
    and y <= (w.y * TILE_SIZE) then
      result = true
    end
  end

  return result
end

function level.finish()
  if game.num < 4 then
    game.num = game.num + 1
    love.filesystem.write("progress", game.num)
    start()
  else
    game.done = true
  end
end

return level
