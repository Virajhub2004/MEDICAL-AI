-- Tic-Tac-Toe (2-player) for LÖVE / Love2D
---@diagnostic disable: undefined-global
---@diagnostic disable: undefined-field
--
-- Run from repo root:
--   love lessons/03-AI-Assistants-Intro
--
-- Controls:
--   Left click : place mark
--   R          : reset round (keep score)
--   N          : new match (reset score)
--   Esc        : quit

local board = {}

local currentPlayer = "X"
local gameState = "playing" -- "playing" | "win" | "tie"
local winner = nil
local winningCells = nil -- {{r,c},{r,c},{r,c}}

local score = { X = 0, O = 0, Ties = 0 }

local ui = {
	fontTitle = nil,
	fontUI = nil,
	fontMark = nil,
	boardX = 0,
	boardY = 0,
	boardSize = 0,
	cellSize = 0,
	headerH = 0,
	hover = nil, -- {r,c}
}

local COLORS = {
	bg = { 14 / 255, 18 / 255, 28 / 255, 1 },
	panel = { 22 / 255, 28 / 255, 44 / 255, 1 },
	grid = { 190 / 255, 205 / 255, 1, 0.30 },
	gridStrong = { 190 / 255, 205 / 255, 1, 0.55 },
	text = { 235 / 255, 242 / 255, 1, 0.92 },
	muted = { 235 / 255, 242 / 255, 1, 0.65 },
	hover = { 120 / 255, 200 / 255, 1, 0.14 },
	winline = { 255 / 255, 220 / 255, 110 / 255, 0.90 },
	x = { 110 / 255, 210 / 255, 1, 0.95 },
	o = { 1, 120 / 255, 170 / 255, 0.95 },
}

local function resetRound()
	board = {
		{ nil, nil, nil },
		{ nil, nil, nil },
		{ nil, nil, nil },
	}
	currentPlayer = "X"
	gameState = "playing"
	winner = nil
	winningCells = nil
end

local function resetMatch()
	score.X, score.O, score.Ties = 0, 0, 0
	resetRound()
end

local function computeLayout()
	local w, h = love.graphics.getDimensions()
	local minDim = math.min(w, h)
	local margin = math.floor(minDim * 0.07)
	ui.headerH = math.floor(h * 0.22)

	local usableH = h - ui.headerH - margin
	local usableW = w - 2 * margin

	ui.boardSize = math.floor(math.min(usableW, usableH))
	ui.cellSize = math.floor(ui.boardSize / 3)
	ui.boardSize = ui.cellSize * 3
	ui.boardX = math.floor((w - ui.boardSize) / 2)
	ui.boardY = math.floor(ui.headerH + (usableH - ui.boardSize) / 2)

	local base = math.max(14, math.floor(minDim * 0.03))
	ui.fontUI = love.graphics.newFont(base)
	ui.fontTitle = love.graphics.newFont(math.floor(base * 1.35))
	ui.fontMark = love.graphics.newFont(math.floor(ui.cellSize * 0.62))
end

local function isBoardFull()
	for r = 1, 3 do
		for c = 1, 3 do
			if board[r][c] == nil then
				return false
			end
		end
	end
	return true
end

local function checkWinner()
	local lines = {
		-- rows
		{ { 1, 1 }, { 1, 2 }, { 1, 3 } },
		{ { 2, 1 }, { 2, 2 }, { 2, 3 } },
		{ { 3, 1 }, { 3, 2 }, { 3, 3 } },
		-- cols
		{ { 1, 1 }, { 2, 1 }, { 3, 1 } },
		{ { 1, 2 }, { 2, 2 }, { 3, 2 } },
		{ { 1, 3 }, { 2, 3 }, { 3, 3 } },
		-- diags
		{ { 1, 1 }, { 2, 2 }, { 3, 3 } },
		{ { 1, 3 }, { 2, 2 }, { 3, 1 } },
	}

	for _, line in ipairs(lines) do
		local a = board[line[1][1]][line[1][2]]
		local b = board[line[2][1]][line[2][2]]
		local c = board[line[3][1]][line[3][2]]
		if a ~= nil and a == b and b == c then
			return a, line
		end
	end

	return nil, nil
end

local function cellFromPoint(x, y)
	if x < ui.boardX or x >= ui.boardX + ui.boardSize then
		return nil
	end
	if y < ui.boardY or y >= ui.boardY + ui.boardSize then
		return nil
	end
	local c = math.floor((x - ui.boardX) / ui.cellSize) + 1
	local r = math.floor((y - ui.boardY) / ui.cellSize) + 1
	if r < 1 or r > 3 or c < 1 or c > 3 then
		return nil
	end
	return r, c
end

local function makeMove(r, c)
	if gameState ~= "playing" then
		return
	end
	if board[r][c] ~= nil then
		return
	end

	board[r][c] = currentPlayer

	local w, line = checkWinner()
	if w ~= nil then
		gameState = "win"
		winner = w
		winningCells = line
		if w == "X" then
			score.X = score.X + 1
		else
			score.O = score.O + 1
		end
		return
	end

	if isBoardFull() then
		gameState = "tie"
		score.Ties = score.Ties + 1
		return
	end

	currentPlayer = (currentPlayer == "X") and "O" or "X"
end

local function roundRect(x)
	return math.floor(x + 0.5)
end

local function drawRoundedPanel(x, y, w, h)
	local r = math.floor(math.min(w, h) * 0.08)
	love.graphics.setColor(COLORS.panel)
	love.graphics.rectangle("fill", x, y, w, h, r, r)
end

