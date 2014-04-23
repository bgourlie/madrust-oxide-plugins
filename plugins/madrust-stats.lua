-- PLUGIN = PLUGIN or {} -- accommodates testing

PLUGIN.Title = "madrust-stats"
PLUGIN.Description = "Integration for madrust-stats backend."
PLUGIN.Version = "0.1"
PLUGIN.Author = "W. Brian Gourlie"

function PLUGIN:Init()
  print("madrust-stats init")
end

function PLUGIN:OnKilled(takeDamage, damageEvent)
	print(" *** BEGIN DEATH REPORT *** ")
	print('attacker: ' .. tostring(damageEvent.attacker))
	print('victim: ' .. tostring(damageEvent.victim))
	print('sender: ' .. tostring(damageEvent.sender))
	print('status: ' .. tostring(damageEvent.status))
	print('damageTypes: ' .. tostring(damageEvent.damageTypes))
	print('amount: ' .. tostring(damageEvent.amount))
	print('extraData: ' .. tostring(damageEvent.extraData))
	print('bodyPart: ' .. tostring(damageEvent.bodyPart))
	print(" *** END DEATH REPORT *** ")
end

