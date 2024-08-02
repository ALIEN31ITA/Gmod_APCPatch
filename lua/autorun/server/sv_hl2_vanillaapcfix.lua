// Vanilla APC Fix - Until rubat fixes it one day...
// Credits - Alien31, Phoneixf, BloodyCop, Shockpast, homonovus, and any1 who helped from the Discord
// APC - INTERACT
hook.Add("PlayerUse","HL2_VANILLAAPCFIX_USE", function(ply, ent)
    if ent:GetClass() == "prop_vehicle_apc" and !ply:InVehicle() then
        if ( !ent.APC_ReEnter or ent.APC_ReEnter <= CurTime() ) and !ent:GetDriver():IsValid()
        and ent:Health() > 0 and !ent:GetInternalVariable("m_bLocked") then
            ply:EnterVehicle(ent)
        elseif !( IsValid( ent:GetDriver() ) or ent:GetInternalVariable("m_bLocked") or ent:Health() <= 0 ) then
            return false
        end
    end
end)
// APC - ENTERING
hook.Add("PlayerEnteredVehicle","HL2_VANILLAAPCFIX_ENTER", function(ply, veh, role)
    if veh:GetClass() == "prop_vehicle_apc" then
        ply:SetNWEntity( "HL2APC", veh )
        veh:SetNWEntity( "APC_TARGET", Entity( 0 ) )
        veh.APC_ReEnter = CurTime() +0.5
    end
end)
// APC - EXIT
hook.Add("PlayerLeaveVehicle","HL2_VANILLAAPCFIX_EXIT", function(ply, veh, role)	
	if ( veh:GetClass() == "prop_vehicle_apc" ) then
        veh:StopSound( "apc_engine_idle" )
        veh:SetNWBool( "APC_SIREN", false )
        if veh.APC_Snd and veh.APC_Snd:IsPlaying() then
            veh.APC_Snd:FadeOut( 1 )
            veh.APC_Snd:ChangePitch( 60, 0.5 )
        end
        ply:SetNWEntity( "HL2APC", Entity( 0 ) )
        veh.APC_ReEnter = CurTime() +0.5
	end
end)
// APC - DRIVING