local function drawHeader()
	local w, _ = love.graphics.getDimensions()

	love.graphics.setFont(ui.fontTitle)
	love.graphics.setColor(COLORS.text)
	local title = "Tic-Tac-Toe"
	local tw = ui.fontTitle:getWidth(title)
	love.graphics.print(title, math.floor((w - tw) / 2), 14)

	love.graphics.setFont(ui.fontUI)
	local scoreLine = string.format("Score  X: %d   O: %d   Ties: %d", score.X, score.O, score.Ties)
	local sw = ui.fontUI:getWidth(scoreLine)
	love.graphics.setColor(COLORS.muted)
	love.graphics.print(scoreLine, math.floor((w - sw) / 2), 14 + ui.fontTitle:getHeight() + 6)

	local status
	if gameState == "playing" then
		status = "Turn: " .. currentPlayer
	elseif gameState == "win" then
		status = "Winner: " .. tostring(winner) .. "   (R: next round, N: new match)"
	else
		status = "Tie game   (R: next round, N: new match)"
	end

	local stw = ui.fontUI:getWidth(status)
	love.graphics.setColor(COLORS.text)
	love.graphics.print(status, math.floor((w - stw) / 2), 14 + ui.fontTitle:getHeight() + ui.fontUI:getHeight() + 12)

	local hint = "Click to play • R reset round • N reset match • Esc quit"
	local hw = ui.fontUI:getWidth(hint)
	love.graphics.setColor(COLORS.muted)
	love.graphics.print(hint, math.floor((w - hw) / 2), ui.headerH - ui.fontUI:getHeight() - 10)
end

local function cellRect(r, c)
	local x = ui.boardX + (c - 1) * ui.cellSize
	local y = ui.boardY + (r - 1) * ui.cellSize
	return x, y, ui.cellSize, ui.cellSize
end

local function isWinningCell(r, c)
	if not winningCells then
		return false
	end
	for _, rc in ipairs(winningCells) do
		if rc[1] == r and rc[2] == c then
			return true
		end
	end
	return false
end

local function drawBoard()
	local pad = math.floor(ui.cellSize * 0.09)
	drawRoundedPanel(ui.boardX - pad, ui.boardY - pad, ui.boardSize + pad * 2, ui.boardSize + pad * 2)

	-- hover highlight
	if ui.hover and gameState == "playing" then
		local r, c = ui.hover[1], ui.hover[2]
		if board[r][c] == nil then
			local x, y, cw, ch = cellRect(r, c)
			love.graphics.setColor(COLORS.hover)
			love.graphics.rectangle("fill", x + 6, y + 6, cw - 12, ch - 12, 12, 12)
		end
	end

	-- grid lines
	love.graphics.setLineWidth(math.max(2, math.floor(ui.cellSize * 0.045)))
	for i = 1, 2 do
		local x = ui.boardX + i * ui.cellSize
		local y = ui.boardY + i * ui.cellSize
		love.graphics.setColor(COLORS.gridStrong)
		love.graphics.line(x, ui.boardY, x, ui.boardY + ui.boardSize)
		love.graphics.line(ui.boardX, y, ui.boardX + ui.boardSize, y)
	end

	-- marks
	love.graphics.setFont(ui.fontMark)
	for r = 1, 3 do
		for c = 1, 3 do
			local mark = board[r][c]
			if mark ~= nil then
				local x, y, cw, ch = cellRect(r, c)
				local markW = ui.fontMark:getWidth(mark)
				local markH = ui.fontMark:getHeight()
				local px = math.floor(x + (cw - markW) / 2)
				local py = math.floor(y + (ch - markH) / 2 - ui.cellSize * 0.04)

				if isWinningCell(r, c) then
					love.graphics.setColor(COLORS.winline)
				elseif mark == "X" then
					love.graphics.setColor(COLORS.x)
				else
					love.graphics.setColor(COLORS.o)
				end

				love.graphics.print(mark, px, py)
			end
		end
	end

	-- winning line overlay
	if winningCells then
		local a = winningCells[1]
		local b = winningCells[3]
		local ax, ay = cellRect(a[1], a[2])
		local bx, by = cellRect(b[1], b[2])
		local cx1 = ax + ui.cellSize / 2
		local cy1 = ay + ui.cellSize / 2
		local cx2 = bx + ui.cellSize / 2
		local cy2 = by + ui.cellSize / 2

		love.graphics.setLineWidth(math.max(4, math.floor(ui.cellSize * 0.065)))
		love.graphics.setColor(COLORS.winline)
		love.graphics.line(roundRect(cx1), roundRect(cy1), roundRect(cx2), roundRect(cy2))
	end
end

function love.load()
	love.window.setTitle("Tic-Tac-Toe")
	love.window.setMode(800, 820, { resizable = true, minwidth = 520, minheight = 560 })
	love.graphics.setBackgroundColor(COLORS.bg)
	resetMatch()
	computeLayout()
end

function love.resize()
	computeLayout()
end

function love.update()
	local mx, my = love.mouse.getPosition()
	local r, c = cellFromPoint(mx, my)
	if r ~= nil then
		ui.hover = { r, c }
	else
		ui.hover = nil
	end
end

function love.mousepressed(x, y, button)
	if button ~= 1 then
		return
	end
	local r, c = cellFromPoint(x, y)
	if r == nil then
		return
	end
	makeMove(r, c)
end

function love.keypressed(key)
	if key == "r" then
		resetRound()
	elseif key == "n" then
		resetMatch()
	elseif key == "escape" then
		love.event.quit()
	end
end

function love.draw()
	drawHeader()
	drawBoard()
end

