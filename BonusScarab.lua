--- Represents a bonus scarab that will give points at the end of the level.
-- @classmod BonusScarab



-- Class identification
local class = require "class"
local BonusScarab = class:derive("BonusScarab")

-- Include commons
local Vec2 = require("Essentials/Vector2")
local Color = require("Essentials/Color")

-- Include other classes
local Sprite = require("Sprite")



--- Constructors
-- @section constructors

--- Object constructor.
-- Executed when this object is created.
-- @tparam Path path An instance of Path on which this BonusScarab is.
function BonusScarab:new(path)
	self.path = path
	
	self.offset = path.length
	self.distance = 0
	self.trailDistance = 0
	self.coinDistance = 0
	self.minOffset = math.max(path.clearOffset, 64)
	
	self.sprite = Sprite("sprites/sphere_vise.json")
	self.shadowImage = game.resourceBank:getImage("img/game/ball_shadow.png")
	
	game:playSound("bonus_scarab_loop")
end



--- Callbacks
-- @section callbacks

--- An update callback.
-- @tparam number dt Delta time in seconds.
function BonusScarab:update(dt)
	self.offset = self.offset - 1000 * dt
	self.distance = self.path.length - self.offset
	-- Luxor 2
	-- while self.coinDistance < self.distance do
		-- if self.coinDistance > 0 then game.session.level:spawnCollectible(self.path:getPos(self.offset), {type = "coin"}) end
		-- self.coinDistance = self.coinDistance + 500
	-- end
	while self.trailDistance < self.distance do
		local offset = self.path.length - self.trailDistance
		--if not self.path:getHidden(offset) then -- the particles shouldn't be visible under obstacles
			game:spawnParticle("particles/bonus_scarab_trail.json", self.path:getPos(offset))
		--end
		self.trailDistance = self.trailDistance + 24
	end
	if self.offset <= self.minOffset then self:destroy() end
end



--- A drawing callback.
function BonusScarab:draw(hidden, shadow)
	if self.path:getHidden(self.offset) == hidden then
		if shadow then
			self.shadowImage:draw(self.path:getPos(self.offset) + Vec2(4), Vec2(0.5))
		else
			self.sprite:draw(self.path:getPos(self.offset), {angle = self.path:getAngle(self.offset) + math.pi, color = Color(self.path:getBrightness(self.offset))})
		end
	end
end



--- @section end

--- Destroys the bonus scarab and gives an appropriate number of points.
-- For now, this is hardcoded to give 50 points every 24 pixels traversed.
function BonusScarab:destroy()
	self.path.bonusScarab = nil
	-- 50 points every 24 pixels
	local score = math.max(math.floor((self.path.length - self.minOffset) / 24), 1) * 50
	game.session.level:grantScore(score)
	game.session.level:spawnFloatingText(numStr(score) .. "\nBONUS", self.path:getPos(self.offset), "fonts/score0.json")
	game:spawnParticle("particles/collapse_vise.json", self.path:getPos(self.offset))
	game:stopSound("bonus_scarab_loop")
	game:playSound("bonus_scarab")
end



return BonusScarab