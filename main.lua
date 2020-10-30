--- An entry point of this engine.
-- @module main



-- INCLUDE ZONE
local json = require("json")

local Vec2 = require("Essentials/Vector2")
local Color = require("Essentials/Color")

local Profiler = require("Profiler")
local Console = require("Console")

local BootScreen = require("BootScreen")
local Game = require("Game")



-- CONSTANT ZONE
VERSION = "beta 1.1.0"


-- TODO: at some point, get rid of these here and make them configurable
NATIVE_RESOLUTION = Vec2(800, 600)

SPHERE_COLORS = {
	[1] = Color(0, 0, 1),
	[2] = Color(1, 1, 0),
	[3] = Color(1, 0, 0),
	[4] = Color(0, 1, 0),
	[5] = Color(1, 0, 1),
	[6] = Color(1, 1, 1),
	[7] = Color(0, 0, 0),
	[8] = Color(1, 0.5, 0),
	[9] = Color(0, 0.5, 1)
}
POWERUP_CATCH_TEXTS = {
	bomb = "FIREBALL!",
	colorbomb = "COLOR BOMB!",
	lightning = "LIGHTNING BALL!",
	reverse = "REVERSE!",
	slow = "SLOW!",
	stop = "STOP!",
	shotspeed = "SPEED SHOT!",
	wild = "WILD BALL!"
}




-- GLOBAL ZONE
displaySize = Vec2(800, 600)
displayFullscreen = false
mousePos = Vec2(0, 0)
keyModifiers = {lshift = false, lctrl = false, lalt = false, rshift = false, rctrl = false, ralt = false}

game = nil
musicVolume = 1

variableSet = {}

totalTime = 0
timeScale = 1

console = Console()




profUpdate = Profiler("Update")
profDraw = Profiler("Draw")
profDraw2 = Profiler("Draw")
profDrawLevel = Profiler("Draw: Level")
prof3 = Profiler("Draw: Level2")
profMusic = Profiler("Music volume")

profVisible = false
profPage = 1
profPages = {profUpdate, profMusic, profDrawLevel, prof3}

uiDebugVisible = false
uiDebugOffset = 0
e = false

particleSpawnersVisible = false
gameDebugVisible = false








--- Callbacks
-- @section callbacks

--- Executed once when starting the engine.
-- Sets up the window title and starts a boot screen.
function love.load()
	love.window.setTitle("OpenSMCE [" .. VERSION .. "] - Boot Menu")
	game = BootScreen()
end



--- Called once every frame.
-- @tparam number dt Time since last frame in seconds.
function love.update(dt)
	profUpdate:start()
	
	mousePos = posFromScreen(Vec2(love.mouse.getPosition()))
	if game then game:update(dt * timeScale) end
	console:update(dt)
	
	-- rainbow effect for the shooter and console cursor blink; to be phased out soon
	totalTime = totalTime + dt
	
	profUpdate:stop()
end



--- Draws on the screen.
function love.draw()
	profDraw:start()
	
	-- Main
	if game then game:draw() end
	
	-- Tests
	
	
	-- Borders
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("fill", 0, 0, getDisplayOffsetX(), displaySize.y)
	love.graphics.rectangle("fill", displaySize.x - getDisplayOffsetX(), 0, getDisplayOffsetX(), displaySize.y)
	
	-- Profilers
	if profVisible then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
		profPages[profPage]:draw(Vec2(0, displaySize.y))
		profDraw:draw(Vec2(400, displaySize.y))
		profDraw2:draw(Vec2(400, displaySize.y))
	end
	
	-- Console
	console:draw()
	
	-- UI tree
	if uiDebugVisible and game.sessionExists and game:sessionExists() then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", 0, 0, 460, 600)
		love.graphics.setColor(1, 1, 1)
		for i, line in ipairs(getUITreeText()) do
			love.graphics.print(line[1], 10, 10 + i * 15 + uiDebugOffset)
			love.graphics.print(line[2], 260, 10 + i * 15 + uiDebugOffset)
			love.graphics.print(line[3], 270, 10 + i * 15 + uiDebugOffset)
			love.graphics.print(line[4], 290, 10 + i * 15 + uiDebugOffset)
			love.graphics.print(line[5], 320, 10 + i * 15 + uiDebugOffset)
			love.graphics.print(line[6], 350, 10 + i * 15 + uiDebugOffset)
			love.graphics.print(line[7], 380, 10 + i * 15 + uiDebugOffset)
		end
	end
	
	profDraw:stop()
