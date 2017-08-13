#include <amxmodx>
#include <fakemeta>
#include <sqlx>
#include <cod>

#define PLUGIN "CoD Skins"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define TASK_LOAD 3045

enum _:playerInfo { NAME[32], ACTIVE[CSW_P90 + 1] };
enum _:skinsInfo { SKIN_NAME[64], SKIN_WEAPON[32], SKIN_MODEL[64], SKIN_PRICE };

new const commandSkins[][] = { "skiny", "say /skins", "say_team /skins", "say /skin", "say_team /skin", "say /skiny", "say_team /skiny", "say /modele", "say_team /modele", "say /model", "say_team /model" };

new playerData[MAX_PLAYERS + 1][playerInfo], Array:playerSkins[MAX_PLAYERS + 1], Array:skins, Array:weapons, Handle:sql, loaded;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof commandSkins; i++) register_clcmd(commandSkins[i], "skins_menu");
}

public plugin_precache() 
{
	skins = ArrayCreate(skinsInfo);
	weapons = ArrayCreate(64, 16);
	
	new file[128];
	
	get_localinfo("amxx_configsdir", file, charsmax(file));
	format(file, charsmax(file), "%s/cod_skins.ini", file);
	
	if(!file_exists(file)) set_fail_state("[CoD] Brak pliku cod_skins.ini!");
	
	new skin[skinsInfo], lineData[256], tempValue[3][64], bool:error, fileOpen = fopen(file, "r");
	
	while(!feof(fileOpen))
	{
		fgets(fileOpen, lineData, charsmax(lineData)); trim(lineData);
		
		if(lineData[0] == ';' || lineData[0] == '^0' || lineData[0] == '/') continue;
		
		if(lineData[0] == '[') 
		{
			parse(lineData, skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]));
			
			replace_all(skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), "[", "");
			replace_all(skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), "]", "");

			ArrayPushString(weapons, skin[SKIN_WEAPON]);
			
			continue;
		}
		else 
		{
			parse(lineData, tempValue[0], charsmax(tempValue[]), tempValue[1], charsmax(tempValue[]), tempValue[2], charsmax(tempValue[]));

			formatex(skin[SKIN_NAME], charsmax(skin[SKIN_NAME]), tempValue[0]);
			formatex(skin[SKIN_MODEL], charsmax(skin[SKIN_MODEL]), tempValue[1]);

			skin[SKIN_PRICE] = str_to_num(tempValue[2]);

			if(!file_exists(skin[SKIN_MODEL]))
			{
				log_to_file("cod_mod.log", "[CoD] Plik %s nie istnieje!", skin[SKIN_MODEL]);
			
				error = true;
			}
			else precache_model(skin[SKIN_MODEL]);

			ArrayPushArray(skins, skin);
		}
	}
	
	fclose(fileOpen);
	
	if(error) set_fail_state("[CoD] Nie zaladowano wszystkich skinow. Sprawdz logi bledow!");
	
	if(!ArraySize(skins)) set_fail_state("[CoD] Nie zaladowano zadnego skina. Sprawdz plik konfiguracyjny cod_skins.ini!");
	
	for(new i = 1; i <= MAX_PLAYERS; i++) playerSkins[i] = ArrayCreate();
}

