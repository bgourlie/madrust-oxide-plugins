-- PLUGIN = PLUGIN or {} -- accommodates testing

PLUGIN.Title = "madrust-stats"
PLUGIN.Description = "Integration for madrust-stats backend."
PLUGIN.Version = "0.1"
PLUGIN.Author = "W. Brian Gourlie"

function PLUGIN:Init()
  print("madrust-stats init")

  -- damage_radiation : damage_radiation: 16
  -- damage_explosion : damage_explosion: 8
  -- damage_generic : damage_generic: 1
  -- damage_melee : damage_melee: 4
  -- damage_bullet : damage_bullet: 2
  -- damage_cold : damage_cold: 32
  typesystem.LoadEnum( Rust.DamageTypeFlags, "DamageType" )
end

function PLUGIN:OnKilled(takeDamage, damageEvent)
	local normalizedEvent = self:NormalizeDamageEvent(damageEvent)
	if not normalizedEvent then return end
	print(" *** BEGIN DEATH REPORT *** ")
	print('attacker: ' .. normalizedEvent.attacker.name)
	print('victim: ' .. normalizedEvent.victim.name)
	print('damageTypes: ' .. normalizedEvent.damageTypes)
	print('extraData: ' .. normalizedEvent.extraData)
	print('bodyPart: ' .. normalizedEvent.bodyPart)
	print(" *** END DEATH REPORT *** ")
end

function PLUGIN:NormalizeDamageEvent(damageEvent)
	local normalized = 
	{
		attacker = self:NormalizeDamageBeing(damageEvent.attacker),
		victim = self:NormalizeDamageBeing(damageEvent.victim),
		damageTypes = tostring(damageEvent.damageTypes),
		extraData = tostring(damageEvent.extraData),
		bodyPart = tostring(damageEvent.bodyPart)
	}

	return normalized
end

function PLUGIN:NormalizeDamageBeing(damageBeing)
	local name
	local id
	local isNpc

	if damageBeing.client then
		name = damageBeing.client.userName
		id = damageBeing.client.userID
		isNpc = false
	elseif damageBeing.character then
		name = tostring(damageBeing.character)
		isNpc = true
	else
		return nil
	end

	return 
	{
		name = name, 
		id = id, 
		isNpc = isNpc
	}
end