end



--- Executed when an user presses a mouse button.
-- @tparam number x X coordinate where the mouse was when a button was pressed.
-- @tparam number y Y coordinate where the mouse was when a button was pressed.
-- @tparam number button Which mouse button was pressed.
function love.mousepressed(x, y, button)
	if game then game:mousepressed(x, y, button) end
end



--- Executed when an user releases a mouse button.
-- @tparam number x X coordinate where the mouse was when a button was released.
-- @tparam number y Y coordinate where the mouse was when a button was released.
-- @tparam number button Which mouse button was released.
function love.mousereleased(x, y, button)
	if game then game:mousereleased(x, y, button) end
end



--- Executed when an user presses a keyboard button.
-- @tparam string key Which key was pressed.
function love.keypressed(key)
	for k, v in pairs(keyModifiers) do if key == k then keyModifiers[k] = true end end
	
	if not console.active then
		if game then game:keypressed(key) end
		
		--if key == "f" then toggleFullscreen() end
		if key == "o" then profVisible = not profVisible end
		if key == "w" then uiDebugVisible = not uiDebugVisible end
		if key == "q" then particleSpawnersVisible = not particleSpawnersVisible end
		if key == "d" then gameDebugVisible = not gameDebugVisible end
		if key == "s" then saveJson(parsePath("test.json"), game.session.level:serialize()); game:playSound("sphere_shoot_wild") end
		if key == "l" then game.session.level:deserialize(loadJson(parsePath("test.json"))) end
		if key == "kp-" and profPage > 1 then profPage = profPage - 1 end
		if key == "kp+" and profPage < #profPages then profPage = profPage + 1 end
		if key == "," then uiDebugOffset = uiDebugOffset - 75 end
		if key == "." then uiDebugOffset = uiDebugOffset + 75 end
	end
	
	console:keypressed(key)
end



--- Executed when an user releases a keyboard button.
-- @tparam string key Which key was released.
function love.keyreleased(key)
	for k, v in pairs(keyModifiers) do if key == k then keyModifiers[k] = false end end
	
	if not console.active then
		if game then game:keyreleased(key) end
	end
	
	console:keyreleased(key)
end



--- Executed when a key that would result in inserting a character is pressed.
-- @tparam string t What would be typed in.
function love.textinput(t)
	console:textinput(t)
end



--- Executed when an user resizes the window.
-- @tparam number w New width of the screen.
-- @tparam number h New height of the screen.
function love.resize(w, h)
	displaySize = Vec2(w, h)
end



--- @section end

--- Loads a game from a given directory.
-- @tparam string gameName The name of the game directory (in games folder).
function loadGame(gameName)
	game = Game(gameName)
	game:init()
end




--- Toggles fullscreen mode.
function toggleFullscreen()
	displayFullscreen = not displayFullscreen
	if displayFullscreen then
		local _, _, flags = love.window.getMode()
		displaySize = Vec2(love.window.getDesktopDimensions(flags.display))
	else
		displaySize = NATIVE_RESOLUTION
	end
	love.window.setMode(displaySize.x, displaySize.y, {fullscreen = displayFullscreen, resizable = true})
end



function getDisplayOffsetX()
	return (displaySize.x - NATIVE_RESOLUTION.x * getResolutionScale()) / 2
end

function getResolutionScale()
	return displaySize.y / NATIVE_RESOLUTION.y
end

function posOnScreen(pos)
	return pos * getResolutionScale() + Vec2(getDisplayOffsetX(), 0)
end

