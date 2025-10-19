-- Minesweeper Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_min = math.min
local math_sin = math.sin
local math_abs = math.abs
local math_max = math.max
local math_pi = math.pi
local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.boardSize = 9
    instance.cellSize = 40
    instance.board = {}
    instance.mineBoard = {}
    instance.gameOver = false
    instance.gameWon = false
    instance.firstClick = true
    instance.minesCount = 10
    instance.flagsCount = 0
    instance.revealedCount = 0
    instance.flagMode = false
    instance.animations = {}
    instance.cellParticles = {}
    instance.revealQueue = {}
    instance.startTime = 0
    instance.elapsedTime = 0

    instance:initBoard()

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateCellSize()
end

function Game:calculateCellSize()
    local maxSize = math_min(self.screenWidth, self.screenHeight) * 0.8
    self.cellSize = math_floor(maxSize / self.boardSize)
    self.boardX = (self.screenWidth - self.cellSize * self.boardSize) / 2
    self.boardY = (self.screenHeight - self.cellSize * self.boardSize) / 2 + 20
end

function Game:initBoard()
    self.board = {}
    self.mineBoard = {}
    for i = 1, self.boardSize do
        self.board[i] = {}
        self.mineBoard[i] = {}
        for j = 1, self.boardSize do
            self.board[i][j] = {
                revealed = false,
                flagged = false,
                mine = false,
                adjacentMines = 0,
                highlight = false
            }
            self.mineBoard[i][j] = false
        end
    end
end

function Game:placeMines(avoidRow, avoidCol)
    local minesPlaced = 0
    while minesPlaced < self.minesCount do
        local row = math_random(1, self.boardSize)
        local col = math_random(1, self.boardSize)

        -- Don't place mine on first click position or adjacent cells
        if not (math_abs(row - avoidRow) <= 1 and math_abs(col - avoidCol) <= 1) then
            if not self.mineBoard[row][col] then
                self.mineBoard[row][col] = true
                self.board[row][col].mine = true
                minesPlaced = minesPlaced + 1
            end
        end
    end
    self:calculateAdjacentMines()
end

function Game:calculateAdjacentMines()
    for i = 1, self.boardSize do
        for j = 1, self.boardSize do
            if not self.board[i][j].mine then
                local count = 0
                for di = -1, 1 do
                    for dj = -1, 1 do
                        local ni, nj = i + di, j + dj
                        if ni >= 1 and ni <= self.boardSize and nj >= 1 and nj <= self.boardSize then
                            if self.board[ni][nj].mine then
                                count = count + 1
                            end
                        end
                    end
                end
                self.board[i][j].adjacentMines = count
            end
        end
    end
end

function Game:startNewGame(difficulty, boardSize)
    self.boardSize = boardSize or 9
    self.difficulty = difficulty or "beginner"

    -- Set mines based on difficulty and board size
    if self.difficulty == "beginner" then
        self.minesCount = math_floor(self.boardSize * self.boardSize * 0.12)
    elseif self.difficulty == "intermediate" then
        self.minesCount = math_floor(self.boardSize * self.boardSize * 0.16)
    else -- expert
        self.minesCount = math_floor(self.boardSize * self.boardSize * 0.21)
    end

    self.minesCount = math_max(1, self.minesCount)

    self:calculateCellSize()
    self:initBoard()
    self.gameOver = false
    self.gameWon = false
    self.firstClick = true
    self.flagsCount = 0
    self.revealedCount = 0
    self.flagMode = false
    self.animations = {}
    self.cellParticles = {}
    self.revealQueue = {}
    self.startTime = love.timer.getTime()
    self.elapsedTime = 0
end

function Game:resetGame()
    self:startNewGame(self.difficulty, self.boardSize)
end

function Game:toggleFlagMode()
    self.flagMode = not self.flagMode
end

