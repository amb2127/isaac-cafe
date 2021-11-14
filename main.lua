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
	if cacheFlag == CacheFlag.CACHE_RANGE then
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.TearRange = player.TearRange + 60
		end
	end
	if cacheFlag == CacheFlag.CACHE_SPEED then
		if player:HasCollectible(Drinks.SMOOTHIE) then
			player.MoveSpeed = player.MoveSpeed + 0.2
		end 
	end  
end)

local tookDamage = false
IsaacCafe:AddCallback(ModCallbacks.MC_POST_UPDATE, function() -- a glass of water random water splotches
	local player = Isaac.GetPlayer(0)
	if player:HasCollectible(Drinks.WATER) then
		if math.random(60) == 1 and tookDamage == false then
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL,
				0,
				player.Position,
				Vector(0, 0),
				player
			):Update()
		else if math.random(3) == 1 and tookDamage == true then
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
	if ent:ToPlayer() and tookDamage == false and Isaac.GetPlayer(0):HasCollectible(Drinks.WATER) then
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

IsaacCafe:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flags, source, iframes)
	if ent:ToPlayer() and tookDamage == false and Isaac.GetPlayer(0):HasCollectible(Drinks.COFFEE) then
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

local hit = 0
local WineActive = 0
local Offset = Vector(0, 4)
local SwingOffset = Vector(0, -38)
local swung = 0
local LastActive = 0
IsaacCafe:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, id, rng, player, flags, slot)
	if WineActive == 0 then
		local wine = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			Isaac.GetEntityVariantByName("Red Wine"),
			0,
			player.Position - Offset,
			Vector.Zero,
			player
		):ToEffect()
		SFXManager():Play(SoundEffect.SOUND_SHELLGAME, 0.4, 0, false, 1)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position - Offset, Vector.Zero, nil)
		wine.Parent = player
		wine.DepthOffset = 99
		Game()
		WineActive = 1
		LastActive = Game():GetFrameCount()
	end
end, Drinks.WINE)
IsaacCafe:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	if Input.IsButtonPressed(Keyboard.KEY_SPACE, 0) and LastActive < Game():GetFrameCount() - 30 and WineActive == 1 then
		for _, ent in pairs(Isaac.GetRoomEntities()) do
			if ent.Type == EntityType.ENTITY_EFFECT and ent.Variant == Isaac.GetEntityVariantByName("Red Wine") then
				ent:Remove()
				SFXManager():Play(SoundEffect.SOUND_SHELLGAME, 0.4, 0, false, 1)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, Isaac.GetPlayer(0).Position - Offset, Vector.Zero, nil)
				WineActive = 0
			end
		end
	end
end)

