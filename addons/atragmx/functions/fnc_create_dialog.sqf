#include "script_component.hpp"

if (dialog) exitWith { false };
if (underwater ACE_player) exitWith { false };
if (!("ACE_ATragMX" in (uniformItems ACE_player)) && !("ACE_ATragMX" in (vestItems ACE_player))) exitWith { false };

execVM QUOTE(PATHTOF(functions\fnc_update_target_selection.sqf));

createDialog 'ATragMX_Display';

true execVM QUOTE(PATHTOF(functions\fnc_show_main_page.sqf));

false execVM QUOTE(PATHTOF(functions\fnc_show_add_new_gun.sqf));
false execVM QUOTE(PATHTOF(functions\fnc_show_gun_list.sqf));
false execVM QUOTE(PATHTOF(functions\fnc_show_range_card.sqf));
false execVM QUOTE(PATHTOF(functions\fnc_show_range_card_setup.sqf));
false execVM QUOTE(PATHTOF(functions\fnc_show_target_range_assist.sqf));
false execVM QUOTE(PATHTOF(functions\fnc_show_target_speed_assist.sqf));
false execVM QUOTE(PATHTOF(functions\fnc_show_target_speed_assist_timer.sqf));

{
    lbAdd [6000, _x select 0];
} forEach GVAR(gunList);

true