function Game:update(dt)
    self.elapsedTime = love.timer.getTime() - self.startTime

    -- Update animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration
        if anim.progress >= 1 then
            table_remove(self.animations, i)
        end
    end

    -- Update particles
    for i = #self.cellParticles, 1, -1 do
        local particle = self.cellParticles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        particle.rotation = particle.rotation + particle.dr * dt

        if particle.life <= 0 then
            table_remove(self.cellParticles, i)
        end
    end

    -- Process reveal queue
    if #self.revealQueue > 0 then
        local cell = table_remove(self.revealQueue, 1)
        if cell then
            self:revealCell(cell.row, cell.col)
        end
    end
end

function Game:createParticles(x, y, color, count)
    for _ = 1, count or 8 do
        table_insert(self.cellParticles, {
            x = x,
            y = y,
            dx = (math_random() - 0.5) * 80,
            dy = (math_random() - 0.5) * 80,
            dr = (math_random() - 0.5) * 8,
            life = math_random(0.5, 1.2),
            color = color,
            size = math_random(2, 5),
            rotation = math_random() * math_pi * 2
        })
    end
end

function Game:revealCell(row, col)
    if row < 1 or row > self.boardSize or col < 1 or col > self.boardSize then
        return
    end

    local cell = self.board[row][col]
    if cell.revealed or cell.flagged then return end

    cell.revealed = true
    self.revealedCount = self.revealedCount + 1

    -- Add reveal animation
    table_insert(self.animations, {
        type = "reveal",
        row = row,
        col = col,
        progress = 0,
        duration = 0.2
    })

    if cell.mine then
        self.gameOver = true
        self:createParticles(
            self.boardX + (col - 0.5) * self.cellSize,
            self.boardY + (row - 0.5) * self.cellSize,
            { 1, 0.2, 0.2 }, 15
        )
    elseif cell.adjacentMines == 0 then
        -- Reveal adjacent cells for empty cells
        for di = -1, 1 do
            for dj = -1, 1 do
                if not (di == 0 and dj == 0) then
                    table_insert(self.revealQueue, { row = row + di, col = col + dj })
                end
            end
        end
    end

    -- Check win condition
    if self.revealedCount == (self.boardSize * self.boardSize - self.minesCount) then
        self.gameOver = true
        self.gameWon = true
        self:createWinParticles()
    end
end

function Game:toggleFlag(row, col)
    local cell = self.board[row][col]
    if not cell.revealed then
        cell.flagged = not cell.flagged
        self.flagsCount = self.flagsCount + (cell.flagged and 1 or -1)

        table_insert(self.animations, {
            type = "flag",
            row = row,
            col = col,
            progress = 0,
            duration = 0.15
        })
    end
end

function Game:handleClick(x, y, button)
    if self.gameOver then return end

    -- Check reset button
    if x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 20 and y <= 60 then
        self:resetGame()
        return
    end

    -- Check flag mode toggle button
    if x >= self.screenWidth - 140 and x <= self.screenWidth - 20 and
        y >= 80 and y <= 120 then
        self.flagMode = not self.flagMode
        return
    end

    local row, col = self:getCellFromPos(x, y)
    if row and col then
        if button == 2 or self.flagMode then -- Right click or flag mode
            self:toggleFlag(row, col)
        else                                 -- Left click
            if self.firstClick then
                self:placeMines(row, col)
                self.firstClick = false
            end
            self:revealCell(row, col)
        end
    end
end

function Game:getCellFromPos(x, y)
    local col = math_floor((x - self.boardX) / self.cellSize) + 1
    local row = math_floor((y - self.boardY) / self.cellSize) + 1

    if row >= 1 and row <= self.boardSize and col >= 1 and col <= self.boardSize then
        return row, col
    end
    return nil, nil
end

function Game:getCellCenter(row, col)
    local x = self.boardX + (col - 0.5) * self.cellSize
    local y = self.boardY + (row - 0.5) * self.cellSize
    return x, y
end

function Game:createWinParticles()
    for i = 1, self.boardSize do
        for j = 1, self.boardSize do
            if not self.board[i][j].mine then
                local x, y = self:getCellCenter(i, j)
                self:createParticles(x, y, { 0.2, 1, 0.2 }, 2)
            end
        end
    end
