/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <xs>
#include <cstrike>

#define PLUGIN "Portal"
#define VERSION "1.0"
#define AUTHOR "DarkGL & R3X"

#define SOUNDS
#define SPRITES
//#define TEST
//#define TRACE_HULL

#define MAX 32
#define IsPlayer(%1) (1<=%1<=MAX)

new const szClassNameNieb[] = "portal_shot_niebieski"
new const szClassNamePom[] = "portal_shot_pomaranczowy"
new const szClassTelNieb[] = "teleport_nieb";
new const szClassTelPom[] = "teleport_pom";
new const v_model[] = "models/portal/v_portal.mdl";
new const portal[] = "models/portal/portal.mdl";
new const w_model[] = "models/rpgrocket.mdl";

#if defined SOUNDS
new const portal_shot_blue[] = "portal/portalgun_shoot_blue1.wav"
new const portal_shot_red[] = "portal/portalgun_shoot_red1.wav"
new const soundOpen[][]={
	"portal/portal_open1.wav",
	"portal/portal_open2.wav",
	"portal/portal_open3.wav"
}
new const soundClose[][]={
	"portal/portal_close1.wav",
	"portal/portal_close2.wav"
}
new const soundEnter[][]={
	"portal/portal_enter1.wav",
	"portal/portal_enter2.wav"
}
new const soundInvalid[]= "portal/portal_invalid_surface3.wav";
#endif

new player_ent[MAX+1]
new Float:fNextAttack[MAX+1]
new bool:bMode[MAX+1]
new iEnt[MAX+1][2];
new iTel[MAX+1][2]

#define OFFSET_WEAPONOWNER 41
#define OFFSET_LINUX_WEAPONS 4
#define OFFSET_ACTIVEITEM 374
#define OFFSET_LINUX_PLAYER 5

#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47

new const szClassTouch[][]={
	"worldspawn",
	"func_wall",
	"func_door",
	"func_door_rotating",
	"func_breakable"
}

#define  MAX_DISTANCE 70.0
#define  MIN_DISTANCE 50.0

#if defined SPRITES
new sprite;
new g_trail;
new spriteInvalid[2];
#endif

enum eCvar{
	SpriteType,
	FallDamge,
	SpeedBullet,
	PortalCost,
	SpawnPortal
}

new pCvars[eCvar]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Killed,"player","ham_KilledPost",1)
	RegisterHam( Ham_TakeDamage, "player", "ham_damage" );
	RegisterHam(Ham_Spawn,"player","ham_Spawned",1)
	
	register_logevent("Koniec_Rundy", 2, "1=Round_End") 
	
	register_forward(FM_CmdStart,"fwd_CmdStart")
	
	register_touch(szClassTelPom,"*","touchTeleport")
	register_touch(szClassTelNieb,"*","touchTeleport")
	
	for(new i = 0;i<sizeof szClassTouch;i++){	
		register_touch(szClassTouch[i],szClassNameNieb,"touchNieb")
		register_touch(szClassTouch[i],szClassNamePom,"touchPom")
	}
	
	register_clcmd("say /portal","buyPortal");
	register_clcmd("drop","cmdDrop")
	
	register_clcmd("give_portal","give_weapon",ADMIN_CFG,"<nick>")
	
	return PLUGIN_CONTINUE;
}

public ham_Spawned(id){
	if(!is_user_alive(id)){
		return HAM_IGNORED;
	}
	if(get_pcvar_num(pCvars[SpawnPortal]) && !pev_valid(player_ent[id])){
		new szWeaponName[64],bool:bContinue = false;
		new num, iWeapons[32] 
		
		get_user_weapons(id, iWeapons, num) 
		for(new i = 1;i<=30;i++){
			if(i == 2 || i == 4 || i == 6 || i == 9 || i == 25 || i == 29){
				continue;
			}
			bContinue = false;
			for (new j=0; j<num; j++) 
			{
				if(iWeapons[j] == i){
					bContinue = true;
					break;
				}
			} 
			if(!bContinue){
				get_weaponname(i,szWeaponName,charsmax(szWeaponName));
				player_ent[id] = give_item(id,szWeaponName)
				RegisterHamFromEntity(Ham_Item_Deploy,player_ent[id],"ham_ItemDeploy_Post",1)
				set_pdata_float(player_ent[id], m_flNextPrimaryAttack, 99999.0, OFFSET_LINUX_WEAPONS)
				set_pdata_float(player_ent[id], m_flNextSecondaryAttack, 99999.0, OFFSET_LINUX_WEAPONS)
				break;
			}
		}
		
	}
	return HAM_IGNORED;
}

