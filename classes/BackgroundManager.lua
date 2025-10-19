-- Minesweeper Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.menuParticles = {}
    instance.gameParticles = {}
    instance.time = 0
    instance:initMenuParticles()
    instance:initGameParticles()
    return instance
end

function BackgroundManager:initMenuParticles()
    self.menuParticles = {}
    for _ = 1, 60 do
        table_insert(self.menuParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(2, 6),
            speed = math_random(20, 60),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.3, 1.5),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 8), -- Numbers 1-8
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 3,
            color = {math_random(0.3, 0.8), math_random(0.3, 0.8), math_random(0.5, 1)}
        })
    end
end

function BackgroundManager:initGameParticles()
    self.gameParticles = {}
    for _ = 1, 40 do
        table_insert(self.gameParticles, {
            x = math_random() * 1000,
            y = math_random() * 1000,
            size = math_random(1, 4),
            speed = math_random(10, 30),
            angle = math_random() * math_pi * 2,
            type = math_random() > 0.7 and "mine" or "number",
            number = math_random(1, 8),
            rotation = math_random() * math_pi * 2,
            rotationSpeed = (math_random() - 0.5) * 2,
            isGlowing = math_random() > 0.7,
            glowPhase = math_random() * math_pi * 2,
            color = math_random() > 0.5 and {0.8, 0.3, 0.3} or {0.3, 0.6, 0.8}
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update menu particles
    for _, particle in ipairs(self.menuParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
        particle.rotation = particle.rotation + particle.rotationSpeed * dt

        if particle.x < -50 then particle.x = 1050 end
        if particle.x > 1050 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1050 end
        if particle.y > 1050 then particle.y = -50 end
    end

    -- Update game particles
    for _, particle in ipairs(self.gameParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt
        particle.rotation = particle.rotation + particle.rotationSpeed * dt
        particle.glowPhase = particle.glowPhase + dt * 2

        if particle.x < -50 then particle.x = 1050 end
        if particle.x > 1050 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1050 end
        if particle.y > 1050 then particle.y = -50 end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Circuit board gradient background
    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 1.5 + progress * 5) + 1) * 0.03

        local r = 0.15 + progress * 0.1 + pulse
        local g = 0.2 + progress * 0.15 + pulse
        local b = 0.3 + progress * 0.25 + pulse

        love.graphics.setColor(r, g, b, 0.7)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Floating number particles
    for _, particle in ipairs(self.menuParticles) do
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.4
        local alpha = 0.3 + pulse * 0.4

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        love.graphics.scale(particle.size / 20, particle.size / 20)
        love.graphics.print(tostring(particle.type), -3, -4)
        love.graphics.pop()
    end

    -- Grid pattern with mine symbols
    love.graphics.setColor(0.3, 0.4, 0.6, 0.15)
    local gridSize = 60
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            if math_random() > 0.8 then
                love.graphics.setColor(0.8, 0.3, 0.3, 0.1)
                love.graphics.circle("line", x + gridSize/2, y + gridSize/2, gridSize/4)
            else
                love.graphics.setColor(0.3, 0.4, 0.6, 0.1)
                love.graphics.rectangle("line", x, y, gridSize, gridSize)
            end
        end
    end
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Deep blue grid background with wave effect
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local wave = math_sin(progress * 10 + time * 2) * 0.02
        local r = 0.08 + wave
        local g = 0.12 + progress * 0.08 + wave
        local b = 0.2 + progress * 0.15 + wave

        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Game particles (mines and numbers)
    for _, particle in ipairs(self.gameParticles) do
        local alpha = 0.25
        if particle.isGlowing then
            local glow = (math_sin(particle.glowPhase) + 1) * 0.15
            alpha = 0.2 + glow
        end

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)

        if particle.type == "mine" then
            love.graphics.scale(particle.size / 15, particle.size / 15)
            love.graphics.circle("line", 0, 0, 6)
            love.graphics.circle("line", 0, 0, 3)
        else
            love.graphics.scale(particle.size / 12, particle.size / 12)
            love.graphics.print(tostring(particle.number), -3, -4)
        end

        love.graphics.pop()
    end

    -- Subtle grid lines resembling minefield
    love.graphics.setColor(0.25, 0.35, 0.55, 0.2)
    local cellSize = 30
    for x = 0, screenWidth, cellSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, cellSize do
        love.graphics.line(0, y, screenWidth, y)
    end
end

return BackgroundManager