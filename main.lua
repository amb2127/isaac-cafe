local IsaacCafe = RegisterMod("Isaac Cafe;", 1) -- registers the mod!!!!

local function tearsUp(firedelay, val) -- by deadinfinity
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
    return math.max((30 / newTears) - 1, -0.99)
end

local Drinks = {
	CUSTOM = Isaac.GetItemIdByName("Customized Cocktail"),
	WATER = Isaac.GetItemIdByName("A Glass of Water"),
	BEER = Isaac.GetItemIdByName("Old Beer"),
	COFFEE = Isaac.GetItemIdByName("Black Coffee"),
	WINE = Isaac.GetItemIdByName("Red Wine"),
	MILKSHAKE = Isaac.GetItemIdByName("Milkshake!"),
	SMOOTHIE = Isaac.GetItemIdByName("Fruit Smoothie")
}

IsaacCafe:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, item)
	local player = Isaac.GetPlayer(0)
	local level = Game():GetLevel()
	if item.Type == 5 -- pickup
	and item.Variant == PickupVariant.PICKUP_COLLECTIBLE -- item
	and item.SubType == Drinks.CUSTOM -- customized cocktail
	and level:GetCurses() ~= LevelCurse.CURSE_OF_BLIND -- not curse of blind
	and player:GetPlayerType() < 41 then -- not modded char
		local sprite = item.GetSprite()
		sprite:ReplaceSpritesheet(1, "gfx/items/collectibles/"..player:GetPlayerType().."_drink.png") -- replace the sprite
		sprite:LoadGraphics()
		sprite:Update()
		sprite:Render(item.Position, Vector(0,0), Vector(0,0))
	end
end)

IsaacCafe:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag) -- stats
	if cacheFlag == CacheFlag.CACHE_DAMAGE then 
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.Damage = player.Damage + 0.5
		end
		if player:HasCollectible(Drinks.MILKSHAKE) then
			player.Damage = player.Damage + 1
		end
	end
	if cacheFlag == CacheFlag.CACHE_FIREDELAY then
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.MaxFireDelay = tearsUp(player.MaxFireDelay,0.5)
		end
		if player:HasCollectible(Drinks.MILKSHAKE) then
			player.MaxFireDelay = tearsUp(player.MaxFireDelay,-0.25)
		end
		if player:HasCollectible(Drinks.COFFEE) then
			player.MaxFireDelay = tearsUp(player.MaxFireDelay,0.5)
		end
	end
	if cacheFlag == CacheFlag.CACHE_LUCK then
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.Luck = player.Luck + 1
		end
	end
	if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.ShotSpeed = player.ShotSpeed + 0.15
		end
	end
	if cacheFlag == CacheFlag.CACHE_SPEED then
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.MoveSpeed = player.MoveSpeed + 0.2
		end 
	end  
end)

local WaterHit = false
IsaacCafe:AddCallback(ModCallbacks.MC_POST_UPDATE, function() -- a glass of water random water splotches
	local player = Isaac.GetPlayer(0)
	if player:HasCollectible(Drinks.WATER) then
		if math.random(60) == 1 and WaterHit == false then
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL,
				0,
				player.Position,
				Vector(0, 0),
				player
			):Update()
		else if math.random(3) == 1 and WaterHit == true then
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL,
				0,
				player.Position,
				Vector(0, 0),
				player
			):Update()
			end
		end
	end
end)

IsaacCafe:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flags, source, iframes)
	if ent:ToPlayer() and WaterHit == false and Isaac.GetPlayer(0):HasCollectible(Drinks.WATER) then
		SFXManager():Play(SoundEffect.SOUND_GLASS_BREAK)
		Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_HOLYWATER,
			0,
			player.Position,
			Vector(0,0),
			player
		)
		WaterHit = true
	end
end)

local CoffeeHit = false
IsaacCafe:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flags, source, iframes)
	if ent:ToPlayer() and CoffeeHit == false and Isaac.GetPlayer(0):HasCollectible(Drinks.COFFEE) then
		SFXManager():Play(SoundEffect.SOUND_POT_BREAK_2)
		local spill = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_LEMON_MISHAP,
			0,
			player.Position,
			Vector(0,0),
			player
		)
		spill:SetColor(Color(.1, .03, 0, 1, 0, 0, 0), 0, 1, false, false)
		spill:Update()
		local tear = Isaac.Spawn(
			EntityType.ENTITY_TEAR,
			TearVariant.BLUE,
			0,
			player.Position,
			Isaac.GetPlayer(0):GetMovementVector()*10,
			player
		):ToTear()
		tear.CollisionDamage = Isaac.GetPlayer(0).Damage
		tear.Scale = Isaac.GetPlayer(0).Damage/15+1
		tear:Update()
		CoffeeHit = true
	end
end)

IsaacCafe:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	WaterHit = false
	CoffeeHit = false
end)