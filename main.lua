-- Minesweeper Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Game = require("classes/Game")
local Menu = require("classes/Menu")
local BackgroundManager = require("classes/BackgroundManager")

local game, menu, backgroundManager
local screenWidth, screenHeight
local gameState = "menu"

local function updateScreenSize()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
end

function love.load()
    love.window.setTitle("Minesweeper")
    love.graphics.setLineStyle("smooth")
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))

    game = Game.new()
    menu = Menu.new()
    backgroundManager = BackgroundManager.new()

    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()

    if gameState == "menu" then
        menu:update(dt, screenWidth, screenHeight)
    elseif gameState == "playing" then
        game:update(dt)
    elseif gameState == "options" then
        menu:update(dt, screenWidth, screenHeight)
    end

    backgroundManager:update(dt)
end

function love.draw()
    if gameState == "menu" or gameState == "options" then
        backgroundManager:drawMenuBackground(screenWidth, screenHeight)
    elseif gameState == "playing" then
        backgroundManager:drawGameBackground(screenWidth, screenHeight)
    end

    if gameState == "menu" or gameState == "options" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    end
end

function love.mousepressed(x, y, button, istouch)
    if gameState == "menu" then
        local action = menu:handleClick(x, y, "menu")
        if action == "start" then
            gameState = "playing"
            game:startNewGame(menu:getDifficulty(), menu:getBoardSize())
        elseif action == "options" then
            gameState = "options"
        elseif action == "quit" then
            love.event.quit()
        end
    elseif gameState == "options" then
        local action = menu:handleClick(x, y, "options")
        if not action then return end
        if action == "back" then
            gameState = "menu"
        elseif action:sub(1, 4) == "size" then
            local size = action:sub(6)
            menu:setBoardSize(size)
        elseif action:sub(1, 10) == "difficulty" then
            local difficulty = action:sub(12)
            menu:setDifficulty(difficulty)
        end
    elseif gameState == "playing" then
        if game:isGameOver() then
            gameState = "menu"
        else
            game:handleClick(x, y, button)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" or gameState == "options" then
            gameState = "menu"
        else
            love.event.quit()
        end
    elseif key == "r" and gameState == "playing" then
        game:resetGame()
    elseif key == "f" and gameState == "playing" then
        game:toggleFlagMode()
    end
end

function love.resize(w, h)
    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end