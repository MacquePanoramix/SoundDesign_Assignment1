--
-- This game is hastily hacked together by Martijn Frazer
-- For the CuriousU sound design for games workshop
-- at UTwente in August 2017
--
-- It requires Love in order to run, which can be obtained at: http://love2d.org
--
-- If you want to get in touch with me, use e-mail: martijn@martijnfrazer.nl
-- or Twitter: @martijnfrazer
--

_ = require "lib.lume"
coil = require "lib.coil"
flux = require "lib.flux"

font = {
  big = love.graphics.newFont("font/visitor2.ttf", 64),
  medium = love.graphics.newFont("font/visitor2.ttf", 36),
  small = love.graphics.newFont("font/visitor2.ttf", 24)
}

game = {
  level = require "src.level",
  player = require "src.player",
  enemy = require "src.enemy",
  num = 1,
  x = 0,
  level_width = 0,
  done = false
}

reqs = {
  {"walk", "jump", "end"},
  {"coin", "splash"},
  {"kill", "hurt"},
  {}
}

sfx = {}

function playSfx(source)
  if source ~= nil then
    source:seek(0)
    source:play()
  end
end

function start()
  game.x = 0
  game.enemy.load()
  game.level.load(game.num)
  game.player.load()
end

function love.load()
  math.randomseed(os.time())

  love.graphics.setDefaultFilter("nearest", "nearest")

  -- get all sfx
  for i, file in ipairs(love.filesystem.getDirectoryItems("snd")) do
    if string.find(file, ".wav", 1, true) ~= nil then
      local name = file:gsub(".wav", "")

      sfx[name] = love.audio.newSource("snd/"..file, "static")
    end
  end

  -- determine which level we are at
  if love.filesystem.getInfo("progress") == nil then
    love.filesystem.write("progress", "1")
  end
  local num = love.filesystem.read("progress")
  num = tonumber(num)
  if num == nil
  or love.filesystem.getInfo("data/level_"..num..".txt") == nil then
    num = 1
  end
  game.num = num

  -- go go go!
  start()
end

function love.update(dt)
  if not game.done then
    game.player.update(dt)
    game.enemy.update(dt)

    coil.update(dt)
    flux.update(dt)
  end
end

function love.draw()
  if not game.done then
    love.graphics.scale(2)
    love.graphics.translate(game.x, 0)

    game.level.draw()
    game.enemy.draw()
    game.player.draw()
    game.level.drawWater()

    love.graphics.translate(-game.x, 0)
    love.graphics.scale(0.5)

    -- draw requirements
    local text_y = 50
    love.graphics.setFont(font.medium)
    _.each(reqs[game.num], function(name)

      if sfx[name] == nil then
        love.graphics.setColor(255 / 255, 255 / 255, 255 / 255)
      else
        love.graphics.setColor(155 / 255, 255 / 255, 170 / 255)

				love.graphics.rectangle("fill", 700, text_y + 12, 180, 3)
      end

      love.graphics.printf(string.upper(name..".wav"), 700, text_y, 180, "right")

      text_y = text_y + 30
    end)
    love.graphics.setColor(255, 255, 255)
  else
    love.graphics.setBackgroundColor(39 / 255, 240 / 255, 133 / 255)

    love.graphics.setColor(255, 255, 255)
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line", 20, 20, 860, 460)


    love.graphics.setColor(255, 75, 41)
    love.graphics.setFont(font.big)
    love.graphics.printf("Congratulations!", 0, 80, 900, "center")
    love.graphics.printf("You've won!", 0, 130, 900, "center")

    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(font.medium)
    love.graphics.printf("You are you now a certified professional audio game person.", 100, 220, 700, "center")
    love.graphics.printf("Please print this certificate as proof and carry it with you at all times.", 100, 300, 700, "center")

    love.graphics.setColor(100, 100, 100)
    love.graphics.setFont(font.small)
    love.graphics.printf("Thank you for playing. I hope you had a good time.", 100, 380, 700, "center")

    love.graphics.setColor(255, 75, 41)
    love.graphics.printf("If you want to play again, press numbers 1 - 4!", 100, 400, 700, "center")

    love.graphics.setColor(100, 100, 100)
    love.graphics.printf("Made by Martijn Frazer", 100, 440, 700, "center")

    love.graphics.setColor(255, 255, 255)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if not isrepeat then
    if _.find({"1", "2", "3", "4"}, key)
		and love.filesystem.getInfo("data/level_"..key..".txt") then
      game.num = tonumber(key)
      game.done = false
      start()
    else
      game.player.keypressed(key)
    end
  end
end

function love.keyreleased(key)
  game.player.keyreleased(key)
end