end

function Game:draw()
    self:drawBoard()
    self:drawCells()
    self:drawUI()
    self:drawParticles()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawBoard()
    -- Draw board background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", self.boardX - 10, self.boardY - 10,
        self.cellSize * self.boardSize + 20,
        self.cellSize * self.boardSize + 20, 5)

    -- Draw grid lines with better visibility
    love.graphics.setLineWidth(2)

    -- Draw vertical lines
    for i = 0, self.boardSize do
        local x = self.boardX + i * self.cellSize
        love.graphics.setColor(0.6, 0.7, 1, 0.8)
        love.graphics.line(x, self.boardY, x, self.boardY + self.cellSize * self.boardSize)
    end

    -- Draw horizontal lines
    for i = 0, self.boardSize do
        local y = self.boardY + i * self.cellSize
        love.graphics.setColor(0.6, 0.7, 1, 0.8)
        love.graphics.line(self.boardX, y, self.boardX + self.cellSize * self.boardSize, y)
    end

    love.graphics.setLineWidth(1) -- Reset to default
end

function Game:drawCells()
    local numberColors = {
        [1] = { 0.2, 0.4, 1 },   -- Blue
        [2] = { 0.2, 0.7, 0.2 }, -- Green
        [3] = { 1, 0.2, 0.2 },   -- Red
        [4] = { 0.4, 0.2, 0.8 }, -- Purple
        [5] = { 0.8, 0.2, 0.2 }, -- Dark Red
        [6] = { 0.2, 0.8, 0.8 }, -- Cyan
        [7] = { 0, 0, 0 },       -- Black
        [8] = { 0.5, 0.5, 0.5 }  -- Gray
    }

    local font = love.graphics.newFont(math_floor(self.cellSize * 0.6))

    for row = 1, self.boardSize do
        for col = 1, self.boardSize do
            local cell = self.board[row][col]
            local x, y = self.boardX + (col - 1) * self.cellSize, self.boardY + (row - 1) * self.cellSize

            -- Cell background
            if cell.revealed then
                love.graphics.setColor(0.2, 0.25, 0.4)
                love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)

                -- Add subtle border for revealed cells
                love.graphics.setColor(0.4, 0.5, 0.8, 0.3)
                love.graphics.rectangle("line", x, y, self.cellSize, self.cellSize)
            else
                -- Enhanced 3D effect for unrevealed cells
                love.graphics.setColor(0.4, 0.45, 0.8)
                love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
                love.graphics.setColor(0.2, 0.25, 0.5)
                love.graphics.rectangle("fill", x + 2, y + 2, self.cellSize - 4, self.cellSize - 4)

                -- Stronger border for unrevealed cells
                love.graphics.setColor(0.6, 0.7, 1, 0.6)
                love.graphics.setLineWidth(1.5)
                love.graphics.rectangle("line", x, y, self.cellSize, self.cellSize)
                love.graphics.setLineWidth(1)
            end

            -- Cell content
            if cell.revealed then
                if cell.mine then
                    love.graphics.setColor(1, 0.2, 0.2)
                    love.graphics.circle("fill", x + self.cellSize / 2, y + self.cellSize / 2, self.cellSize / 3)
                elseif cell.adjacentMines > 0 then
                    love.graphics.setColor(numberColors[cell.adjacentMines] or { 1, 1, 1 })
                    love.graphics.setFont(font)
                    love.graphics.print(tostring(cell.adjacentMines),
                        x + (self.cellSize - font:getWidth(tostring(cell.adjacentMines))) / 2,
                        y + (self.cellSize - font:getHeight()) / 2)
                end
            elseif cell.flagged then
                love.graphics.setColor(1, 0.8, 0.2)

                -- Dimensions
                local poleWidth = self.cellSize * 0.1
                local poleHeight = self.cellSize * 0.6
                local flagWidth = self.cellSize * 0.35
                local flagHeight = self.cellSize * 0.25

                -- Offset to move everything slightly left
                local offset = self.cellSize * 0.1

                -- Pole coordinates
                local poleX = x + self.cellSize / 2 - poleWidth / 2 - offset
                local poleY = y + self.cellSize / 2 - poleHeight / 2

                -- Draw pole
                love.graphics.rectangle("fill", poleX, poleY, poleWidth, poleHeight)

                -- Flag coordinates (triangular flag)
                local flagX = poleX + poleWidth
                local flagY = poleY

                love.graphics.polygon("fill",
                    flagX, flagY,                              -- Top-left of flag
                    flagX + flagWidth, flagY + flagHeight / 2, -- Tip of flag
                    flagX, flagY + flagHeight                  -- Bottom-left of flag
                )
            end

            -- Animation effects (rest of the method remains the same)
            for _, anim in ipairs(self.animations) do
                if anim.row == row and anim.col == col then
                    if anim.type == "reveal" then
                        local scale = anim.progress
                        love.graphics.setColor(1, 1, 1, 0.5 * (1 - scale))
                        love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
                    elseif anim.type == "flag" then
                        local pulse = math_sin(anim.progress * math_pi) * 0.3
                        love.graphics.setColor(1, 1, 1, pulse)
                        love.graphics.rectangle("line", x + 2, y + 2, self.cellSize - 4, self.cellSize - 4)
                    end
                end
            end
        end
    end