hook.Add("VehicleMove","HL2_VANILLAAPCFIX_DRIVING", function(ply, veh, mv)
	if ( veh:GetClass() == "prop_vehicle_apc" ) then
        if ply:GetNWEntity( "HL2APC" ) != veh then
            ply:SetNWEntity( "HL2APC", veh )
        end
        if veh:IsEFlagSet( EFL_NO_THINK_FUNCTION ) then
            veh:RemoveEFlags( EFL_NO_THINK_FUNCTION )
        end
		// Gun Aiming
		local playerLookAngles = ply:LocalEyeAngles()
		local playerEyeRoll =  math.NormalizeAngle(playerLookAngles.yaw -90)
		local playerEyePitch = playerLookAngles.pitch
		
		veh:SetPoseParameter("vehicle_weapon_yaw", playerEyeRoll)
		veh:SetPoseParameter("vehicle_weapon_pitch", playerEyePitch)
	
		// Rocket Aiming
		local HL2SB_APC_Target = util.TraceLine( {
		  start = ply:EyePos(),
		  endpos = ply:EyePos() + ply:EyeAngles():Forward() * 10000,
		  filter = { veh },
		} )
		
        if !IsValid( veh.DummyAPC ) then
            local dummy = ents.Create("info_target")
            dummy:Spawn()
            dummy:SetName( "["..veh:EntIndex().."]apclasertarget" )
            veh:DeleteOnRemove( dummy )
            veh.DummyAPC = dummy
        end
		local dummy, target = veh.DummyAPC, veh:GetNWEntity( "APC_TARGET" )
        dummy:SetPos(HL2SB_APC_Target.HitPos)
        veh:SetSaveValue("m_hSpecificRocketTarget", nil)
        veh:SetSaveValue("m_flMachineGunTime",CurTime()+10)
        veh:SetSaveValue("m_flRocketTime",CurTime()+10)

        if veh:GetNWInt( "APC_HEALTH" ) != veh:Health() then
            veh:SetNWInt( "APC_HEALTH", veh:Health() )
        end

        if mv:KeyDown( IN_ATTACK ) and veh.APC_NextFireP and veh.APC_NextFireP <= CurTime() then
            if veh:GetNWInt( "APC_AMMOP" ) > 0 then
                veh.APC_NextFireP = CurTime() +0.1
                veh.APC_NextAmmoP = CurTime() +2
                timer.Simple( 0, function()
                    if !IsValid( ply ) or !IsValid( veh ) or veh:Health() <= 0 then
                        return
                    end
                    local att = veh:LookupAttachment( "muzzle" )
                    if att and att != -1 then
                        local gat = veh:GetAttachment( att )
                        local bullet = {}
                        bullet.AmmoType = "AR2"
                        bullet.Attacker = ply
                        bullet.Damage = 3
                        bullet.Dir = gat.Ang:Forward()
                        bullet.Force = 1
                        bullet.Spread = Vector( 0.069760, 0.069760, 0 )
                        bullet.Tracer = 1
                        bullet.Src = gat.Pos
                        bullet.TracerName = "HelicopterTracer"
                        veh:FireBullets( bullet )

                        sound.Play( "Weapon_AR2.Single", gat.Pos )
                        local ef = EffectData()
                        ef:SetAttachment( att )
                        ef:SetEntity( veh )
                        util.Effect( "ChopperMuzzleFlash", ef )

                        veh:SetNWInt( "APC_AMMOP", veh:GetNWInt( "APC_AMMOP" ) -1 )
                        veh:SetSaveValue("m_iMachineGunBurstLeft",veh:GetNWInt( "APC_AMMOP" ))
                    end
                end )
            end
        end
        if mv:KeyDown( IN_ATTACK2 ) and veh.APC_NextFireS and veh.APC_NextFireS <= CurTime() then
            veh.APC_NextFireS = CurTime() +1.5
            veh:SetSaveValue("m_flRocketTime", 0)
            veh:SetSaveValue("m_iRocketSalvoLeft",0)
        end
        if mv:KeyPressed( IN_RELOAD ) then
            veh:SetNWBool( "APC_Siren", !veh:GetNWBool( "APC_Siren" ) )
            if veh:GetNWBool( "APC_Siren" ) then
                veh:StopSound( "Buttons.snd47" )
                veh:EmitSound( "Buttons.snd41" )
                if IsValid( veh.APC_Sprite ) then
                    veh.APC_Sprite:Fire( "ShowSprite" )
                end
            else
                veh:StopSound( "Buttons.snd41" )
                veh:EmitSound( "Buttons.snd47" )
                if IsValid( veh.APC_Sprite ) then
                    veh.APC_Sprite:Fire( "HideSprite" )
                    veh.APC_Sprite:Remove()
                end
            end
        end

        local sir = veh:GetNWBool( "APC_Siren" )
        if sir then
            if veh.APC_Snd and !veh.APC_Snd:IsPlaying() then
                veh.APC_Snd:Stop()
                veh.APC_Snd = nil
            end
            if !veh.APC_Snd then
                veh.APC_Snd = CreateSound( veh, "ambient/alarms/apc_alarm_loop1.wav" )
                veh.APC_Snd:SetSoundLevel( 150 )
                veh.APC_Snd:Play()
                veh.APC_Snd:ChangeVolume( 0 )
                veh.APC_Snd:ChangePitch( 80 )
                veh.APC_Snd:ChangePitch( 100, 1 )
                veh.APC_Snd:ChangeVolume( 1, 1 )
                veh.APC_NextSiren = CurTime() +math.Rand( 1, 3 )
            end
            if veh.APC_NextSiren and veh.APC_NextSiren <= CurTime() then
                veh.APC_NextSiren = CurTime() +math.Rand( 1, 3 )
                sound.EmitHint( SOUND_COMBAT, veh:WorldSpaceCenter(), 3072, 1, veh )
            end
        elseif veh.APC_Snd and veh.APC_Snd:IsPlaying() then
            veh.APC_Snd:FadeOut( 1 )
            veh.APC_Snd:ChangePitch( 60, 0.5 )
        end
	end
end)
// APC - GUN SPAWN POSITION
hook.Add( "PlayerSpawnedVehicle", "HL2_VANILLA_APCFIX", function( ply, ent )
	if ( ent:GetClass() == "prop_vehicle_apc" ) then
		local oldPoseParameters = table.Copy(ent:GetInternalVariable("m_flPoseParameter"))
		oldPoseParameters[1] = 0.5
		ent:SetSaveValue("m_flPoseParameter", oldPoseParameters)
	end
end )
// APC - KILL USER WHEN DESTROYED
local formatMsg = "OnDeath apc_damage_%d:RunCode:0:-1"
if !VANILLAHL2APCs then
    VANILLAHL2APCs = {}