function posFromScreen(pos)
	return (pos - Vec2(getDisplayOffsetX(), 0)) / getResolutionScale()
end



function getRainbowColor(t)
	t = t * 3
	local r = math.min(math.max(2 * (1 - math.abs(t % 3)), 0), 1) + math.min(math.max(2 * (1 - math.abs((t % 3) - 3)), 0), 1)
	local g = math.min(math.max(2 * (1 - math.abs((t % 3) - 1)), 0), 1)
	local b = math.min(math.max(2 * (1 - math.abs((t % 3) - 2)), 0), 1)
	return Color(r, g, b)
end

function getUITreeText(widget, rowTable, indent)
	widget = widget or game.widgets["main"]
	rowTable = rowTable or {}
	indent = indent or 0
	--if indent > 1 then return end
	
	local name = widget.name
	for i = 1, indent do name = "    " .. name end
	local visible = widget.visible and "X" or ""
	local visible2 = widget:getVisible() and "V" or ""
	local alpha = tostring(math.floor(widget.alpha * 10) / 10)
	local alpha2 = tostring(math.floor(widget:getAlpha() * 10) / 10)
	local time = widget.time and tostring(math.floor(widget.time * 100) / 100) or "-"
	local pos = tostring(widget.pos)
	if widget:getVisible() then
		table.insert(rowTable, {name, visible, visible2, alpha, alpha2, time, pos})
	end
	
	for childN, child in pairs(widget.children) do
		getUITreeText(child, rowTable, indent + 1)
	end
	
	return rowTable
end



