#include <amxmodx>
#include <cod>

#define PLUGIN "CoD Class Saper"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new const name[] = "Saper";
new const description[] = "Ma 2 miny i nieco zmniejszona grawitacje. Jest mniej widoczny z P90.";
new const fraction[] = "";
new const weapons = (1<<CSW_P90)|(1<<CSW_FIVESEVEN);
new const health = 10;
new const intelligence = 0;
new const strength = 10;
new const stamina = 10;
new const condition = 20;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cod_register_class(name, description, fraction, weapons, health, intelligence, strength, stamina, condition);
}

public cod_class_enabled(id, promotion)
{
	cod_set_user_mines(id, 2);

	cod_set_user_render(id, CLASS, 140, RENDER_ALWAYS, CSW_P90);

	cod_set_user_gravity(id, CLASS, -0.25);
}
	
public cod_class_spawned(id)
	cod_add_user_mines(id, 2);

public cod_class_skill_used(id)
	cod_use_user_mine(id);
