local class = require "com/class"
local Console = class:derive("Console")

local Vec2 = require("src/Essentials/Vector2")

function Console:new()
	self.history = {}
	self.command = ""
	
	self.open = false
	self.active = false
	
	self.backspace = false
	self.BACKSPACE_FIRST_REPEAT_TIME = 0.5
	self.BACKSPACE_NEXT_REPEAT_TIME = 0.05
	self.backspaceTime = 0
	
	self.MAX_MESSAGES = 20
	
	self.font = love.graphics.newFont()
	self.consoleFont = love.graphics.newFont(16)
end

function Console:update(dt)
	if self.backspace then
		self.backspaceTime = self.backspaceTime - dt
		if self.backspaceTime <= 0 then
			self.backspaceTime = self.BACKSPACE_NEXT_REPEAT_TIME
			self:inputBackspace()
		end
	else
		self.backspaceTime = self.BACKSPACE_FIRST_REPEAT_TIME
	end
end

function Console:print(message)
	table.insert(self.history, {text = message, time = totalTime})
end

function Console:setOpen(open)
	self.open = open
	self.active = open
end

function Console:toggleOpen(open)
	self:setOpen(not self.open)
end

function Console:draw()
	local pos = Vec2(5, displaySize.y)
	local size = Vec2(600, 200)
	
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(self.consoleFont)
	for i = 1, self.MAX_MESSAGES do
		local pos = pos - Vec2(0, 30 + 20 * i)
		local message = self.history[#self.history - i + 1]
		if message and (self.open or totalTime - message.time < 10) then
			dbg:drawVisibleText({{1, 0.3, 0.3}, message.text}, pos, 20)
		end
	end
	
	if self.open then
		local text = "> " .. self.command
		if self.active and totalTime % 1 < 0.5 then text = text .. "_" end
		dbg:drawVisibleText(text, pos - Vec2(0, 25), 20, size.x)
	end
	love.graphics.setFont(self.font)
end



function Console:keypressed(key)
	-- the shortcut is Control + F12
	if key == "f12" and (keyModifiers["lctrl"] or keyModifiers["rctrl"]) then
		self:toggleOpen()
	end
	if self.active then
		if key == "backspace" then
			self:inputBackspace()
			self.backspace = true
		end
		if key == "return" then
			self:inputEnter()
		end
	end
end

function Console:keyreleased(key)
	if key == "backspace" then
		self.backspace = false
	end
end

function Console:textinput(t)
	self:inputCharacter(t)
end



function Console:inputCharacter(t)
	if not self.active then return end
	self.command = self.command .. t
end

function Console:inputBackspace()
	if not self.active then return end
	self.command = self.command:sub(1, -2)
end

function Console:inputEnter()
	local success = dbg:runCommand(self.command)
	if not success then self:print("Invalid command!") end
	self.command = ""
end

return Console