function runCommand(command)
	local words = {""}
	for i = 1, command:len() do
		local character = command:sub(i, i)
		if character == " " then
			table.insert(words, "")
		else
			words[#words] = words[#words] .. character
		end
	end
	
	if words[1] == "p" then
		local t = {fire = "bomb", ligh = "lightning", wild = "wild", bomb = "colorbomb", slow = "slow", stop = "stop", rev = "reverse", shot = "shotspeed"}
		for word, name in pairs(t) do
			if words[2] == word then
				if word == "bomb" then
					if not words[3] or not tonumber(words[3]) or tonumber(words[3]) < 1 or tonumber(words[3]) > 7 then return false end
					game:usePowerup({name = name, color = tonumber(words[3])})
				else
					game:usePowerup({name = name})
				end
				console:print("Powerup applied")
				return true
			end
		end
	elseif words[1] == "sp" then
		if not words[2] or not tonumber(words[2]) then return false end
		game.session.level.destroyedSpheres = tonumber(words[2])
		console:print("Spheres destroyed set to " .. words[2])
		return true
	elseif words[1] == "b" then
		for i, path in ipairs(game.session.level.map.paths) do
			for j, sphereChain in ipairs(path.sphereChains) do
				for k, sphereGroup in ipairs(sphereChain.sphereGroups) do
					sphereGroup.offset = sphereGroup.offset + 1000
				end
			end
		end
		console:print("Boosted!")
		return true
	elseif words[1] == "s" then
		for i, path in ipairs(game.session.level.map.paths) do
			path:spawnChain()
		end
		console:print("Spawned new chains!")
		return true
	elseif words[1] == "fs" then
		toggleFullscreen()
		console:print("Fullscreen toggled")
		return true
	elseif words[1] == "t" then
		if not words[2] or not tonumber(words[2]) then return false end
		timeScale = tonumber(words[2])
		console:print("Time scale set to " .. words[2])
		return true
	elseif words[1] == "e" then
		e = not e
		console:print("Background cheat mode toggled")
		return true
	elseif words[1] == "n" then
		game.session:destroyFunction(function(sphere, spherePos) return true end, Vec2())
		console:print("Nuked!")
		return true
	elseif words[1] == "test" then
		game:spawnParticle("particles/collapse_vise.json", Vec2(100, 400))
		return true
	end
	
	return false
end



function loadFile(path)
	local file = io.open(path, "r")
	if not file then
		print("WARNING: File \"" .. path .. "\" does not exist. Expect errors!")
		return
	end
	io.input(file)
	local contents = io.read("*a")
	io.close(file)
	return contents
end

function loadJson(path)
	return json.decode(loadFile(path))
end

-- This function allows to load images from external sources.
-- This is an altered code from https://love2d.org/forums/viewtopic.php?t=85350#p221460
function loadImage(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			data = love.filesystem.newFileData(data, "tempname")
			data = love.image.newImageData(data)
			local image = love.graphics.newImage(data)
			return image
		end
	end
end

-- This function allows to load sounds from external sources.
-- This is an altered code from the above function.
function loadSound(path, type)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			-- to make everything work properly, we need to get the extension from the path, because it is used
			-- source: https://love2d.org/wiki/love.filesystem.newFileData
			local dotPos = 0
			local l = path:len()
			for i = 1, l do
				if path:sub(i, i) == "." then
					dotPos = i
				end
			end
			local extension = path:sub(dotPos + 1, l)
			data = love.filesystem.newFileData(data, "tempname." .. extension)
			data = love.sound.newSoundData(data)
			local sound = love.audio.newSource(data, type)
			return sound
		end
	end
end

function saveJson(path, data)
	print("Saving JSON data to " .. path .. "...")
	local file = io.open(path, "w")
	io.output(file)
	local contents = json.encode(data)
	io.write(contents)
	io.close(file)
end

function parseString(data, variables)
	if not data then return nil end
	if type(data) == "string" then return data end
	str = ""
	for i, compound in ipairs(data) do
		if type(compound) == "string" then
			str = str .. compound
		else
			if compound.type == "variable" then
				if not variables[compound.name] then
					-- print("FATAL: Invalid variable: " .. compound.name)
					-- print("Variables:")
					-- for k, v in pairs(variables) do print(k, v) end
					-- print("The game will crash now...")
				end
				str = str .. tostring(variables[compound.name])
			end
		end
	end
	return str
end

function parsePath(data, variables)
	if not data then return nil end
	return "games/" .. game.name .. "/" .. parseString(data, variables)
end

function parseNumber(data, variables, properties)
	if not data then return nil end
	if type(data) == "number" then return data end
	if data.type == "variable" then return variables[data.name] end
	if data.type == "property" then return properties[data.name] end
	if data.type == "randomSign" then
		local value = parseNumber(data.value, variables, properties)
		return math.random() < 0.5 and -value or value
	end
	if data.type == "randomInt" then
		local min = parseNumber(data.min, variables, properties)
		local max = parseNumber(data.max, variables, properties)
		return math.random(min, max)
	end
	if data.type == "randomFloat" then
		local min = parseNumber(data.min, variables, properties)
		local max = parseNumber(data.max, variables, properties)
		return min + math.random() * (max - min)
	end
	if data.type == "expr_graph" then
		local value = parseNumber(data.value, variables, properties)
		local points = {}
		for i, point in ipairs(data.points) do
			points[i] = parseVec2(point, variables, properties)
		end
		for i, point in ipairs(points) do
			if value < point.x then
				local prevPoint = points[i - 1]
				if prevPoint and point.x - prevPoint.x > 0 then
					local t = (point.x - value) / (point.x - prevPoint.x)
					return prevPoint.y * t + point.y * (1 - t)
				end
				return point.y
			end
		end
		return points[#points].y
	end
end

function parseVec2(data, variables, properties)
	if not data then return nil end
	if data.type == "variable" then return variables[data.name] end
	return Vec2(parseNumber(data.x, variables, properties), parseNumber(data.y, variables, properties))
end

function parseColor(data, variables, properties)
	if not data then return nil end
	if data.type == "variable" then return variables[data.name] end
	return Color(parseNumber(data.r, variables, properties), parseNumber(data.g, variables, properties), parseNumber(data.b, variables, properties))
end

function numStr(n)
	local text = ""
	local s = tostring(n)
	local l = s:len()
	for i = 1, l do
		text = text .. s:sub(i, i)
		if l - i > 0 and (l - i) % 3 == 0 then text = text .. "," end
	end
	return text
end
