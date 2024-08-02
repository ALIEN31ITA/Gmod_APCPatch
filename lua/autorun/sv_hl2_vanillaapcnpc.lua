local Category = "Combine"

local HL2VAN_NPC_APCDRIVER_APC = 
{
	Name = "APC",
	Model = "models/combine_apc.mdl",
	Class = "prop_vehicle_apc",
	Category = Category,
	KeyValues = { vehiclescript = "scripts/vehicles/apc_npc.txt" },
	ListClass = "hl2van_apcdriver_playermade",

}
list.Set( "NPC", "hl2van_apcdriver_playermade", HL2VAN_NPC_APCDRIVER_APC )

// VEHICLES

local Category = "Half-Life 2"

local HL2VAN_VEH_COMBINE_APC = 
{
	Name = "Combine APC",
	Model = "models/combine_apc.mdl",
	Class = "prop_vehicle_apc",
	Category = Category,
	KeyValues = { vehiclescript = "scripts/vehicles/apc_patch.txt" },
	ListClass = "hl2van_prop_vehicle_apc",

}
list.Set( "Vehicles", "hl2van_prop_vehicle_apc", HL2VAN_VEH_COMBINE_APC )

include("includes/modules/outline.lua")
AddCSLuaFile("includes/modules/outline.lua")

duplicator.Allow( "prop_vehicle_apc" )