public plugin_cfg()
{
	new host[32], user[32], pass[32], db[32], queryData[192], error[128], errorNum;
	
	get_cvar_string("cod_sql_host", host, charsmax(host));
	get_cvar_string("cod_sql_user", user, charsmax(user));
	get_cvar_string("cod_sql_pass", pass, charsmax(pass));
	get_cvar_string("cod_sql_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("cod_mod.log", "Error: %s", error);
		
		return;
	}
	
	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_skins` (name VARCHAR(35), weapon VARCHAR(35), skin VARCHAR(64), PRIMARY KEY(name, weapon, skin))");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);
	
	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

public plugin_end()
{
	SQL_FreeHandle(sql);
	
	ArrayDestroy(skins);
	
	for(new i = 1; i <= MAX_PLAYERS; i++) ArrayDestroy(playerSkins[i]);
}

public client_disconnected(id)
	remove_task(id + TASK_LOAD);

public client_putinserver(id)
{
	rem_bit(id, loaded);
	
	for(new i = 1; i < CSW_P90 + 1; i++) playerData[id][i] = -1;

	ArrayClear(playerSkins[id]);

	if(is_user_hltv(id) || is_user_bot(id)) return;
	
	get_user_name(id, playerData[id][NAME], charsmax(playerData[][NAME]));
	
	mysql_escape_string(playerData[id][NAME], playerData[id][NAME], charsmax(playerData[][NAME]));
	
	load_skins(id);
}

public skins_menu(id)
{
	if(!cod_check_account(id)) return PLUGIN_HANDLED;

	if(!get_bit(id, loaded))
	{
		cod_print_chat(id, "Trwa ladowanie twoich skinow...");

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new menu = menu_create("\yMenu \rSkinow\w:", "skins_menu_handle");
		
	menu_additem(menu, "\wUstaw \ySkin");
	menu_additem(menu, "\wKup \ySkin");
	
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public skins_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	choose_weapon_menu(id, item);

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public choose_weapon_menu(id, type)
{
	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new menuData[32], tempType[2], menu = menu_create("\yWybierz \rBron\w:", "choose_weapon_menu_handle");

	num_to_str(type, tempType, charsmax(tempType));

	for(new i = 0; i < ArraySize(weapons); i++)
	{
		ArrayGetString(weapons, i, menuData, charsmax(menuData));

		menu_additem(menu, menuData, tempType);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public choose_weapon_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new itemData[32], itemType[2], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemType, charsmax(itemType), itemData, charsmax(itemData), itemCallback);

	switch(str_to_num(itemType))
	{
		case 0: set_weapon_skin(id, itemData);
		case 1: buy_weapon_skin(id, itemData);
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public set_weapon_skin(id, weapon[])
{
	new menuData[32], skin[skinsInfo], tempId[5], count, menu = menu_create("\yWybierz \rSkin\w:", "set_weapon_skin_handle");

	menu_additem(menu, "Domyslny", weapon);

	for(new i = 0; i < ArraySize(playerSkins[id]); i++)
	{
		ArrayGetArray(skins, ArrayGetCell(playerSkins[id], i), skin);

		if(equal(weapon, skin[SKIN_WEAPON]))
		{
			num_to_str(ArrayGetCell(playerSkins[id], i), tempId, charsmax(tempId));

			formatex(menuData, charsmax(menuData), skin[SKIN_NAME]);

			menu_additem(menu, menuData, tempId);

			count++;
		}
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	if(!count)
	{
		cod_print_chat(id, "Nie posiadasz^x03 zadnych^x01 skinow tej broni.");

		menu_destroy(menu);
	}
	else menu_display(id, menu);
}

public set_weapon_skin_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new queryData[256], itemData[32], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	menu_destroy(menu);

	new skin[skinsInfo], skinId = str_to_num(itemData);

	ArrayGetArray(skins, skinId, skin);

	if(!skinId && strlen(itemData) > 3) formatex(queryData, charsmax(queryData), "DELETE FROM `cod_skins` WHERE name = '%s' AND weapon = '%s ACTIVE'", playerData[id][NAME], itemData);
	else formatex(queryData, charsmax(queryData), "DELETE FROM `cod_skins` WHERE name = '%s' AND weapon = '%s ACTIVE'", playerData[id][NAME], skin[SKIN_WEAPON]);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if(item)
	{
		add_skin(id, skin[SKIN_WEAPON], skin[SKIN_NAME], 1);

		set_skin(id, skin[SKIN_WEAPON], skinId);

		cod_print_chat(id, "Twoj nowy skin^x03 %s^x01 to^x03 %s^x01.", skin[SKIN_WEAPON], skin[SKIN_NAME]);
	}
	else 
	{
		set_skin(id, itemData, -1);

		cod_print_chat(id, "Przywrociles domyslny skin broni^x03 %s^x01.", itemData);
	}
	
	return PLUGIN_HANDLED;
}

public buy_weapon_skin(id, weapon[])
{
	new menuData[64], skin[skinsInfo], tempId[5], count, menu = menu_create("\yWybierz \rSkin\w:", "buy_weapon_skin_handle");

	for(new i = 0; i < ArraySize(skins); i++)
	{
		ArrayGetArray(skins, i, skin);

		if(equal(weapon, skin[SKIN_WEAPON]))
		{
			num_to_str(i, tempId, charsmax(tempId));

			formatex(menuData, charsmax(menuData), "\y%s \w- \r%i Honoru", skin[SKIN_NAME], skin[SKIN_PRICE])

			menu_additem(menu, menuData, tempId);

			count++;
		}
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	
	if(!count)
	{
		cod_print_chat(id, "Do kupienia nie ma^x03 zadnych^x01 skinow tej broni.");

		menu_destroy(menu);
	}
	else menu_display(id, menu);
}

public buy_weapon_skin_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new itemData[32], itemAccess, itemCallback, skinId;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	skinId = str_to_num(itemData);

	menu_destroy(menu);

	for(new i = 0; i < ArraySize(playerSkins[id]); i++)
	{
		if(ArrayGetCell(playerSkins[id], i) == skinId)
		{
			cod_print_chat(id, "Juz posiadasz tego skina!");

			return PLUGIN_HANDLED;
		}
	}

	new skin[skinsInfo];

	ArrayGetArray(skins, skinId, skin);

	if(cod_get_user_honor(id) < skin[SKIN_PRICE])
	{
		cod_print_chat(id, "Nie masz wystarczajacej ilosci^x03 honoru^x01.");

		return PLUGIN_HANDLED;
	}

	add_skin(id, skin[SKIN_WEAPON], skin[SKIN_NAME]);

	ArrayPushCell(playerSkins[id], skinId);

	cod_print_chat(id, "Pomyslnie zakupiles skin^x03 %s^x01 do broni^x03 %s^x01.", skin[SKIN_NAME], skin[SKIN_WEAPON]);

	return PLUGIN_HANDLED;
}

public cod_weapon_deploy(id, weapon, ent)
{
	if(weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_C4) return;

	if(playerData[id][weapon] > -1)
	{
		static skin[skinsInfo];
		
		ArrayGetArray(skins, playerData[id][weapon], skin);
		
		set_pev(id, pev_viewmodel2, skin[SKIN_MODEL]);
	}
}

public load_skins(id)
{
	new playerId[1], queryData[128];
	
	playerId[0] = id;
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_skins` WHERE name = '%s'", playerData[id][NAME]);
	
	SQL_ThreadQuery(sql, "load_skins_handle", queryData, playerId, sizeof(playerId));
}