end

function Game:drawUI()
    -- Game info
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))

    -- Mines counter
    love.graphics.setColor(1, 0.4, 0.4)
    love.graphics.print("Mines: " .. (self.minesCount - self.flagsCount), 20, 20)

    -- Timer
    love.graphics.setColor(0.4, 0.8, 1)
    love.graphics.print("Time: " .. math_floor(self.elapsedTime) .. "s", 20, 50)

    -- Flag mode indicator
    love.graphics.setColor(self.flagMode and { 1, 0.8, 0.2 } or { 0.6, 0.6, 0.6 })
    love.graphics.print("Flag Mode: " .. (self.flagMode and "ON" or "OFF"), 20, 80)

    -- Reset button
    love.graphics.setColor(0.8, 0.6, 0.2)
    love.graphics.rectangle("line", self.screenWidth - 140, 20, 120, 40, 5)
    love.graphics.setColor(0.8, 0.6, 0.2, 0.3)
    love.graphics.rectangle("fill", self.screenWidth - 140, 20, 120, 40, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("Reset", self.screenWidth - 130, 32)

    -- Flag mode toggle button
    love.graphics.setColor(0.6, 0.4, 0.8)
    love.graphics.rectangle("line", self.screenWidth - 140, 80, 120, 40, 5)
    love.graphics.setColor(0.6, 0.4, 0.8, 0.3)
    love.graphics.rectangle("fill", self.screenWidth - 140, 80, 120, 40, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Toggle Flag", self.screenWidth - 135, 92)

    -- Game info
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Difficulty: " .. self.difficulty, 20, 110)
    love.graphics.print("Board: " .. self.boardSize .. "x" .. self.boardSize, 20, 130)

    love.graphics.print("Left Click: Reveal", 20, self.screenHeight - 90)
    love.graphics.print("Right Click: Flag", 20, self.screenHeight - 70)
    love.graphics.print("Press F: Toggle Flag Mode", 20, self.screenHeight - 50)
    love.graphics.print("Press R: Reset Game", 20, self.screenHeight - 30)
end

function Game:drawParticles()
    for _, particle in ipairs(self.cellParticles) do
        local alpha = math_min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        love.graphics.circle("fill", 0, 0, particle.size)
        love.graphics.pop()
    end
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)

    if self.gameWon then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf("VICTORY!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Time: " .. math_floor(self.elapsedTime) .. " seconds", 0, self.screenHeight / 2 - 20,
            self.screenWidth, "center")
    else
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")
    end

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 20, self.screenWidth, "center")
end

function Game:isGameOver()
    return self.gameOver
end

-- Math functions
function math_abs(x) return x < 0 and -x or x end

function math_max(a, b) return a > b and a or b end

return Game