public buyPortal(id){
	new cost = get_pcvar_num(pCvars[PortalCost]);
	if(cost < 0){
		return PLUGIN_HANDLED;
	}
	if(cs_get_user_money(id) < cost){
		client_print(id,print_console,"Masz za malo kasy");
	}
	else
	{
		if(!is_user_alive(id)){
			client_print(id,print_console,"Musisz byc zywy");
			return PLUGIN_HANDLED
		}
		if(pev_valid(player_ent[id])){
			client_print(id,print_console,"Masz juz portal guna");
			return PLUGIN_HANDLED
		}
		new szWeaponName[64],bool:bContinue = false;
		new num, iWeapons[32] 
		
		get_user_weapons(id, iWeapons, num) 
		for(new i = 1;i<=30;i++){
			if(i == 2 || i == 4 || i == 6 || i == 9 || i == 25 || i == 29){
				continue;
			}
			bContinue = false;
			for (new j=0; j<num; j++) 
			{
				if(iWeapons[j] == i){
					bContinue = true;
					break;
				}
			} 
			if(!bContinue){
				get_weaponname(i,szWeaponName,charsmax(szWeaponName));
				player_ent[id] = give_item(id,szWeaponName)
				RegisterHamFromEntity(Ham_Item_Deploy,player_ent[id],"ham_ItemDeploy_Post",1)
				set_pdata_float(player_ent[id], m_flNextPrimaryAttack, 99999.0, OFFSET_LINUX_WEAPONS)
				set_pdata_float(player_ent[id], m_flNextSecondaryAttack, 99999.0, OFFSET_LINUX_WEAPONS)
				break;
			}
		}
		cs_set_user_money(id,cs_get_user_money(id) - cost,0);
		
	}
	return PLUGIN_HANDLED;
}

public ham_damage( this, inflictor, attacker, Float:damage, damagebits )
{
	if( !( damagebits & DMG_FALL ) || !IsPlayer(this))
	return HAM_IGNORED;
	
	new bool:bCvar = !(!get_pcvar_num(pCvars[FallDamge]))
	
	if(!bCvar || (bCvar && !pev_valid(player_ent[this]))){
		return HAM_IGNORED;
	}
	
	return HAM_SUPERCEDE;
}

public Koniec_Rundy()
{
	remove_entity_name(szClassTelPom)
	remove_entity_name(szClassTelNieb)
	for(new i = 1;i<=MAX;i++){
		iTel[i][0] = 0;
		iTel[i][1] = 0;
	}
}

public touchTeleport(portal,id){
	if(pev_valid(id)){
		if(pev(id,pev_movetype) == MOVETYPE_FOLLOW){
			return PLUGIN_CONTINUE;
		}
		static szClassName[64];
		pev(id,pev_classname,szClassName,charsmax(szClassName));
		if(equal(szClassName,szClassTelPom) || equal(szClassName,szClassTelNieb) || equal(szClassName,szClassNameNieb) || equal(szClassName,szClassNamePom)){
			return PLUGIN_CONTINUE;
		}
		moveTo(id,portal,pev(portal,pev_iuser1))
	}
	return PLUGIN_CONTINUE;
}