end
hook.Add("OnEntityCreated", "APCLuaOnDestroyed", function(ent)
    if ( !IsValid(ent) ) then return end
    if ent:GetClass() == "prop_vehicle_apc" then
        ent:SetKeyValue( "vehiclescript", "scripts/vehicles/apc_patch.txt" )
        local delay = CurTime() +1
        ent.APC_ReEnter = num
        ent.APC_NextFireP = delay
        ent.APC_NextFireS = delay
        ent.APC_NextAmmoP = delay
        ent.APC_Tracking = delay
        ent.APC_TrackCool = delay
        ent.APC_NextSiren = delay
        ent:SetNWInt( "APC_AMMOP", 0 )
        ent:SetNWInt( "APC_HEALTH", 0 )
        ent:SetNWEntity( "APC_TARGET", Entity( 0 ) )
        ent:SetNWInt( "APC_SIREN", false )

        timer.Simple(0, function()
            if ( !IsValid(ent) ) then return end
            ent:SetName("npc_capc_" .. ent:EntIndex())
            
            if ent.APC_NPCDriver and !IsValid( ent:GetDriver() ) then
                ent:SetKeyValue( "vehiclescript", "scripts/vehicles/apc_npc.txt" )
                local HL2_APCGetName = ent:GetName()
                local HL2_APCDriver = ents.Create("npc_apcdriver")
                HL2_APCDriver:SetKeyValue( "Vehicle", HL2_APCGetName)
                HL2_APCDriver:Spawn()
                HL2_APCDriver:Activate()
                ent:DeleteOnRemove(HL2_APCDriver)
            end

            ent:CallOnRemove( "APCStopSiren", function( ent )
                if IsValid( ent ) and ent.APC_Snd then
                    ent.APC_Snd:Stop()
                    ent.APC_Snd = nil
                end
            end )
            
            ent:SetNWEntity( "APC_TARGET", Entity( 0 ) )
            ent:SetNWInt( "APC_SIREN", false )
            table.insert( VANILLAHL2APCs, ent )
            ent.APC_ReEnter = CurTime() +FrameTime()
            ent.APC_NextFireP = CurTime()
            ent.APC_NextFireS = CurTime()
            ent.APC_NextAmmoP = CurTime()
            ent.APC_Tracking = CurTime()
            ent.APC_TrackCool = CurTime()
            ent.APC_NextSiren = CurTime()
            if IsValid( ent.DummyAPC ) then
                ent.DummyAPC:Remove()
            end

            if ( !IsValid(ent.LuaRunEnt) ) then
                ent.LuaRunEnt = ents.Create("lua_run")
                ent.LuaRunEnt:SetName("apc_damage_" .. ent:EntIndex())
                ent.LuaRunEnt:SetKeyValue("Code", "hook.Run(\"OnAPCDestroyed\", Entity(" .. ent:EntIndex() .. "))")
                ent.LuaRunEnt:Spawn()
                ent:DeleteOnRemove( ent.LuaRunEnt )
            end

            local fireMsg = formatMsg:format(ent:EntIndex(), ent:EntIndex())
            ent:Fire("AddOutput", fireMsg)
        end)
    elseif ent:GetClass() == "apc_missile" then
        timer.Simple(0, function()
            if !IsValid(ent) then return end
            local own = ent.Owner
            if IsValid( own ) and own:GetClass() == "prop_vehicle_apc" and ( !IsValid( own:GetDriver() ) or own:GetDriver():IsPlayer() ) then
                own:SetSaveValue("m_flRocketTime", CurTime()+10)
                own:SetSaveValue("m_iRocketSalvoLeft",1)
                own.APC_NextFireS = CurTime() +1.5
                local tname = "["..ent:EntIndex().."]hl2apcmissile"
                timer.Create( tname, 0, 0, function()
                    if !IsValid( ent ) then
                        timer.Remove( tname )
                        return
                    end
                    if IsValid( own ) and own:GetClass() == "prop_vehicle_apc" then
                        local tar = IsValid( own.DummyAPC ) and own.DummyAPC:GetPos() or nil
                        local ota = own:GetNWEntity( "APC_TARGET" )
                        if IsValid( ota ) and ota != Entity( 0 ) then
                            tar = ( ota:IsPlayer() or ota:IsNPC() ) and ota:BodyTarget( ent:GetPos() ) or ota:WorldSpaceCenter()
                        end
                        local vel = ( tar -ent:WorldSpaceCenter() ):GetNormalized()
                        ent:SetLocalVelocity( ent:GetVelocity()*0.95 +vel*64 )
                        ent:SetAngles( ent:GetVelocity():Angle() )
                    end
                end )
                ent:SetSaveValue("m_hSpecificRocketTarget", nil )
                ent:SetSaveValue("m_hOwnerEntity", nil )
                if IsValid( own:GetDriver() ) then
                    ent:SetOwner( own:GetDriver() )
                    ent:SetPhysicsAttacker( own:GetDriver(), 60 )
                end
            end
        end)
    end
end)
// APC - SAME AS BEFORE
hook.Add("OnAPCDestroyed", "APCGotDestroyed", function(ent)
    if ( IsValid(ent.LuaRunEnt) ) then
        ent.LuaRunEnt:Remove()
        ent:StopSound( "apc_engine_idle" )
		local ply = ent:GetDriver()
        if IsValid( ply ) and ply:IsPlayer() then
            ply:Kill()
        end

        if !ent:GetName() or ent:GetName() == "" then
		    ent:SetName("npc_capc_" .. ent:EntIndex())
        end
		local HL2_APCGetName = ent:GetName()
		local HL2_APCDriver = ents.Create("npc_apcdriver")
		HL2_APCDriver:SetKeyValue( "Vehicle", HL2_APCGetName)
		HL2_APCDriver:Spawn()
		HL2_APCDriver:Activate()
		ent:DeleteOnRemove(HL2_APCDriver)
    end
end)
// APC - AMMO REFILLING AND MISSILE TRACKER
hook.Add("Think", "VanillaAPCAmmoRefill", function()
    if !table.IsEmpty( VANILLAHL2APCs ) then
        for num, veh in pairs( VANILLAHL2APCs ) do
            if !IsValid( veh ) then
                table.remove( VANILLAHL2APCs, num )
                continue
            end
            local amp = veh:GetNWInt( "APC_AMMOP" )
            if amp < 10 and veh.APC_NextFireP <= CurTime() and veh.APC_NextAmmoP <= CurTime() then
                veh:SetNWInt( "APC_AmmoP", 10 )
                veh:SetSaveValue("m_iMachineGunBurstLeft",veh:GetNWInt( "APC_AMMOP" ))
            end
            if veh.APC_TrackCool and veh.APC_TrackCool <= CurTime() then
                veh.APC_TrackCool = CurTime() +0.1
                local att = veh:LookupAttachment( "gun_def" )
                if att then
                    local tar, deg
                    local gat = veh:GetAttachment( att )
                    for k, v in pairs( ents.FindInCone( gat.Pos, gat.Ang:Forward(), 3072, 0.75 ) ) do
                        if !IsValid( v ) or ( !v:IsPlayer() and !v:IsNPC() and !v:IsNextBot() and !v:IsVehicle() ) then
                            continue
                        end
                        if v == veh or ( IsValid( veh:GetDriver() ) and veh:GetDriver() == v ) then
                            continue
                        end
                        if ( v:IsPlayer() and !v:Alive() ) or ( v:IsNPC() and ( v:GetNPCState() == NPC_STATE_DEAD or v:GetNPCState() == NPC_STATE_PLAYDEAD ) ) or ( v:IsNextBot() and v:Health() <= 0 ) then
                            continue
                        end
                        local tr = util.TraceLine( {
                            start = gat.Pos,
                            endpos = v:IsNextBot() and v:WorldSpaceCenter() or v:BodyTarget( gat.Pos ),
                            filter = { v, veh },
                            mask = MASK_SHOT,
                        } )
                        if !tr.Hit then
                            local _, aa = WorldToLocal( Vector(), gat.Ang, Vector(), ( tr.HitPos -gat.Pos ):Angle() )
                            local de2 = math.sqrt( aa.Pitch^2 +aa.Yaw^2 )
                            if !deg or de2 < deg then
                                deg = de2
                                tar = v
                            end
                        end
                    end
                    if IsValid( tar ) then
                        if IsValid( veh.DummyAPC ) then
                            veh.DummyAPC:SetPos( tar:GetPos() )
                            veh.APC_Tracking = CurTime() +0.2
                        end
                        if veh:GetNWEntity( "APC_TARGET" ) != tar then
                            veh:SetNWEntity( "APC_TARGET", tar )
                        end
                    elseif veh:GetNWEntity( "APC_TARGET" ) != Entity( 0 ) then
                        veh:SetNWEntity( "APC_TARGET", Entity( 0 ) )
                    end
                end
            end
        end
    end
end)
// APC - LOCKED SOUND FIX
hook.Add("EntityEmitSound", "VanillaAPCLockSoundFix", function(tab)
    local ent = tab.Entity
    if IsValid( ent ) and ent:GetClass() == "prop_vehicle_apc" and !ent:GetInternalVariable("m_bLocked") and tab.OriginalSoundName == "combine.door_lock" then
        if IsValid( ent:GetDriver() ) and ent:GetDriver():IsPlayer() then
            return false
        end
    end
end )
// APC - APC DAMAGE BOOST / DRIVER DAMAGE IMMUNE
hook.Add("EntityTakeDamage", "VanillaAPCDamage", function(tar,dmg)
	if tar:IsPlayer() and tar:Alive() and tar:InVehicle() then
		local veh = tar:GetNWEntity( "HL2APC" )
		if IsValid( veh ) and veh:GetClass() == "prop_vehicle_apc" and tar:GetVehicle() == veh and veh:Health() > 0 then
			dmg:ScaleDamage(0)
            return true
		end
	end

    local atk, inf = dmg:GetAttacker(), dmg:GetInflictor()
    if IsValid( atk ) and IsValid( inf ) and inf:GetClass() == "prop_vehicle_apc" and atk:IsPlayer() and IsValid( atk:GetVehicle() ) and atk:GetVehicle() == inf then
        dmg:ScaleDamage( 8 )
    end
    if IsValid( atk ) and IsValid( inf ) and inf:GetClass() == "env_explosion" and IsValid( inf.Owner )
    and inf.Owner:GetClass() == "prop_vehicle_apc" and IsValid( atk:GetDriver() ) and atk:GetDriver():IsPlayer() then
        dmg:ScaleDamage( 2 )
    end
end)