IsaacCafe:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	local sprite = eff:GetSprite()
	local player = eff.Parent:ToPlayer()

	local FireDirection = player:GetFireDirection()
	local WalkDirection = player:GetMovementDirection()

	if player.FireDelay < player.MaxFireDelay then 
		player.FireDelay = player.MaxFireDelay - 1
	end

	if sprite:GetAnimation() == "Idle" or sprite:GetAnimation() == "Idle2" then
		if FireDirection > -1 and player.FireDelay < player.MaxFireDelay then
			player.FireDelay = player.MaxFireDelay * 2.5

			local angle = FireDirection * 90 + 90
			local hitOffset = SwingOffset:Rotated(angle)
			sprite.Rotation = angle

			if hit == 0 then
				sprite:Play("Swing", true)
			else
				sprite:Play("Swing3", true)
			end
			SFXManager():Play(SoundEffect.SOUND_SHELLGAME, 0.4, 0, false, 1)

			for _, entity in ipairs(Isaac.FindInRadius(eff.Position - hitOffset, 34 * eff.Scale)) do
				if entity:IsVulnerableEnemy() then
					if hit == 0 then
						hit = 1
						SFXManager():Play(SoundEffect.SOUND_POT_BREAK_2)
						local tear1 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(0,9), player):ToTear()
						tear1.Scale = 1.5
						tear1.CollisionDamage = player.Damage + 10
						local tear2 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(9/2,(9*math.sqrt(3))/2), player):ToTear()
						tear2.Scale = 1.5
						tear2.CollisionDamage = player.Damage + 10
						local tear3 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector((9*math.sqrt(3))/2,9/2), player):ToTear()
						tear3.Scale = 1.5
						tear3.CollisionDamage = player.Damage + 10
						local tear4 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(9,0), player):ToTear()
						tear4.Scale = 1.5
						tear4.CollisionDamage = player.Damage + 10
						local tear5 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector((9*math.sqrt(3))/2,-9/2), player):ToTear()
						tear5.Scale = 1.5
						tear5.CollisionDamage = player.Damage + 10
						local tear6 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(9/2,-(9*math.sqrt(3))/2), player):ToTear()
						tear6.Scale = 1.5
						tear6.CollisionDamage = player.Damage + 10
						local tear7 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(0,-9), player):ToTear()
						tear7.Scale = 1.5
						tear7.CollisionDamage = player.Damage + 10
						local tear8 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(-9/2,-(9*math.sqrt(3))/2), player):ToTear()
						tear8.Scale = 1.5
						tear8.CollisionDamage = player.Damage + 10
						local tear9 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(-(9*math.sqrt(3))/2,-9/2), player):ToTear()
						tear9.Scale = 1.5
						tear9.CollisionDamage = player.Damage + 10
						local tear10 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(-9,0), player):ToTear()
						tear10.Scale = 1.5
						tear10.CollisionDamage = player.Damage + 10
						local tear11 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(-(9*math.sqrt(3))/2,9/2), player):ToTear()
						tear11.Scale = 1.5
						tear11.CollisionDamage = player.Damage + 10
						local tear12 = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, eff.Position, Vector(-9/2,(9*math.sqrt(3))/2), player):ToTear()
						tear12.Scale = 1.5
						tear12.CollisionDamage = player.Damage + 10
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SCYTHE_BREAK, 0, eff.Position, Vector.Zero, player):ToEffect().Scale = 2
					end
					local damage = player.Damage * 2 + 5
					entity:AddVelocity((entity.Position - player.Position)/20 * math.sqrt(damage))
					entity:TakeDamage(damage, 0, EntityRef(player), 0)
					entity:BloodExplode()
					SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS, 0.9, 0, false, 1)
				end
				if entity:ToPickup() then
					entity:AddVelocity((entity.Position - player.Position)/5)
				end
			end

			local room = Game():GetRoom()
			for i = 0, room:GetGridSize() do
				local grid = room:GetGridEntity(i)
				if grid then
					if grid.Position:Distance(eff.Position - hitOffset) <= (48 * eff.Scale) then
						local type = grid:GetType()
						if type == GridEntityType.GRID_POOP or type == GridEntityType.GRID_TNT then
							grid:Hurt(3)
							SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS, 1.4, 0, false, 1)
						end
					end
				end
			end
		elseif WalkDirection > -1 then
			local angle = WalkDirection * 90 + 90
			sprite.Rotation = angle
		elseif player.FireDelay < player.MaxFireDelay * 2 then
			sprite.Rotation = 0
		end
	else
		if sprite:IsFinished(sprite:GetAnimation()) then
			if hit == 0 then
				sprite:Play("Idle", true)
			else
				sprite:Play("Idle2", true)
			end
			if swung == 0 then
				swung = 1
			else
				swung = 0
			end
		end
	end
	if (sprite.Rotation == 0 or sprite.Rotation == 180 or sprite.Rotation == 360) then
		eff.Position = eff.Parent.Position + Offset:Rotated(sprite.Rotation) - Vector(0, 8)
		eff.Velocity = eff.Parent.Velocity * 2
	else 
		eff.Position = eff.Parent.Position + Offset:Rotated(sprite.Rotation)*4 -Vector(0, 16)
		eff.Velocity = eff.Parent.Velocity * 2
	end
	if swung == 1 then 
		if (sprite.Rotation == 0 or sprite.Rotation == 180 or sprite.Rotation == 360) then
			sprite.FlipX=true
			sprite.FlipY=false
		else 
			sprite.FlipX=false
			sprite.FlipY=true
		end
	else
		sprite.FlipX=false
		sprite.FlipY=false
	end
	
	if not (sprite.Rotation == 0 or sprite.Rotation == 360) then
		eff.DepthOffset = -99
	else
		eff.DepthOffset = 99
	end
end, Isaac.GetEntityVariantByName("Red Wine"))


IsaacCafe:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	tookDamage = false
	hit = 0
	WineActive = 0
end)
