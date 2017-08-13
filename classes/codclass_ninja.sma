#include <amxmodx>
#include <cod>

#define PLUGIN "CoD Class Skrytobojca"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

new const name[] = "Skrytobojca";
new const description[] = "Po uzyciu mocy klasy jest niewidzialny przez 15s. Ma podwojny skok i 1/2 na zabicie z noza (PPM).";
new const fraction[] = "";
new const weapons = (1<<CSW_DEAGLE)|(1<<CSW_UMP45);
new const health = -10;
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
	cod_set_user_multijumps(id, 1);

public cod_class_spawned(id)
	cod_add_user_multijumps(id, 1);

public cod_class_skill_used(id)
	cod_set_user_render(id, 0, CLASS, RENDER_ALWAYS, 0, 15.0);

public cod_class_damage_attacker(attacker, victim, weapon, &Float:damage, damageBits)
{
	if(weapon == CSW_M249)
	{
		new ammo, weapon = get_user_weapon(id, ammo, _);

		cod_inflict_damage(attacker, victim, (100 - ammo) * 0.2, 0.0, damageBits)
	}
}
