local Mat = Material( "sprites/hud/v_crosshair1" )
local Ma2 = Material( "sprites/hud/v_crosshair2" )
surface.CreateFont( "apc_font1", {
	font = "HalfLife2",
	size = 68,
} )
surface.CreateFont( "apc_font2", {
	font = "HalfLife2",
	size = 68,
	extended = true,
	blursize = 8,
	scanlines = 2,
	antialias = true,
	additive = true,
} )

apchud_start = false
apchud_sglow = 0

apchud_aimx = 0
apchud_aimy = 0

apchud_hpp = 0
apchud_hpg = 0
apchud_hph = false
apchud_hpr = 0
apchud_hpb = 0

apchud_app = 0
apchud_apg = 0
apchud_aph = false
apchud_apr = 0

if HL2HUD then
	local func = HL2HUD.ShouldDraw
	function HL2HUD.ShouldDraw()
		local ply = LocalPlayer()
		if IsValid( ply ) and ply:Alive() and ply:InVehicle() then
			local veh = ply:GetNWEntity( "HL2APC" )
			if IsValid( veh ) and veh:GetClass() == "prop_vehicle_apc" and ply:GetVehicle() == veh then
				return false
			end
		end
		return func()
	end
end

hook.Add( "HUDPaintBackground", "HL2_VANILLAAPCFIX_HUD", function()
	local ply = LocalPlayer()
	if IsValid( ply ) and ply:Alive() and ply:InVehicle() then
		local veh = ply:GetNWEntity( "HL2APC" )
		if IsValid( veh ) and veh:GetClass() == "prop_vehicle_apc" and ply:GetVehicle() == veh and veh:GetNWInt( "APC_HEALTH" ) > 0 then
			local att = veh:LookupAttachment( "gun_def" )
			if att then
				local gat = veh:GetAttachment( att )

				local pos = util.TraceLine( {
					start = gat.Pos,
					endpos = gat.Pos +gat.Ang:Forward()*8192,
					filter = { veh, ply },
					mask = MASK_SHOT
				} ).HitPos:ToScreen()
				local xx, yy = math.Round( pos.x ), math.Round( pos.y )
				apchud_aimx = Lerp( FrameTime()*50, apchud_aimx, xx )
				apchud_aimy = Lerp( FrameTime()*50, apchud_aimy, yy )

				surface.SetMaterial( Mat )
				surface.SetDrawColor( Color( 0, 161, 255 ) )
				surface.DrawTexturedRectRotated( apchud_aimx, apchud_aimy, 32, 32, 0 )
			end

			if !apchud_start then
				apchud_start = true
				apchud_sglow = SysTime() +0.6
			end
			if apchud_hpp != veh:GetNWInt( "APC_HEALTH" ) then
				apchud_hpp = veh:GetNWInt( "APC_HEALTH" )
				apchud_hpg = SysTime() +1

				if apchud_hpp <= 150 and !apchud_hph then
					apchud_hph = true
					apchud_hpr = SysTime() +0.3
				elseif apchud_hpp > 150 and apchud_hph then
					apchud_hph = false
					apchud_hpr = SysTime() +0.3
				end
			end
			if apchud_app != veh:GetNWInt( "APC_AMMOP" ) then
				apchud_app = veh:GetNWInt( "APC_AMMOP" )
				apchud_apg = SysTime() +1
				if apchud_app <= 0 and !apchud_aph then
					apchud_aph = true
					apchud_apr = SysTime() +0.3
				elseif apchud_app > 0 and apchud_aph then
					apchud_aph = false
					apchud_apr = SysTime() +0.3
				end
			end

			local per1 = math.Clamp( ( apchud_sglow -SysTime() )/0.5, 0, 1 )
			local per2 = math.Clamp( ( apchud_hpg -SysTime() )/0.5, 0, 1 )
			local per3 = math.Clamp( ( apchud_apg -SysTime() )/0.5, 0, 1 )

			local per5 = math.Clamp( ( apchud_apr -SysTime() )/0.3, 0, 1 )
			if !apchud_aph then per5 = 1-per5 end
			local per7 = math.Clamp( ( apchud_hpr -SysTime() )/0.3, 0, 1 )
			if !apchud_hph then per7 = 1-per7 end

			local per8 = per1
			if apchud_hph then
				if apchud_hpg <= SysTime() then
					apchud_hpg = SysTime() +0.5
				end
				per8 = math.Clamp( ( apchud_hpg -SysTime() )/1, 0, 1 )
			end

			// Health Counter
			local num = apchud_hpp
			draw.RoundedBox( 8, 36, ScrH() -108, 230, 82, Color( 255*( 1-per7 )*per8, 161*per8*per7, 255*per8*per7, 76 ) )
			draw.SimpleText( "HEALTH", "HudDefault", 92, ScrH() -53, Color( 255*( 1-per7 ), 161*per7, 255*per7 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( num, "apc_font2", 154, ScrH() -68, Color( 255*( 1-per7 ), 161*per7, 255*per7, per2*255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( num, "apc_font1", 154, ScrH() -68, Color( 255*( 1-per7 ), 161*per7, 255*per7 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

			// Primary Ammo Counter
			local num = apchud_app
			draw.RoundedBox( 8, ScrW() -266, ScrH() -108, 228, 82, Color( 255*( 1-per5 )*per1, 161*per1*per5, 255*per1*per5, 76 ) )
			draw.SimpleText( "AMMO", "HudDefault", ScrW() -218, ScrH() -53, Color( 255*( 1-per5 ), 161*per5, 255*per5 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( num, "apc_font2", ScrW() -172, ScrH() -68, Color( 255*( 1-per5 ), 161*per5, 255*per5, per3*255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( num, "apc_font1", ScrW() -172, ScrH() -68, Color( 255*( 1-per5 ), 161*per5, 255*per5 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		end
	elseif apchud_start then
		apchud_start = false
		apchud_hpp = 0
		apchud_hpg = 0
		apchud_app = 0
		apchud_apg = 0
		apchud_aimx = ScrW()/2
		apchud_aimy = ScrH()/2
	end
end )

local hide = {
	[ "CHudHealth" ] = true,
	[ "CHudBattery" ] = true,
	[ "CHudAmmo" ] = true,
	[ "CHudSecondaryAmmo" ] = true
}
hook.Add( "HUDShouldDraw", "HL2_VANILLAAPCFIX_HIDEHUD", function( name )
	local ply = LocalPlayer()
	if IsValid( ply ) and ply:Alive() and ply:InVehicle() then
		local veh = ply:GetNWEntity( "HL2APC" )
		if IsValid( veh ) and veh:GetClass() == "prop_vehicle_apc" and ply:GetVehicle() == veh and hide[ name ] then
			return false
		end
	end
end )

hook.Add("PreDrawOutlines", "HL2_VANILLAAPCFIX_OUTLINE", function()
	local ply = LocalPlayer()
	if IsValid( ply ) and ply:Alive() and ply:InVehicle() then
		local veh = ply:GetNWEntity( "HL2APC" )
		if IsValid( veh ) and veh:GetClass() == "prop_vehicle_apc" and ply:GetVehicle() == veh then
			local tar = veh:GetNWEntity( "APC_TARGET" )
			if IsValid( tar ) and tar != Entity( 0 ) and util.IsValidModel( tar:GetModel() ) then
				if tar:IsVehicle() or tar:Health() > 0 then
					outline.Add( tar, Color( 0, 128, 255 ), OUTLINE_MODE_NOTVISIBLE )
				end
			end
		end
	end
end)