// APC NPC
hook.Add("PlayerSpawnedNPC","HL2SB_NPC_COMBINEAPC", function(ply, ent)
	if ( ent:GetClass() == "prop_vehicle_apc" ) && ent.NPCTable.ListClass == "hl2van_apcdriver_playermade" then
		ent:SetName("npc_capc_" .. ent:EntIndex())
		local HL2_APCGetName = ent:GetName()
		local HL2_APCDriver = ents.Create("npc_apcdriver")
		HL2_APCDriver:SetKeyValue( "Vehicle", HL2_APCGetName)
		HL2_APCDriver:Spawn()
		HL2_APCDriver:Activate()
		ent:DeleteOnRemove(HL2_APCDriver)
		ent.APC_NPCDriver = true
	end
end)