moveTo(id, in, out){
	if(pev_valid(out)){
		#if defined TRACE_HULL
		new hull = HULL_POINT;
		
		if(is_user_alive(id)){
			hull = HULL_HUMAN;
		}
		#endif
		
		new Float:fDistance = MIN_DISTANCE;
		while(fDistance <= MAX_DISTANCE){
			new Float:fOrigin[3];
			pev(out, pev_origin, fOrigin);
			
			new Float:fAngles[3];
			pev(out, pev_vuser1, fAngles);
			
			xs_vec_mul_scalar(fAngles, fDistance, fAngles);
			xs_vec_add(fOrigin, fAngles, fOrigin);
			
			new Float:fMins[3],Float:fMaxs[3];
			pev(id,pev_mins,fMins);
			pev(id,pev_maxs,fMaxs);
			
			
			
			#if defined TRACE_HULL
			if(!trace_hull(fOrigin, hull, id, 0)){
				#else
				if(checkPortalPlace(fOrigin,fMins,fMaxs)){
					#endif
					set_pev(id, pev_origin, fOrigin);
					
					#if defined SOUNDS
					engfunc(EngFunc_EmitAmbientSound, 0,fOrigin, soundEnter[random(sizeof soundEnter)],VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					#endif
					
					parseAngle(id, in, out);
					
					break;
				}
				fDistance += 10.0;
			}
		}
	}

	public fwd_CmdStart(id, uc_handle, seed) {
		if(!is_user_alive(id) || player_ent[id] != get_pdata_cbase(id,OFFSET_ACTIVEITEM,OFFSET_LINUX_PLAYER)){
			return FMRES_IGNORED;
		}
		
		new buttons = get_uc(uc_handle,UC_Buttons)
		new oldbuttons = get_user_oldbutton(id);
		
		if(buttons&IN_ATTACK && fNextAttack[id] < get_gametime()){
			fNextAttack[id] = get_gametime() + 0.5;
			create_shot_portal(id);
			set_animation(id,random_num(1,2))
		}
		if(buttons & IN_ATTACK2 && !(oldbuttons & IN_ATTACK2)){
			bMode[id] = !bMode[id];
			client_print(id,print_center,"Tryb %s",bMode[id] ? "Niebieski":"Pomaranczowy")
		}
		return FMRES_HANDLED
	}

	public plugin_precache(){
		
		cvar_register();
		
		precache_model(v_model);
		precache_model(portal);
		precache_model(w_model);
		#if defined SPRITES
		sprite = precache_model("sprites/white.spr");
		g_trail = precache_model("sprites/smoke.spr")
		spriteInvalid[0] = precache_model("sprites/portal/pom.spr") ;
		spriteInvalid[1] = precache_model("sprites/portal/nieb.spr") ;
		#endif
		
		#if defined SOUNDS
		precache_sound(portal_shot_blue)
		precache_sound(portal_shot_red);
		for(new i = 0 ; i<sizeof soundOpen;i++){
			precache_sound(soundOpen[i])
		}
		for(new i = 0 ; i<sizeof soundClose;i++){
			precache_sound(soundClose[i])
		}
		for(new i = 0 ; i<sizeof soundEnter;i++){
			precache_sound(soundEnter[i])
		}
		precache_sound(soundInvalid)
		#endif
		
		new szConfDir[64],szFullDir[128];
		get_configsdir(szConfDir,charsmax(szConfDir));
		formatex(szFullDir,charsmax(szFullDir),"%s/portal.cfg",szConfDir);
		if(!file_exists(szFullDir)){
			#if defined SPRITES
			write_file(szFullDir,"// 1 or 2 difrent sprites 0 off this")
			write_file(szFullDir,"portal_sprite 1");
			#endif
			
			write_file(szFullDir,"// 1 - no fall damage 0 - normal (no fall damage for person who have portal gun)")
			write_file(szFullDir,"portal_fall_damage 1");
			
			write_file(szFullDir,"// speed of portal bullet")
			write_file(szFullDir,"portal_bullet_speed 1500");
			
			write_file(szFullDir,"//how much money you must have to buy portal with /portal command in say number of negative side off this")
			write_file(szFullDir,"portal_cost -1");
			
			write_file(szFullDir,"//portal gun for free on spawn ?")
			write_file(szFullDir,"portal_spawn 0")
		}
		server_cmd("exec %s",szFullDir)
		
	}

	public client_connect(id){
		player_ent[id] = 0;
		iTel[id][0] = 0;
		iTel[id][1] = 0;
	}

	public client_disconnect(id){
		player_ent[id] = 0;
		iTel[id][0] = 0;
		iTel[id][1] = 0;
	}

	public touchNieb(touched,toucher){
		if(!pev_valid(toucher)){
			remove_entity(toucher)
			return PLUGIN_CONTINUE;
		}
		
		missileTouche(toucher,0);
		
		return PLUGIN_CONTINUE;
	}

	public touchPom(touched,toucher){	
		if(!pev_valid(toucher)){
			remove_entity(toucher)
			return PLUGIN_CONTINUE;
		}
		
		missileTouche(toucher,1);
		
		return PLUGIN_CONTINUE;
	}

	public missileTouche(iEntLocal,iPos){
		new Float:fOrigin[3],iOwner;
		
		pev(iEntLocal,pev_origin,fOrigin);
		
		iOwner = pev(iEntLocal,pev_owner);
		
		new Float:fVelo[3],Float:fEndOrigin[3];
		
		pev(iEntLocal, pev_velocity, fVelo)
		
		xs_vec_normalize(fVelo,fVelo)
		
		xs_vec_mul_scalar(fVelo,50.0,fVelo);
		
		xs_vec_add(fOrigin,fVelo,fEndOrigin);
		
		new ptr = create_tr2()
		
		new Float:vfNormal[3]
		
		engfunc(EngFunc_TraceLine, fOrigin, fEndOrigin, IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS, iEntLocal, ptr)
		
		get_tr2(ptr, TR_vecPlaneNormal, vfNormal);
		
		new Float:fOrigin3[3];
		get_tr2(ptr, TR_vecEndPos, fOrigin3);
		
		free_tr2(ptr)
		
		if(!validWall(fOrigin3,vfNormal) || !checkPlace(fOrigin3,iPos,iOwner)){
			#if defined SOUNDS
			engfunc(EngFunc_EmitAmbientSound, 0,fOrigin3, soundInvalid,VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			#endif
			
			pev(iEntLocal, pev_velocity, fVelo)
			
			xs_vec_normalize(fVelo,fVelo)
			
			xs_vec_mul_scalar(fVelo,-4.0,fVelo);
			xs_vec_add(fOrigin,fVelo,fOrigin3);
			
			#if defined SPRITES
			for(new i = 1; i < 6; i++) {
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin3,0)
				write_byte(TE_SPRITETRAIL)
				engfunc(EngFunc_WriteCoord, fOrigin3[0])
				engfunc(EngFunc_WriteCoord, fOrigin3[1])
				engfunc(EngFunc_WriteCoord, fOrigin3[2])
				engfunc(EngFunc_WriteCoord, fOrigin3[0])
				engfunc(EngFunc_WriteCoord, fOrigin3[1])
				engfunc(EngFunc_WriteCoord, fOrigin3[2] + 10)
				write_short(iPos == 0 ? spriteInvalid[1] : spriteInvalid[0])
				write_byte(2)
				write_byte(1)
				write_byte(1)
				write_byte(random_num(5,10))
				write_byte(5)
				message_end()
			}
			#endif
			
			remove_entity(iEntLocal);
			return PLUGIN_CONTINUE;
		}
		
		new Float:fOldNormal[3];
		xs_vec_copy(vfNormal, fOldNormal);
		
		vector_to_angle(vfNormal, vfNormal);
		
		//cosik
		pev(iEntLocal, pev_velocity, fVelo)
		
		xs_vec_normalize(fVelo,fVelo)
		
		xs_vec_mul_scalar(fVelo,-4.0,fVelo);
		xs_vec_add(fOrigin,fVelo,fOrigin);
		//
		
		remove_entity(iEntLocal);
		
		iEnt[iOwner][iPos] = 0;
		
		if(pev_valid(iTel[iOwner][iPos])){ 
			new Float:fOrigin2[3];
			pev(iTel[iOwner][iPos],pev_origin,fOrigin2)
			#if defined SOUNDS
			engfunc(EngFunc_EmitAmbientSound, 0,fOrigin2, soundClose[random(sizeof soundClose)],VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			#endif
			remove_entity(iTel[iOwner][iPos]);
			iTel[iOwner][iPos] = 0;
		}
		
		iTel[iOwner][iPos] =  engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
		set_pev(iTel[iOwner][iPos],pev_classname,iPos == 0 ? szClassTelNieb : szClassTelPom);
		
		set_pev(iTel[iOwner][iPos],pev_origin,fOrigin);
		
		set_pev(iTel[iOwner][iPos],pev_solid,SOLID_TRIGGER)
		set_pev(iTel[iOwner][iPos],pev_movetype,MOVETYPE_FLY)
		
		engfunc(EngFunc_SetModel, iTel[iOwner][iPos], portal)
		
		set_pev(iTel[iOwner][iPos],pev_skin,iPos == 0 ? 0 : 1);
		
		#if defined SOUNDS
		engfunc(EngFunc_EmitAmbientSound, 0,fOrigin, soundOpen[random(sizeof soundOpen)],VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		#endif
		
		new Float:fMins[3],Float:fMax[3],Float:mul[3];
		
		mul[0] = floatabs(floatabs(fOldNormal[0])-1.0)
		mul[0] = mul[0] + 0.1 > 1.0 ? mul[0]:mul[0]+0.1
		
		mul[1] = floatabs(floatabs(fOldNormal[1])-1.0)
		mul[1] = mul[1] + 0.1 > 1.0 ? mul[1]:mul[1]+0.1
		
		mul[2] = floatabs(floatabs(fOldNormal[2])-1.0)
		mul[2] = mul[2] + 0.1 > 1.0 ? mul[2]:mul[2]+0.1
		
		fMins[0] = floatmul(mul[0],-20.0)-2.0;
		fMins[1] = floatmul(mul[1],-10.0)-2.0;
		fMins[2] = floatmul(mul[2],-42.0)-2.0
		
		fMax[0] = floatmul(mul[0],20.0)+2.0;
		fMax[1] = floatmul(mul[1],10.0)+2.0;
		fMax[2] = floatmul(mul[2],42.0)+2.0
		
		engfunc(EngFunc_SetSize, iTel[iOwner][iPos],fMins, fMax)
		
		set_pev(iTel[iOwner][iPos], pev_angles, vfNormal);
		
		set_pev(iTel[iOwner][iPos],pev_iuser1,iTel[iOwner][iPos == 0 ? 1 : 0]);
		
		if(pev_valid(iTel[iOwner][iPos == 0 ? 1 : 0]) && !pev_valid(pev(iTel[iOwner][iPos == 0 ? 1 : 0],pev_iuser1))){
			set_pev(iTel[iOwner][iPos == 0 ? 1 : 0],pev_iuser1,iTel[iOwner][iPos])
		}
		
		set_pev(iTel[iOwner][iPos], pev_vuser1, fOldNormal);
		
		set_pev(iTel[iOwner][iPos],pev_owner,iOwner);
		
		return PLUGIN_CONTINUE;
	}

	public give_weapon(id,level,cid){
		if(!cmd_access(id,level,cid,2)){
			return PLUGIN_HANDLED;
		}
		new szString[64];
		read_argv(1,szString,charsmax(szString));
		new find = find_player("bl",szString);
		if(!find){
			client_print(id,print_console,"[Portal Gun] Nie moge znalezc takiego gracza");
			return PLUGIN_HANDLED;
		}
		else
		{
			if(!is_user_alive(find)){
				client_print(id,print_console,"[Portal Gun] Gracz musi byc zywy");
				return PLUGIN_HANDLED
			}
			new szName[64];
			get_user_name(find,szName,charsmax(szName));
			if(pev_valid(player_ent[find])){
				client_print(id,print_console,"[Portal Gun] %s ma juz Portal Guna",szName);
				return PLUGIN_HANDLED
			}
			else
			{
				client_print(id,print_console,"[Portal Gun] Dales portal %s",szName);
			}
		}
		new szWeaponName[64],bool:bContinue = false;
		new num, iWeapons[32] 
		
		get_user_weapons(id, iWeapons, num) 
		for(new i = 1;i<=30;i++){
			if(i == 2 || i == 4 || i == 6 || i == 9 || i == 25 || i == 29){
				continue;
			}
			bContinue = false;
			for (new j=0; j<num; j++) 
			{
				if(iWeapons[j] == i){
					bContinue = true;
					break;
				}
			} 
			if(!bContinue){
				get_weaponname(i,szWeaponName,charsmax(szWeaponName));
				player_ent[id] = give_item(id,szWeaponName)
				RegisterHamFromEntity(Ham_Item_Deploy,player_ent[id],"ham_ItemDeploy_Post",1)
				set_pdata_float(player_ent[id], m_flNextPrimaryAttack, 99999.0, OFFSET_LINUX_WEAPONS)
				set_pdata_float(player_ent[id], m_flNextSecondaryAttack, 99999.0, OFFSET_LINUX_WEAPONS)
				break;
			}
		}
		return PLUGIN_HANDLED;
	}

	public ham_ItemDeploy_Post(weapon_ent)
	{
		static owner
		owner = get_pdata_cbase(weapon_ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
		
		if(!is_user_alive(owner)){
			return HAM_IGNORED;
		}
		set_pev(owner,pev_viewmodel2,v_model);
		
		set_animation(owner,6)
		return HAM_IGNORED;
	}

	public ham_KilledPost(id){
		if(is_user_connected(id)){
			player_ent[id] = 0;
		}
	}


	public cmdDrop(id){
		if(player_ent[id] == get_pdata_cbase(id,OFFSET_ACTIVEITEM,OFFSET_LINUX_PLAYER)){
			return PLUGIN_HANDLED;
		}
		return PLUGIN_CONTINUE;
	}

	public create_shot_portal(id){
		new iPos = bMode[id] ? 0 : 1;
		if(pev_valid(iEnt[id][iPos]) && pev(iEnt[id][iPos],pev_owner) == id){
			engfunc(EngFunc_RemoveEntity,iEnt[id][iPos])
			iEnt[id][iPos] = 0;
		}
		iEnt[id][iPos] =  engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		
		if(!pev_valid(iEnt[id][iPos])){
			return PLUGIN_CONTINUE;
		}
		
		set_pev(iEnt[id][iPos],pev_classname,bMode[id] ? szClassNameNieb : szClassNamePom);
		
		new Float:Origin[3], Float: vAngle[3], Float: Velocity[3];
		
		pev(id,pev_v_angle,vAngle)
		
		new iOrigin[3];
		get_user_origin(id,iOrigin,1)
		IVecFVec(iOrigin,Origin)
		
		#if defined SOUNDS
		engfunc(EngFunc_EmitAmbientSound, 0,Origin, bMode[id] ? portal_shot_blue : portal_shot_red,VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		#endif
		
		set_pev(iEnt[id][iPos],pev_origin,Origin);
		
		vAngle[0] *= -1.0;
		
		set_pev(iEnt[id][iPos],pev_angles,vAngle)
		
		set_pev(iEnt[id][iPos],pev_solid,SOLID_TRIGGER)
		set_pev(iEnt[id][iPos],pev_movetype,MOVETYPE_FLY)
		
		VelocityByAim(id, get_pcvar_num(pCvars[SpeedBullet]) , Velocity);
		
		set_pev(iEnt[id][iPos],pev_owner,id)
		
		set_pev(iEnt[id][iPos],pev_velocity,Velocity)
		
		engfunc(EngFunc_SetModel, iEnt[id][iPos], w_model)
		
		engfunc(EngFunc_SetSize, iEnt[id][iPos], {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0})
		
		set_rendering(iEnt[id][iPos], kRenderFxGlowShell, bMode[id] ? 0:255,bMode[id] ? 0:165,bMode[id] ? 255:0, kRenderTransColor, 1) 
		
		#if defined SPRITES
		new iMode = get_pcvar_num(pCvars[SpriteType]);
		if(iMode){
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMFOLLOW)
			write_short(iEnt[id][iPos])
			write_short(iMode == 1 ? sprite:g_trail);
			write_byte(10)
			write_byte(5)
			if(bMode[id]){
				write_byte(0)
				write_byte(0)
				write_byte(255)
			}
			else{
				write_byte(255)
				write_byte(165)
				write_byte(0)
			}
			write_byte(192)
			message_end()
		}
		#endif
		
		return PLUGIN_CONTINUE;
	}


	stock bool:validWall(const Float:fOrigin[3], Float:fNormal[3], Float:width=40.0, Float:height = 65.0){
		new Float:fInvNormal[3];
		xs_vec_neg(fNormal, fInvNormal);
		
		new Float:fPoint[3];
		xs_vec_add(fOrigin, fNormal, fPoint);
		
		new Float:fNormalUp[3];
		new Float:fNormalRight[3];
		vector_to_angle(fNormal, fNormalUp);
		
		fNormalUp[0] = -fNormalUp[0];
		
		angle_vector(fNormalUp, ANGLEVECTOR_RIGHT, fNormalRight);
		angle_vector(fNormalUp, ANGLEVECTOR_UP, fNormalUp);
		
		xs_vec_mul_scalar(fNormalUp, height/2, fNormalUp);
		xs_vec_mul_scalar(fNormalRight, width/2, fNormalRight);
		
		new Float:fPoint2[3];
		xs_vec_add(fPoint, fNormalUp, fPoint2);
		xs_vec_add(fPoint2, fNormalRight, fPoint2);
		if(!traceToWall(fPoint2, fInvNormal))
		return false;
		
		xs_vec_add(fPoint, fNormalUp, fPoint2);
		xs_vec_sub(fPoint2, fNormalRight, fPoint2);
		if(!traceToWall(fPoint2, fInvNormal))
		return false;
		
		xs_vec_sub(fPoint, fNormalUp, fPoint2);
		xs_vec_sub(fPoint2, fNormalRight, fPoint2);
		if(!traceToWall(fPoint2, fInvNormal))
		return false;
		
		xs_vec_sub(fPoint, fNormalUp, fPoint2);
		xs_vec_add(fPoint2, fNormalRight, fPoint2);
		if(!traceToWall(fPoint2, fInvNormal))
		return false;
		
		return true;
	}

bool:traceToWall(const Float:fOrigin[3], const Float:fVec[3]){
		new Float:fOrigin2[3];
		xs_vec_add(fOrigin, fVec, fOrigin2);
		xs_vec_add(fOrigin2, fVec, fOrigin2);
		
		new tr = create_tr2();
		engfunc(EngFunc_TraceLine, fOrigin, fOrigin2, IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS, 0, tr);
		new Float:fFrac;
		get_tr2(tr, TR_flFraction, fFrac);
		free_tr2(tr);
		
		if( floatabs(fFrac - 0.5) <= 0.02 ){
			return true;
		}
		
		return false;
	}

	set_animation(id, anim) {
		set_pev(id, pev_weaponanim, anim)
		
		message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
		write_byte(anim)
		write_byte(pev(id, pev_body))
		message_end()
	} 

	parseAngle(id, in, out){
		new Float:fAngles[3];
		pev(id, pev_v_angle, fAngles);
		angle_vector(fAngles, ANGLEVECTOR_FORWARD, fAngles);
		
		new Float:fNormalIn[3];
		pev(in, pev_vuser1, fNormalIn);
		xs_vec_neg(fNormalIn, fNormalIn);
		
		new Float:fNormalOut[3];
		pev(out, pev_vuser1, fNormalOut);
		
		xs_vec_sub(fAngles, fNormalIn, fAngles);
		xs_vec_add(fAngles, fNormalOut, fAngles);
		
		//fAngles[2] = -fAngles[2];
		
		vector_to_angle(fAngles, fAngles);
		
		set_pev(id, pev_angles, fAngles);
		set_pev(id, pev_fixangle, 1);
		
		
		pev(id, pev_velocity, fAngles);
		new Float:fSpeed = vector_length(fAngles);
		xs_vec_normalize(fAngles,  fAngles);
		
		xs_vec_sub(fAngles, fNormalIn, fAngles);
		xs_vec_add(fAngles, fNormalOut, fAngles);
		
		xs_vec_normalize(fAngles, fAngles);
		xs_vec_mul_scalar(fAngles, fSpeed, fAngles);
		set_pev(id, pev_velocity, fAngles);
	}

bool:checkPlace(Float:fOrigin[3],iMode,id){
		new ent = -1;
		new szClass[64]
		while((ent = find_ent_in_sphere(ent,fOrigin,45.0))){
			pev(ent,pev_classname,szClass,charsmax(szClass));
			if(equal(szClass,szClassTelNieb) || equal(szClass,szClassTelPom)){
				if(iMode == 0 && equal(szClass,szClassTelNieb) && pev(ent,pev_owner) == id){
					continue;
				}
				else if(iMode == 1 && equal(szClass,szClassTelPom) && pev(ent,pev_owner) == id){
					continue;
				}
				else{
					return false;
				}
			}
		}
		return true;
	}

	public cvar_register(){
		#if defined SPRITES
		pCvars[SpriteType] = register_cvar("portal_sprite","1")
		#endif
		pCvars[FallDamge] = register_cvar("portal_fall_damage","1")
		pCvars[SpeedBullet] = register_cvar("portal_bullet_speed","1500")
		pCvars[PortalCost] = register_cvar("portal_cost","-1")
		pCvars[SpawnPortal] = register_cvar("portal_spawn","0")
	}

bool:checkPortalPlace(Float: fOrigin[3],Float: fMins[3],Float: fMaxs[3]){
		new Float:fOriginTmp[3]
		
		xs_vec_copy(fOrigin,fOriginTmp)
		
		
		fOriginTmp[0] += fMins[0];
		fOriginTmp[1] += fMaxs[1];
		fOriginTmp[2] += fMaxs[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		
		fOriginTmp[0] += fMaxs[0];
		fOriginTmp[1] += fMaxs[1];
		fOriginTmp[2] += fMaxs[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		
		fOriginTmp[0] += fMins[0];
		fOriginTmp[1] += fMins[1];
		fOriginTmp[2] += fMaxs[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		fOriginTmp[0] += fMaxs[0];
		fOriginTmp[1] += fMins[1];
		fOriginTmp[2] += fMaxs[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		fOriginTmp[0] += fMins[0];
		fOriginTmp[1] += fMaxs[1];
		fOriginTmp[2] += fMins[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		fOriginTmp[0] += fMaxs[0];
		fOriginTmp[1] += fMaxs[1];
		fOriginTmp[2] += fMins[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		fOriginTmp[0] += fMins[0];
		fOriginTmp[1] += fMins[1];
		fOriginTmp[2] += fMins[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		fOriginTmp[0] += fMaxs[0];
		fOriginTmp[1] += fMins[1];
		fOriginTmp[2] += fMins[2];
		if(!traceTo(fOrigin,fOriginTmp)){
			return false;
		}
		xs_vec_copy(fOrigin,fOriginTmp)
		
		return true;
	}

bool:traceTo(const Float:fFrom[3],const Float:fTo[3]){
		new tr = create_tr2();
		
		engfunc(EngFunc_TraceLine, fFrom, fTo,0, 0, tr);
		
		new Float:fFrac;
		get_tr2(tr, TR_flFraction, fFrac);
		free_tr2(tr);
		
		return (fFrac == 1.0) 
		
	}

#if defined TEST
	Create_Line(const Float:start[3], const Float:stop[3], Float:go=10.0, r=0,g=0,b=255)
	{
		new Float:fStart[3], Float:fStop[3];
		new Float:fVec[3];
		xs_vec_sub(start, stop, fVec);
		xs_vec_normalize(fVec, fVec);

		xs_vec_mul_scalar(fVec, go, fVec);

		xs_vec_add(stop, fVec, fStop);
		xs_vec_sub(start, fVec, fStart);


		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(0)
		engfunc(EngFunc_WriteCoord, fStart[0])
		engfunc(EngFunc_WriteCoord,fStart[1])
		engfunc(EngFunc_WriteCoord,fStart[2])

		engfunc(EngFunc_WriteCoord,fStop[0])
		engfunc(EngFunc_WriteCoord,fStop[1])
		engfunc(EngFunc_WriteCoord,fStop[2])
		write_short(sprite)
		write_byte(1)
		write_byte(5)
		write_byte(1)//life
		write_byte(10)
		write_byte(0)
		write_byte(r)	// RED
		write_byte(g)	// GREEN
		write_byte(b)	// BLUE					
		write_byte(250)	// brightness
		write_byte(5)
		message_end()
	}
#endif
	/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/