public load_skins_handle(failState, Handle:query, error[], errorNum, playerId[], dataSize)
{
	if(failState) 
	{
		log_to_file("cod_mod.log", "SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = playerId[0], skin[skinsInfo];
	
	while(SQL_MoreResults(query))
	{
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "skin"), skin[SKIN_NAME], charsmax(skin[SKIN_NAME]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "weapon"), skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]));

		if(contain(skin[SKIN_WEAPON], "ACTIVE") != -1)
		{
			replace(skin[SKIN_WEAPON], charsmax(skin[SKIN_WEAPON]), " ACTIVE", "");

			set_skin(id, skin[SKIN_WEAPON], get_skin_id(skin[SKIN_NAME], skin[SKIN_WEAPON]));
		}
		else
		{
			new skinId = get_skin_id(skin[SKIN_NAME], skin[SKIN_WEAPON]);

			if(skinId > -1) ArrayPushCell(playerSkins[id], skinId);
		}

		SQL_NextRow(query);
	}
	
	set_bit(id, loaded);
}

stock get_weapon_id(weapon[])
{
	static weaponName[32];

	formatex(weaponName, charsmax(weaponName), "weapon_%s", weapon);

	strtolower(weaponName);

	return get_weaponid(weaponName);
}

stock add_skin(id, weapon[], name[], active = 0)
{
	new queryData[192];

	formatex(queryData, charsmax(queryData), "INSERT INTO `cod_skins` (`name`, `weapon`, `skin`) VALUES ('%s', '%s%s', '%s')", playerData[id][NAME], weapon, active ? " ACTIVE" : "", name);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock set_skin(id, weapon[], skin)
{
	if(skin >= ArraySize(skins)) return;

	playerData[id][get_weapon_id(weapon)] = skin;
}

stock get_skin_id(const name[], const weapon[])
{
	new skin[skinsInfo];

	for(new i = 0; i < ArraySize(skins); i++)
	{
		ArrayGetArray(skins, i, skin);

		if(equal(name, skin[SKIN_NAME]) && equal(weapon, skin[SKIN_WEAPON])) return i;
	}

	return -1;
}

stock get_skin_info(skinId, info, dataReturn[] = "", dataLength = 0)
{
	static skin[skinsInfo];
	
	ArrayGetArray(skins, skinId, skin);
	
	if(info == SKIN_NAME || info == SKIN_WEAPON || info == SKIN_MODEL)
	{
		copy(dataReturn, dataLength, skin[info]);
		
		return 0;
	}
	
	return skin[info];
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if(failState) 
	{
		if(failState == TQUERY_CONNECT_FAILED) log_to_file("cod_mod.log", "Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("cod_mod.log", "Query failed. [%d] %s", errorNum, error);
	}
	
	return PLUGIN_CONTINUE;
}