/*
	This file is part of TF2 Sandbox.
	
	TF2 Sandbox is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TF2 Sandbox is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TF2 Sandbox.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <build>
#include <build_stocks>
#include <tf2>
#include <tf2_stocks>

//#pragma newdecls required

new MoveType:g_mtGrabMoveType[MAXPLAYERS];
new g_iGrabTarget[MAXPLAYERS];
new Float:g_vGrabPlayerOrigin[MAXPLAYERS][3];
new bool:g_bGrabIsRunning[MAXPLAYERS];
new bool:g_bGrabFreeze[MAXPLAYERS];

new Handle:g_hMenuCredits;
new Handle:g_hMenuCredits2;


new Handle:g_hCookieSDoorTarget;
new Handle:g_hCookieSDoorModel;

new Handle:g_hPropNameArray;
new Handle:g_hPropModelPathArray;
new Handle:g_hPropTypeArray;
new Handle:g_hPropStringArray;
new String:g_szFile[128];

new String:g_szConnectedClient[32][MAXPLAYERS];
//new String:g_szDisconnectClient[32][MAXPLAYERS];
new g_iTempOwner[MAX_HOOK_ENTITIES] =  { -1, ... };

new Float:g_fDelRangePoint1[MAXPLAYERS][3];
new Float:g_fDelRangePoint2[MAXPLAYERS][3];
new Float:g_fDelRangePoint3[MAXPLAYERS][3];
new String:g_szDelRangeStatus[MAXPLAYERS][8];
new bool:g_szDelRangeCancel[MAXPLAYERS] =  { false, ... };

new ColorBlue[4] =  {
	50, 
	50, 
	255, 
	255 };

new ColorWhite[4] =  {
	255, 
	255, 
	255, 
	255 };
new ColorRed[4] =  {
	255, 
	50, 
	50, 
	255 };
new ColorGreen[4] =  {
	50, 
	255, 
	50, 
	255 };

#define EFL_NO_PHYSCANNON_INTERACTION (1<<30)

new g_Halo;
new g_PBeam;

new bool:g_bBuffer[MAXPLAYERS + 1];

new g_iCopyTarget[MAXPLAYERS];
new Float:g_fCopyPlayerOrigin[MAXPLAYERS][3];
new bool:g_bCopyIsRunning[MAXPLAYERS] = false;

new g_Beam;

new Handle:g_hMainMenu = INVALID_HANDLE;
new Handle:g_hPropMenu = INVALID_HANDLE;
new Handle:g_hEquipMenu = INVALID_HANDLE;
new Handle:g_hPlayerStuff = INVALID_HANDLE;
new Handle:g_hCondMenu = INVALID_HANDLE;
new Handle:g_hRemoveMenu = INVALID_HANDLE;
new Handle:g_hBuildHelperMenu = INVALID_HANDLE;
new Handle:g_hPropMenuComic = INVALID_HANDLE;
new Handle:g_hPropMenuConstructions = INVALID_HANDLE;
new Handle:g_hPropMenuWeapons = INVALID_HANDLE;
new Handle:g_hPropMenuPickup = INVALID_HANDLE;
new Handle:g_hPropMenuHL2 = INVALID_HANDLE;

/*new String:g_szFile[128];
new Handle:g_hPropNameArray;
new Handle:g_hPropModelPathArray;
new Handle:g_hPropTypeArray;
new Handle:g_hPropStringArray;*/

new String:CopyableProps[][] =  {
	"prop_dynamic", 
	"prop_dynamic_override", 
	"prop_physics", 
	"prop_physics_multiplayer", 
	"prop_physics_override", 
	"prop_physics_respawnable", 
	"prop_ragdoll", 
	"func_physbox", 
	"player"
};

new String:EntityType[][] =  {
	"player", 
	"func_physbox", 
	"prop_door_rotating", 
	"prop_dynamic", 
	"prop_dynamic_ornament", 
	"prop_dynamic_override", 
	"prop_physics", 
	"prop_physics_multiplayer", 
	"prop_physics_override", 
	"prop_physics_respawnable", 
	"prop_ragdoll", 
	"item_ammo_357", 
	"item_ammo_357_large", 
	"item_ammo_ar2", 
	"item_ammo_ar2_altfire", 
	"item_ammo_ar2_large", 
	"item_ammo_crate", 
	"item_ammo_crossbow", 
	"item_ammo_pistol", 
	"item_ammo_pistol_large", 
	"item_ammo_smg1", 
	"item_ammo_smg1_grenade", 
	"item_ammo_smg1_large", 
	"item_battery", 
	"item_box_buckshot", 
	"item_dynamic_resupply", 
	"item_healthcharger", 
	"item_healthkit", 
	"item_healthvial", 
	"item_item_crate", 
	"item_rpg_round", 
	"item_suit", 
	"item_suitcharger", 
	"weapon_357", 
	"weapon_alyxgun", 
	"weapon_ar2", 
	"weapon_bugbait", 
	"weapon_crossbow", 
	"weapon_crowbar", 
	"weapon_frag", 
	"weapon_physcannon", 
	"weapon_pistol", 
	"weapon_rpg", 
	"weapon_shotgun", 
	"weapon_smg1", 
	"weapon_stunstick", 
	"weapon_slam", 
	"tf_viewmodel", 
	"tf_", 
	"gib"
};

new String:DelClass[][] =  {
	"npc_", 
	"Npc_", 
	"NPC_", 
	"prop_", 
	"Prop_", 
	"PROP_", 
	"func_", 
	"Func_", 
	"FUNC_", 
	"item_", 
	"Item_", 
	"ITEM_", 
	"gib"
};

enum PropTypeCheck {
	
	PROP_NONE = 0, 
	PROP_RIGID = 1, 
	PROP_PHYSBOX = 2, 
	PROP_WEAPON = 3, 
	PROP_TF2OBJ = 4,  //tf2 buildings
	PROP_RAGDOLL = 5, 
	PROP_TF2PROJ = 6,  //tf2 projectiles
	PROP_PLAYER = 7
	
};

public Plugin:myinfo =  {
	name = "TF2SB Lite",
	author = "Yuuki, LeadKiller, Danct12, DaRkWoRlD, greenteaf0718, hjkwe654",
	description = "Everything in one module, isn't that cool?",
	version = BUILDMOD_VER,
	url = "https://github.com/NickrepoliYT/tf2sb"
};

public OnPluginStart() {
	// Basic Spawn Commands
	RegAdminCmd("sm_spawnprop", Command_SpawnProp, 0, "Spawn a prop in command list!");
	RegAdminCmd("sm_prop", Command_SpawnProp, 0, "Spawn props in command list, too!");
	
	// More building useful stuffs
	RegAdminCmd("sm_skin", Command_Skin, 0, "Color a prop.");
	
	// Coloring Props and more
	RegAdminCmd("sm_color", Command_Color, 0, "Color a prop.");
	RegAdminCmd("sm_render", Command_Render, 0, "Render an entity.");
	
	// Rotating stuffs
	RegAdminCmd("sm_rotate", Command_Rotate, 0, "Rotate an entity.");
	RegAdminCmd("sm_r", Command_Rotate, 0, "Rotate an entity.");
	RegAdminCmd("sm_accuraterotate", Command_AccurateRotate, 0, "Accurate rotate a prop.");
	RegAdminCmd("sm_ar", Command_AccurateRotate, 0, "Accurate rotate a prop.");
	RegAdminCmd("sm_move", Command_Move, 0, "Move a prop to a position.");
	
	// Misc stuffs
	RegAdminCmd("sm_sdoor", Command_SpawnDoor, 0, "Doors creator.");
	RegAdminCmd("sm_ld", Command_LightDynamic, 0, "Dynamic Light.");
	RegAdminCmd("sm_fly", Command_Fly, 0, "I BELIEVE I CAN FLYYYYYYY, I BELIEVE THAT I CAN TOUCH DE SKY");
	RegAdminCmd("sm_setname", Command_SetName, 0, "SetPropname");
	RegAdminCmd("sm_simplelight", Command_SimpleLight, 0, "Spawn a Light, in a very simple way.");
	RegAdminCmd("sm_propdoor", Command_OpenableDoorProp, 0, "Making a door, in prop_door way.");
	RegAdminCmd("sm_propscale", Command_PropScale, ADMFLAG_SLAY, "Resizing a prop");
	
	// HL2 Props
	g_hPropMenuHL2 = CreateMenu(PropMenuHL2);
	SetMenuTitle(g_hPropMenuHL2, "TF2SB - HL2 Props and Miscs\nSay /g in chat to move Entities!");
	SetMenuExitBackButton(g_hPropMenuHL2, true);
	AddMenuItem(g_hPropMenuHL2, "removeprops", "|Remove");
	
	g_hCookieSDoorTarget = RegClientCookie("cookie_SDoorTarget", "For SDoor.", CookieAccess_Private);
	g_hCookieSDoorModel = RegClientCookie("cookie_SDoorModel", "For SDoor.", CookieAccess_Private);
	g_hPropNameArray = CreateArray(33, 2048); // Max Prop List is 1024-->2048
	g_hPropModelPathArray = CreateArray(128, 2048); // Max Prop List is 1024-->2048
	g_hPropTypeArray = CreateArray(33, 2048); // Max Prop List is 1024-->2048
	g_hPropStringArray = CreateArray(256, 2048);
	
	ReadProps();
	
	// Grab
	RegAdminCmd("+grab", Command_EnableGrab, 0, "Grab props.");
	RegAdminCmd("-grab", Command_DisableGrab, 0, "Grab props.");
	
	// Messages
	LoadTranslations("common.phrases");
	
	// Remover
	RegAdminCmd("sm_delall", Command_DeleteAll, 0, "Delete all of your spawned entitys.");
	RegAdminCmd("sm_del", Command_Delete, 0, "Delete an entity.");
	
	HookEntityOutput("prop_physics_respawnable", "OnBreak", OnPropBreak);
	
	// Buildings Belong To Us
	HookEvent("player_builtobject", Event_player_builtobject);
	
	// Simple Menu
	g_hMainMenu = CreateMenu(MainMenu);
	SetMenuTitle(g_hMainMenu, "TF2SB - Spawnlist v2");
	AddMenuItem(g_hMainMenu, "spawnlist", "Spawn...");
	AddMenuItem(g_hMainMenu, "equipmenu", "Equip...");
	AddMenuItem(g_hMainMenu, "playerstuff", "Player...");
	AddMenuItem(g_hMainMenu, "buildhelper", "Build Helper...");
	
	// Player Stuff for now
	g_hPlayerStuff = CreateMenu(PlayerStuff);
	SetMenuTitle(g_hPlayerStuff, "TF2SB - Player...");
	AddMenuItem(g_hPlayerStuff, "cond", "Conditions...");
	AddMenuItem(g_hPlayerStuff, "sizes", "Sizes...");
	AddMenuItem(g_hPlayerStuff, "health", "Health");
	AddMenuItem(g_hPlayerStuff, "speed", "Speed");
	AddMenuItem(g_hPlayerStuff, "model", "Model");
	AddMenuItem(g_hPlayerStuff, "pitch", "Pitch");
	SetMenuExitBackButton(g_hPlayerStuff, true);
	
	// Init thing for commands!
	RegAdminCmd("sm_sandbox", Command_BuildMenu, 0);
	RegAdminCmd("sm_resupply", Command_Resupply, 0);
	
	// Build Helper (placeholder)
	g_hBuildHelperMenu = CreateMenu(BuildHelperMenu);
	SetMenuTitle(g_hBuildHelperMenu, "TF2SB - Build Helper\nThis was actually a placeholder because we can't figure out how to make a toolgun");
	
	AddMenuItem(g_hBuildHelperMenu, "delprop", "Delete Prop");
	AddMenuItem(g_hBuildHelperMenu, "colors", "Color (see chat)");
	AddMenuItem(g_hBuildHelperMenu, "effects", "Effects (see chat)");
	AddMenuItem(g_hBuildHelperMenu, "skin", "Skin (see chat)");
	AddMenuItem(g_hBuildHelperMenu, "rotate", "Rotate (see chat)");
	AddMenuItem(g_hBuildHelperMenu, "accuraterotate", "Accurate Rotate (see chat)");
	AddMenuItem(g_hBuildHelperMenu, "doors", "Doors (see chat)");
	AddMenuItem(g_hBuildHelperMenu, "lights", "Lights");
	SetMenuExitBackButton(g_hBuildHelperMenu, true);
	
	// Remove Command
	g_hRemoveMenu = CreateMenu(RemoveMenu);
	SetMenuTitle(g_hRemoveMenu, "TF2SB - Remove");
	AddMenuItem(g_hRemoveMenu, "remove", "Remove that prop");
	AddMenuItem(g_hRemoveMenu, "delallfail", "To delete all, type !delall (there is no comeback)");
	
	SetMenuExitBackButton(g_hRemoveMenu, true);
	
	//Addcond Menu
	g_hCondMenu = CreateMenu(CondMenu);
	SetMenuTitle(g_hCondMenu, "TF2SB - Conditions...");
	AddMenuItem(g_hCondMenu, "crits", "Crits");
	AddMenuItem(g_hCondMenu, "noclip", "Noclip");
	//	AddMenuItem(g_hCondMenu, "infammo", "Inf. Ammo");
	AddMenuItem(g_hCondMenu, "speedboost", "Speed Boost");
	AddMenuItem(g_hCondMenu, "resupply", "Resupply");
	//	AddMenuItem(g_hCondMenu, "buddha", "Buddha");
	AddMenuItem(g_hCondMenu, "minicrits", "Mini-Crits");
	AddMenuItem(g_hCondMenu, "fly", "Fly");
	//	AddMenuItem(g_hCondMenu, "infclip", "Inf. Clip");
	AddMenuItem(g_hCondMenu, "damagereduce", "Damage Reduction");
	AddMenuItem(g_hCondMenu, "removeweps", "Remove Weapons");
	SetMenuExitBackButton(g_hCondMenu, true);
	
	// Equip Menu
	g_hEquipMenu = CreateMenu(EquipMenu);
	SetMenuTitle(g_hEquipMenu, "TF2SB - Equip...");
	
	AddMenuItem(g_hEquipMenu, "physgun", "Physics Gun");
	AddMenuItem(g_hEquipMenu, "toolgun", "Tool Gun");
	//	AddMenuItem(g_hEquipMenu, "portalgun", "Portal Gun");
	
	SetMenuExitBackButton(g_hEquipMenu, true);

	/* This goes for something called prop menu, i can't figure out how to make a config spawn list */
	
	// Prop Menu INIT
	g_hPropMenu = CreateMenu(PropMenu);
	SetMenuTitle(g_hPropMenu, "TF2SB - Spawn...\nSay /g in chat to move Entities!");
	SetMenuExitBackButton(g_hPropMenu, true);
	AddMenuItem(g_hPropMenu, "removeprops", "|Remove");
	AddMenuItem(g_hPropMenu, "constructprops", "Construction Props");
	AddMenuItem(g_hPropMenu, "comicprops", "Comic Props");
	AddMenuItem(g_hPropMenu, "pickupprops", "Pickup Props");
	AddMenuItem(g_hPropMenu, "weaponsprops", "Weapons Props");
	AddMenuItem(g_hPropMenu, "hl2props", "HL2 Props and Miscs");
	
	// Prop Menu Pickup
	g_hPropMenuPickup = CreateMenu(PropMenuPickup);
	SetMenuTitle(g_hPropMenuPickup, "TF2SB - Pickup Props\nSay /g in chat to move Entities!");
	SetMenuExitBackButton(g_hPropMenuPickup, true);
	AddMenuItem(g_hPropMenuPickup, "removeprops", "|Remove");
	AddMenuItem(g_hPropMenuPickup, "medkit_large", "Medkit Large");
	AddMenuItem(g_hPropMenuPickup, "medkit_large_bday", "Medkit Large Bday");
	AddMenuItem(g_hPropMenuPickup, "medkit_medium", "Medkit Medium");
	AddMenuItem(g_hPropMenuPickup, "medkit_medium_bday", "Medkit Medium Bday");
	AddMenuItem(g_hPropMenuPickup, "medkit_small", "Medkit Small");
	AddMenuItem(g_hPropMenuPickup, "medkit_small_bday", "Medkit Small Bday");
	AddMenuItem(g_hPropMenuPickup, "ammopack_large", "Ammo Pack Large");
	AddMenuItem(g_hPropMenuPickup, "ammopack_large_bday", "Ammo Pack Large Bday");
	AddMenuItem(g_hPropMenuPickup, "ammopack_medium", "Ammo Pack Medium");
	AddMenuItem(g_hPropMenuPickup, "ammopack_medium_bday", "Ammo Pack Medium Bday");
	AddMenuItem(g_hPropMenuPickup, "ammopack_small", "Ammo Pack Small");
	AddMenuItem(g_hPropMenuPickup, "ammopack_small_bday", "Ammo Pack Small Bday");
	AddMenuItem(g_hPropMenuPickup, "platesandvich", "Sandvich Plate");
	AddMenuItem(g_hPropMenuPickup, "platesteak", "Steak Plate");
	AddMenuItem(g_hPropMenuPickup, "intelbriefcase", "Briefcase");
	AddMenuItem(g_hPropMenuPickup, "tf_gift", "Gift");
	AddMenuItem(g_hPropMenuPickup, "halloween_gift", "Big Gift");
	AddMenuItem(g_hPropMenuPickup, "plate_robo_sandwich", "Sandvich Robo Plate");
	AddMenuItem(g_hPropMenuPickup, "currencypack_large", "Currency Pack Large");
	AddMenuItem(g_hPropMenuPickup, "currencypack_medium", "Currency Pack Medium");
	AddMenuItem(g_hPropMenuPickup, "currencypack_small", "Currency Pack Small");
	
	// Prop Menu Weapons
	g_hPropMenuWeapons = CreateMenu(PropMenuWeapons);
	SetMenuTitle(g_hPropMenuWeapons, "TF2SB - Weapon Props\nSay /g in chat to move Entities!");
	SetMenuExitBackButton(g_hPropMenuWeapons, true);
	AddMenuItem(g_hPropMenuWeapons, "removeprops", "|Remove");
	AddMenuItem(g_hPropMenuWeapons, "w_baseball", "Baseball");
	AddMenuItem(g_hPropMenuWeapons, "w_bat", "Bat");
	AddMenuItem(g_hPropMenuWeapons, "w_builder", "PDA Build");
	AddMenuItem(g_hPropMenuWeapons, "w_cigarette_case", "Cigarette Case");
	AddMenuItem(g_hPropMenuWeapons, "w_fireaxe", "Fire Axe");
	AddMenuItem(g_hPropMenuWeapons, "w_frontierjustice", "Frontier Justice");
	AddMenuItem(g_hPropMenuWeapons, "w_grenade_grenadelauncher", "Grenade");
	AddMenuItem(g_hPropMenuWeapons, "w_grenadelauncher", "Grenade Launcher");
	AddMenuItem(g_hPropMenuWeapons, "w_knife", "Knife");
	AddMenuItem(g_hPropMenuWeapons, "w_medigun", "Medi Gun");
	AddMenuItem(g_hPropMenuWeapons, "w_minigun", "MiniGun");
	AddMenuItem(g_hPropMenuWeapons, "w_pda_engineer", "PDA Destroy");
	AddMenuItem(g_hPropMenuWeapons, "w_pistol", "Pistol");
	AddMenuItem(g_hPropMenuWeapons, "w_revolver", "Revolver");
	AddMenuItem(g_hPropMenuWeapons, "w_rocket", "Rocket");
	AddMenuItem(g_hPropMenuWeapons, "w_rocketlauncher", "Rocket Launcher");
	AddMenuItem(g_hPropMenuWeapons, "w_sapper", "Sapper");
	AddMenuItem(g_hPropMenuWeapons, "w_scattergun", "Scatter Gun");
	AddMenuItem(g_hPropMenuWeapons, "w_shotgun", "Shotgun");
	AddMenuItem(g_hPropMenuWeapons, "w_shovel", "Shovel");
	AddMenuItem(g_hPropMenuWeapons, "w_smg", "SMG");
	AddMenuItem(g_hPropMenuWeapons, "w_sniperrifle", "Sniper Rifle");
	AddMenuItem(g_hPropMenuWeapons, "w_stickybomb_launcher", "Sticky Bomb Launcher");
	AddMenuItem(g_hPropMenuWeapons, "w_syringegun", "Syringe Gun");
	AddMenuItem(g_hPropMenuWeapons, "w_toolbox", "Toolbox");
	AddMenuItem(g_hPropMenuWeapons, "w_ttg_max_gun", "TTG Max Gun");
	AddMenuItem(g_hPropMenuWeapons, "w_wrangler", "The Wrangler");
	AddMenuItem(g_hPropMenuWeapons, "w_wrench", "Wrench");
	
	// Prop Menu Comics Prop
	g_hPropMenuComic = CreateMenu(PropMenuComics);
	SetMenuTitle(g_hPropMenuComic, "TF2SB - Comic Props\nSay /g in chat to move Entities!");
	SetMenuExitBackButton(g_hPropMenuComic, true);
	AddMenuItem(g_hPropMenuComic, "removeprops", "|Remove");
	AddMenuItem(g_hPropMenuComic, "ingot001", "Gold Ingot");
	AddMenuItem(g_hPropMenuComic, "paint_can001", "Paint Can 1");
	AddMenuItem(g_hPropMenuComic, "paint_can002", "Paint Can 2");
	AddMenuItem(g_hPropMenuComic, "painting_02", "Painting 1");
	AddMenuItem(g_hPropMenuComic, "painting_03", "Painting 2");
	AddMenuItem(g_hPropMenuComic, "painting_04", "Painting 3");
	AddMenuItem(g_hPropMenuComic, "painting_05", "Painting 4");
	AddMenuItem(g_hPropMenuComic, "painting_06", "Painting 5");
	AddMenuItem(g_hPropMenuComic, "painting_07", "Painting 6");
	AddMenuItem(g_hPropMenuComic, "target_scout", "Target Scout");
	AddMenuItem(g_hPropMenuComic, "target_soldier", "Target Soldier");
	AddMenuItem(g_hPropMenuComic, "target_pyro", "Target Pyro");
	AddMenuItem(g_hPropMenuComic, "target_demoman", "Target Demoman");
	AddMenuItem(g_hPropMenuComic, "target_heavy", "Target Heavy");
	AddMenuItem(g_hPropMenuComic, "target_engineer", "Target Engineer");
	AddMenuItem(g_hPropMenuComic, "target_medic", "Target Medic");
	AddMenuItem(g_hPropMenuComic, "target_sniper", "Target Sniper");
	AddMenuItem(g_hPropMenuComic, "target_spy", "Target Spy");
	
	// Prop Menu Constructions Prop
	g_hPropMenuConstructions = CreateMenu(PropMenuConstructions);
	SetMenuTitle(g_hPropMenuConstructions, "TF2SB - Construction Props\nSay /g in chat to move Entities!");
	SetMenuExitBackButton(g_hPropMenuConstructions, true);
	AddMenuItem(g_hPropMenuConstructions, "removeprops", "|Remove");
	AddMenuItem(g_hPropMenuConstructions, "air_intake", "Air Fan");
	AddMenuItem(g_hPropMenuConstructions, "baby_grand_01", "Grand Piano");
	AddMenuItem(g_hPropMenuConstructions, "barbell", "Barbell");
	AddMenuItem(g_hPropMenuConstructions, "barrel01", "Yellow Barrel");
	AddMenuItem(g_hPropMenuConstructions, "barrel02", "Dark Barrel");
	AddMenuItem(g_hPropMenuConstructions, "barrel03", "Yellow Barrel 2");
	AddMenuItem(g_hPropMenuConstructions, "barrel_flatbed01", "Barrel Flatbed");
	AddMenuItem(g_hPropMenuConstructions, "basketball_hoop", "Basketball Hoop");
	AddMenuItem(g_hPropMenuConstructions, "beer_keg001", "Beer Keg");
	AddMenuItem(g_hPropMenuConstructions, "bench001a", "Bench 1");
	AddMenuItem(g_hPropMenuConstructions, "bench001b", "Bench 2");
	AddMenuItem(g_hPropMenuConstructions, "bird", "Bird");
	AddMenuItem(g_hPropMenuConstructions, "bookcase_132_01", "Bookcase 1");
	AddMenuItem(g_hPropMenuConstructions, "bookcase_132_02", "Bookcase 2");
	AddMenuItem(g_hPropMenuConstructions, "bookcase_132_03", "Bookcase 3");
	AddMenuItem(g_hPropMenuConstructions, "bookpile_01", "Pile of Books");
	AddMenuItem(g_hPropMenuConstructions, "bookstand001", "Book Stand 1");
	AddMenuItem(g_hPropMenuConstructions, "bookstand002", "Book Stand 2");
	AddMenuItem(g_hPropMenuConstructions, "box_cluster01", "Cluster of Boxes");
	AddMenuItem(g_hPropMenuConstructions, "box_cluster02", "Cluster of Boxes 2");
	AddMenuItem(g_hPropMenuConstructions, "bullskull001", "Skull of a bull");
	AddMenuItem(g_hPropMenuConstructions, "campervan", "(HUN)Camper Van");
	AddMenuItem(g_hPropMenuConstructions, "cap_point_base", "Control Point");
	AddMenuItem(g_hPropMenuConstructions, "chair", "Chair");
	AddMenuItem(g_hPropMenuConstructions, "chalkboard01", "Chalk Board");
	AddMenuItem(g_hPropMenuConstructions, "chimney003", "Chimney 1");
	AddMenuItem(g_hPropMenuConstructions, "chimney005", "Chimney 2");
	AddMenuItem(g_hPropMenuConstructions, "chimney006", "Chimney 3");
	AddMenuItem(g_hPropMenuConstructions, "coffeemachine", "Coffee Machine");
	AddMenuItem(g_hPropMenuConstructions, "coffeepot", "Coffee Pot");
	AddMenuItem(g_hPropMenuConstructions, "computer_low", "Potato Computer");
	AddMenuItem(g_hPropMenuConstructions, "computer_printer", "Computer Printer");
	AddMenuItem(g_hPropMenuConstructions, "concrete_block001", "Concrete Block");
	AddMenuItem(g_hPropMenuConstructions, "concrete_pipe001", "Concrete Pipe 1");
	AddMenuItem(g_hPropMenuConstructions, "concrete_pipe002", "Concrete Pipe 2");
	AddMenuItem(g_hPropMenuConstructions, "control_room_console01", "Control Room Console 1");
	AddMenuItem(g_hPropMenuConstructions, "control_room_console02", "Control Room Console 2");
	AddMenuItem(g_hPropMenuConstructions, "control_room_console03", "Control Room Console 3");
	AddMenuItem(g_hPropMenuConstructions, "control_room_console04", "Control Room Console 4");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal001", "Corrugated Metal 1");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal002", "Corrugated Metal 2");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal003", "Corrugated Metal 3");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal004", "Corrugated Metal 4");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal005", "Corrugated Metal 5");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal006", "Corrugated Metal 6");
	AddMenuItem(g_hPropMenuConstructions, "corrugated_metal007", "Corrugated Metal 7");
	AddMenuItem(g_hPropMenuConstructions, "couch_01", "Couch");
	AddMenuItem(g_hPropMenuConstructions, "crane_platform001", "Crane Platform");
	AddMenuItem(g_hPropMenuConstructions, "crane_platform001b", "Crane Platform 2");
	AddMenuItem(g_hPropMenuConstructions, "drain_pipe001", "Drain Pipe");
	AddMenuItem(g_hPropMenuConstructions, "dumptruck", "Dump Truck");
	AddMenuItem(g_hPropMenuConstructions, "dumptruck_empty", "Dump Truck (Empty)");
	AddMenuItem(g_hPropMenuConstructions, "fire_extinguisher", "Fire Extinguisher");
	AddMenuItem(g_hPropMenuConstructions, "fire_extinguisher_cabinet01", "Fire Extinguisher Cabinet");
	AddMenuItem(g_hPropMenuConstructions, "groundlight001", "Ground Light 1");
	AddMenuItem(g_hPropMenuConstructions, "groundlight002", "Ground Light 2");
	AddMenuItem(g_hPropMenuConstructions, "hardhat001", "Hard Hat");
	AddMenuItem(g_hPropMenuConstructions, "haybale", "Haybale");
	AddMenuItem(g_hPropMenuConstructions, "horseshoe001", "Horse Shoe)");
	AddMenuItem(g_hPropMenuConstructions, "hose001", "Hose");
	AddMenuItem(g_hPropMenuConstructions, "hubcap", "Hubcap");
	AddMenuItem(g_hPropMenuConstructions, "keg_large", "Large Keg");
	AddMenuItem(g_hPropMenuConstructions, "kitchen_shelf", "Kitchen Shelf");
	AddMenuItem(g_hPropMenuConstructions, "kitchen_stove", "Kitchen Stove");
	AddMenuItem(g_hPropMenuConstructions, "ladder001", "Ladder");
	AddMenuItem(g_hPropMenuConstructions, "lantern001", "Lantern (on)");
	AddMenuItem(g_hPropMenuConstructions, "lantern001_off", "Lantern (off)");
	AddMenuItem(g_hPropMenuConstructions, "locker001", "Locker");
	AddMenuItem(g_hPropMenuConstructions, "lunchbag", "Lunchbag");
	AddMenuItem(g_hPropMenuConstructions, "metalbucket001", "Metal Bucket");
	AddMenuItem(g_hPropMenuConstructions, "milk_crate", "Crate of Milk");
	AddMenuItem(g_hPropMenuConstructions, "milkjug001", "Milk Jug");
	AddMenuItem(g_hPropMenuConstructions, "miningcrate001", "Mining Crate 1");
	AddMenuItem(g_hPropMenuConstructions, "miningcrate002", "Mining Crate 2");
	AddMenuItem(g_hPropMenuConstructions, "mop_and_bucket", "Mop and Bucket");
	AddMenuItem(g_hPropMenuConstructions, "mvm_museum_case", "Museum Case");
	AddMenuItem(g_hPropMenuConstructions, "oilcan01", "Oilcan 1");
	AddMenuItem(g_hPropMenuConstructions, "oilcan01b", "Oilcan 1b");
	AddMenuItem(g_hPropMenuConstructions, "oilcan02", "Oilcan 2");
	AddMenuItem(g_hPropMenuConstructions, "oildrum", "Oildrum");
	AddMenuItem(g_hPropMenuConstructions, "padlock", "Padlock");
	AddMenuItem(g_hPropMenuConstructions, "pallet001", "Wood Pallet");
	AddMenuItem(g_hPropMenuConstructions, "pick001", "Wood Pickaxe");
	AddMenuItem(g_hPropMenuConstructions, "picnic_table", "Picnic Table");
	AddMenuItem(g_hPropMenuConstructions, "pill_bottle01", "Pill Bottle");
	AddMenuItem(g_hPropMenuConstructions, "portrait_01", "Portrait Painting");
	AddMenuItem(g_hPropMenuConstructions, "propane_tank_tall01", "Propane Tank Tall");
	AddMenuItem(g_hPropMenuConstructions, "resupply_locker", "Non-working Resupply Locker");
	AddMenuItem(g_hPropMenuConstructions, "roof_metal001", "Roof Metal 1");
	AddMenuItem(g_hPropMenuConstructions, "roof_metal002", "Roof Metal 2");
	AddMenuItem(g_hPropMenuConstructions, "roof_metal003", "Roof Metal 3");
	AddMenuItem(g_hPropMenuConstructions, "roof_vent001", "Roof Vent");
	AddMenuItem(g_hPropMenuConstructions, "sack_flat", "Sack Flat");
	AddMenuItem(g_hPropMenuConstructions, "sack_stack", "Sack Stack");
	AddMenuItem(g_hPropMenuConstructions, "sack_stack_pallet", "Sack Stack's Pallet");
	AddMenuItem(g_hPropMenuConstructions, "saw_blade", "Saw Blade");
	AddMenuItem(g_hPropMenuConstructions, "saw_blade_large", "Monster Saw Blade");
	AddMenuItem(g_hPropMenuConstructions, "shelf_props01", "Shelf of Tools");
	AddMenuItem(g_hPropMenuConstructions, "sign_barricade001a", "Barricade for Signs");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01", "Battlements Sign");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01_hanging01", "Battlements Sign Hanging");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01_sm", "Battlements Sign (Small)");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01_witharrow_L_sm", "Battlements Sign (small) <-");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01_witharrow_R_sm", "Battlements Sign (small) ->");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01_witharrow_l", "Battlements Sign <-");
	AddMenuItem(g_hPropMenuConstructions, "sign_gameplay01_witharrow_r", "Battlements Sign ->");
	AddMenuItem(g_hPropMenuConstructions, "sign_wood_cap001", "Sign Wood Cap 1");
	AddMenuItem(g_hPropMenuConstructions, "sign_wood_cap002", "Sign Wood Cap 2");
	AddMenuItem(g_hPropMenuConstructions, "signpost001", "No Swimming Sign");
	AddMenuItem(g_hPropMenuConstructions, "sink001", "Sink");
	AddMenuItem(g_hPropMenuConstructions, "sniper_fence01", "Sniper Fence 1");
	AddMenuItem(g_hPropMenuConstructions, "sniper_fence02", "Sniper Fence 2");
	AddMenuItem(g_hPropMenuConstructions, "spool_rope", "Spool (rope)");
	AddMenuItem(g_hPropMenuConstructions, "spool_wire", "Spool (wire)");
	AddMenuItem(g_hPropMenuConstructions, "stairs_wood001a", "Stair Wood 1");
	AddMenuItem(g_hPropMenuConstructions, "stairs_wood001b", "Stair Wood 2");
	AddMenuItem(g_hPropMenuConstructions, "table_01", "Table 1");
	AddMenuItem(g_hPropMenuConstructions, "table_02", "Table 2");
	AddMenuItem(g_hPropMenuConstructions, "table_03", "Table 3");
	AddMenuItem(g_hPropMenuConstructions, "tank001", "Tank 1");
	AddMenuItem(g_hPropMenuConstructions, "tank002", "Tank 2");
	AddMenuItem(g_hPropMenuConstructions, "telephone001", "Telephone");
	AddMenuItem(g_hPropMenuConstructions, "telephonepole001", "Telephone Pole");
	AddMenuItem(g_hPropMenuConstructions, "thermos", "Thermos");
	AddMenuItem(g_hPropMenuConstructions, "tire001", "Tire 1");
	AddMenuItem(g_hPropMenuConstructions, "tire002", "Tire 2");
	AddMenuItem(g_hPropMenuConstructions, "tire003", "Tire 3");
	AddMenuItem(g_hPropMenuConstructions, "tracks001", "Tracks 1");
	AddMenuItem(g_hPropMenuConstructions, "tractor_01", "Tractor Wheel");
	AddMenuItem(g_hPropMenuConstructions, "train_engine_01", "Train Engine");
	AddMenuItem(g_hPropMenuConstructions, "train_flatcar_container", "Container 1");
	AddMenuItem(g_hPropMenuConstructions, "train_flatcar_container_01b", "Container 2");
	AddMenuItem(g_hPropMenuConstructions, "train_flatcar_container_01c", "Container 3");
	AddMenuItem(g_hPropMenuConstructions, "trainwheel001", "Train Wheel 1");
	AddMenuItem(g_hPropMenuConstructions, "trainwheel002", "Train Wheel 2");
	AddMenuItem(g_hPropMenuConstructions, "trainwheel003", "Train Wheel 3");
	AddMenuItem(g_hPropMenuConstructions, "tv001", "TV");
	AddMenuItem(g_hPropMenuConstructions, "uniform_locker", "Uniform Locker");
	AddMenuItem(g_hPropMenuConstructions, "uniform_locker_pj", "Uniform Locker 2");
	AddMenuItem(g_hPropMenuConstructions, "vent001", "Vent");
	AddMenuItem(g_hPropMenuConstructions, "wagonwheel001", "Wagon Wheel");
	AddMenuItem(g_hPropMenuConstructions, "wastebasket01", "Waste Basket");
	AddMenuItem(g_hPropMenuConstructions, "water_barrel", "Water Barrel");
	AddMenuItem(g_hPropMenuConstructions, "water_barrel_cluster", "Water Barrel Cluster 1");
	AddMenuItem(g_hPropMenuConstructions, "water_barrel_cluster2", "Water Barrel Cluster 2");
	AddMenuItem(g_hPropMenuConstructions, "water_barrel_cluster3", "Water Barrel Cluster 3");
	AddMenuItem(g_hPropMenuConstructions, "water_barrel_large", "Water Barrel (large)");
	AddMenuItem(g_hPropMenuConstructions, "water_spigot", "Water Spigot");
	AddMenuItem(g_hPropMenuConstructions, "waterpump001", "Water Pump");
	AddMenuItem(g_hPropMenuConstructions, "weathervane001", "Weather Vane");
	AddMenuItem(g_hPropMenuConstructions, "weight_scale", "Weight Scale");
	AddMenuItem(g_hPropMenuConstructions, "welding_machine01", "Welding Machine");
	AddMenuItem(g_hPropMenuConstructions, "wood_crate_01", "Wood Crate");
	AddMenuItem(g_hPropMenuConstructions, "wood_pile", "Wood Pile");
	AddMenuItem(g_hPropMenuConstructions, "wood_pile_short", "Wood Pile Short");
	AddMenuItem(g_hPropMenuConstructions, "wood_platform1", "Wood Platform 1");
	AddMenuItem(g_hPropMenuConstructions, "wood_platform2", "Wood Platform 2");
	AddMenuItem(g_hPropMenuConstructions, "wood_platform3", "Wood Platform 3");
	AddMenuItem(g_hPropMenuConstructions, "wood_stairs128", "Wood Stairs 128");
	AddMenuItem(g_hPropMenuConstructions, "wood_stairs48", "Wood Stairs 48");
	AddMenuItem(g_hPropMenuConstructions, "wood_stairs96", "Wood Stairs 96");
	AddMenuItem(g_hPropMenuConstructions, "wooden_barrel", "Wooden Barrel");
	AddMenuItem(g_hPropMenuConstructions, "woodpile_indoor", "Wood Pile Indoor");
	AddMenuItem(g_hPropMenuConstructions, "work_table001", "Work Table");
	
	
	/*	g_hPropNameArray = CreateArray(33, 2048);		// Max Prop List is 1024-->2048
	g_hPropModelPathArray = CreateArray(128, 2048);	// Max Prop List is 1024-->2048
	g_hPropTypeArray = CreateArray(33, 2048);		// Max Prop List is 1024-->2048
	g_hPropStringArray = CreateArray(256, 2048);
	
	ReadProps();
	
	new String:szPropName[32], String:szPropFrozen[32], String:szPropString[256], String:szModelPath[128];
	
	new PropName = FindStringInArray(g_hPropNameArray, szPropName);
	new PropString = FindStringInArray(g_hPropNameArray, szPropString);*/
	
	RegAdminCmd("sm_fda", ClientRemoveAll, ADMFLAG_SLAY);
	
	new String:buffer[512];
	
	g_hMenuCredits = CreateMenu(TF2SBCred1);
	
	Format(buffer, sizeof(buffer), "Credits\n \n");
	StrCat(buffer, sizeof(buffer), "Coders: Danct12, DaRkWoRlD\n");
	StrCat(buffer, sizeof(buffer), "\n \n");
	StrCat(buffer, sizeof(buffer), "greenteaf0718, hjkwe654 -for the original BuildMod\n");
	StrCat(buffer, sizeof(buffer), "FlaminSarge, javalia -for the GravityGun Mod\n");
	StrCat(buffer, sizeof(buffer), "Pelipoika -for the ToolGun Source Code!\n");
	StrCat(buffer, sizeof(buffer), "TESTBOT#7 -making official group profile\n");
	StrCat(buffer, sizeof(buffer), "iKiroZz -inspired me to make this mod\n");
	StrCat(buffer, sizeof(buffer), "SomePanns -help me fixing some problems at some parts.\n");
	StrCat(buffer, sizeof(buffer), "Garry Newman -for creating Garry's Mod, without him, this wouldn't exist.\n");
	StrCat(buffer, sizeof(buffer), "AlliedModders -without this, SourceMod wouldn't exist and this also won't.\n \n");
	
	SetMenuTitle(g_hMenuCredits, buffer);
	AddMenuItem(g_hMenuCredits, "0", "Next");
	
	g_hMenuCredits2 = CreateMenu(TF2SBCred2);
	
	Format(buffer, sizeof(buffer), "Credits\n \n");
	StrCat(buffer, sizeof(buffer), "Thanks to these people for tested this mod at the begin:\n \n");
	StrCat(buffer, sizeof(buffer), "periodicJudgement\n");
	StrCat(buffer, sizeof(buffer), "Lord Lecubon | ᵁᶳᴸ\n");
	StrCat(buffer, sizeof(buffer), "iKiroZz | Titan.TF\n");
	StrCat(buffer, sizeof(buffer), "Lazyneer\n");
	StrCat(buffer, sizeof(buffer), "Cecil\n");
	StrCat(buffer, sizeof(buffer), "TESTBOT#7\n");
	StrCat(buffer, sizeof(buffer), "And every DanctTF2 players who have joined to test it out!\n \n \n");
	StrCat(buffer, sizeof(buffer), "THANKS FOR PLAYING\n \n");
	
	SetMenuTitle(g_hMenuCredits2, buffer);
	AddMenuItem(g_hMenuCredits2, "0", "Back");
	RegAdminCmd("sm_tf2sb", Command_TF2SBCred, 0);
}

public Action:Command_TF2SBCred(client, args)
{
	
	DisplayMenu(g_hMenuCredits, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public TF2SBCred1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:DisplayMenu(g_hMenuCredits2, param1, MENU_TIME_FOREVER);
		}
	}
}

public TF2SBCred2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:DisplayMenu(g_hMenuCredits, param1, MENU_TIME_FOREVER);
		}
	}
}

stock Float:GetEntitiesDistance(ent1, ent2)
{
	new Float:orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	new Float:orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);
	
	return GetVectorDistance(orig1, orig2);
}

public OnMapStart() {
	AutoExecConfig();
}

public OnClientPutInServer(Client) {
	GetClientAuthId(Client, AuthId_Steam2, g_szConnectedClient[Client], sizeof(g_szConnectedClient));
}

public OnClientDisconnect(Client) {
	FakeClientCommand(Client, "sm_delall");
}

public Action:Timer_Disconnect(Handle:Timer, Handle:hPack) {
	ResetPack(hPack);
	new Client = ReadPackCell(hPack);
	
	new iCount;
	for (new iCheck = Client; iCheck < MAX_HOOK_ENTITIES; iCheck++) {
		if (IsValidEntity(iCheck)) {
			if (g_iTempOwner[iCheck] == Client) {
				AcceptEntityInput(iCheck, "Kill", -1);
				iCount++;
			}
		}
	}
	
	return;
}

public Action:Command_Copy(Client, args) {
	
	if (g_bBuffer[Client])
	{
		Build_PrintToChat(Client, "You're doing it so fast! Slow it down!");
		
		return Plugin_Handled;
	}
	
	g_bBuffer[Client] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(Client));
	
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	
	
	new iEntity = Build_ClientAimEntity(Client, true, true);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (!Build_IsAdmin(Client, true)) {
		if (GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT))
			return Plugin_Handled;
	}
	
	if (!Build_IsEntityOwner(Client, iEntity, true))
		return Plugin_Handled;
	
	if (g_bCopyIsRunning[Client]) {
		Build_PrintToChat(Client, "You are already copying something!");
		return Plugin_Handled;
	}
	
	new String:szClass[33], bool:bCanCopy = false;
	GetEdictClassname(iEntity, szClass, sizeof(szClass));
	for (new i = 0; i < sizeof(CopyableProps); i++) {
		if (StrEqual(szClass, CopyableProps[i], false))
			bCanCopy = true;
	}
	
	new bool:IsDoll = false;
	if (StrEqual(szClass, "prop_ragdoll") || StrEqual(szClass, "player")) {
		if (Build_IsAdmin(Client, true)) {
			g_iCopyTarget[Client] = CreateEntityByName("prop_ragdoll");
			IsDoll = true;
		} else {
			Build_PrintToChat(Client, "You need \x04L2 Build Access\x01 to copy this prop!");
			return Plugin_Handled;
		}
	} else {
		if (StrEqual(szClass, "func_physbox") && !Build_IsAdmin(Client, true)) {
			
			Build_PrintToChat(Client, "You can't copy this prop!");
			return Plugin_Handled;
		}
		
		g_iCopyTarget[Client] = CreateEntityByName(szClass);
	}
	
	if (Build_RegisterEntityOwner(g_iCopyTarget[Client], Client, IsDoll)) {
		if (bCanCopy) {
			new Float:fEntityOrigin[3], Float:fEntityAngle[3];
			new String:szModelName[128];
			new String:szColorR[20], String:szColorG[20], String:szColorB[20], String:szColor[3][128], String:szColor2[255];
			
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
			GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fEntityAngle);
			GetEntPropString(iEntity, Prop_Data, "m_ModelName", szModelName, sizeof(szModelName));
			if (StrEqual(szModelName, "models/props_c17/oildrum001_explosive.mdl") && !Build_IsAdmin(Client, true)) {
				Build_PrintToChat(Client, "You need \x04L2 Build Access\x01 to copy this prop!");
				RemoveEdict(g_iCopyTarget[Client]);
				return Plugin_Handled;
			}
			DispatchKeyValue(g_iCopyTarget[Client], "model", szModelName);
			
			
			GetEdictClassname(g_iCopyTarget[Client], szClass, sizeof(szClass));
			if (StrEqual(szClass, "prop_dynamic")) {
				SetEntProp(g_iCopyTarget[Client], Prop_Send, "m_nSolidType", 6);
				SetEntProp(g_iCopyTarget[Client], Prop_Data, "m_nSolidType", 6);
			}
			
			DispatchSpawn(g_iCopyTarget[Client]);
			TeleportEntity(g_iCopyTarget[Client], fEntityOrigin, fEntityAngle, NULL_VECTOR);
			
			GetCmdArg(1, szColorR, sizeof(szColorR));
			GetCmdArg(2, szColorG, sizeof(szColorG));
			GetCmdArg(3, szColorB, sizeof(szColorB));
			
			DispatchKeyValue(g_iCopyTarget[Client], "rendermode", "5");
			DispatchKeyValue(g_iCopyTarget[Client], "renderamt", "150");
			DispatchKeyValue(g_iCopyTarget[Client], "renderfx", "4");
			
			if (args > 1) {
				szColor[0] = szColorR;
				szColor[1] = szColorG;
				szColor[2] = szColorB;
				ImplodeStrings(szColor, 3, " ", szColor2, 255);
				DispatchKeyValue(g_iCopyTarget[Client], "rendercolor", szColor2);
			} else {
				DispatchKeyValue(g_iCopyTarget[Client], "rendercolor", "50 255 255");
			}
			g_bCopyIsRunning[Client] = true;
			
			CreateTimer(0.01, Timer_CopyRing, Client);
			CreateTimer(0.01, Timer_CopyBeam, Client);
			CreateTimer(0.02, Timer_CopyMain, Client);
			return Plugin_Handled;
		} else {
			Build_PrintToChat(Client, "This prop was not copy able.");
			return Plugin_Handled;
		}
	} else {
		RemoveEdict(g_iCopyTarget[Client]);
		return Plugin_Handled;
	}
}

public Action:Command_Paste(Client, args) {
	
	if (!Build_AllowToUse(Client))
		return Plugin_Handled;
	
	g_bCopyIsRunning[Client] = false;
	return Plugin_Handled;
}

public Action:Timer_CopyBeam(Handle:Timer, any:Client) {
	if (IsValidEntity(g_iCopyTarget[Client]) && Build_IsClientValid(Client, Client)) {
		decl Float:fOriginPlayer[3], Float:fOriginEntity[3];
		
		GetClientAbsOrigin(Client, g_fCopyPlayerOrigin[Client]);
		GetClientAbsOrigin(Client, fOriginPlayer);
		
		GetEntPropVector(g_iCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity);
		fOriginPlayer[2] += 50;
		
		new iColor[4];
		iColor[0] = GetRandomInt(50, 255);
		iColor[1] = GetRandomInt(50, 255);
		iColor[2] = GetRandomInt(50, 255);
		iColor[3] = GetRandomInt(255, 255);
		
		TE_SetupBeamPoints(fOriginEntity, fOriginPlayer, g_PBeam, g_Halo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, iColor, 20);
		TE_SendToAll();
		
		if (g_bCopyIsRunning[Client])
			CreateTimer(0.01, Timer_CopyBeam, Client);
	}
}

public Action:Timer_CopyRing(Handle:Timer, any:Client) {
	if (IsValidEntity(g_iCopyTarget[Client]) && Build_IsClientValid(Client, Client)) {
		decl Float:fOriginEntity[3];
		
		GetEntPropVector(g_iCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity);
		
		new iColor[4];
		iColor[0] = GetRandomInt(50, 255);
		iColor[1] = GetRandomInt(254, 255);
		iColor[2] = GetRandomInt(254, 255);
		iColor[3] = GetRandomInt(250, 255);
		
		TE_SetupBeamRingPoint(fOriginEntity, 10.0, 15.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(fOriginEntity, 80.0, 100.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0);
		TE_SendToAll();
		
		if (g_bCopyIsRunning[Client])
			CreateTimer(0.3, Timer_CopyRing, Client);
	}
}

public Action:Timer_CopyMain(Handle:Timer, any:Client) {
	if (IsValidEntity(g_iCopyTarget[Client]) && Build_IsClientValid(Client, Client)) {
		decl Float:fOriginEntity[3], Float:fOriginPlayer[3];
		
		GetEntPropVector(g_iCopyTarget[Client], Prop_Data, "m_vecOrigin", fOriginEntity);
		GetClientAbsOrigin(Client, fOriginPlayer);
		
		fOriginEntity[0] += fOriginPlayer[0] - g_fCopyPlayerOrigin[Client][0];
		fOriginEntity[1] += fOriginPlayer[1] - g_fCopyPlayerOrigin[Client][1];
		fOriginEntity[2] += fOriginPlayer[2] - g_fCopyPlayerOrigin[Client][2];
		
		SetEntityMoveType(g_iCopyTarget[Client], MOVETYPE_NONE);
		TeleportEntity(g_iCopyTarget[Client], fOriginEntity, NULL_VECTOR, NULL_VECTOR);
		
		if (g_bCopyIsRunning[Client])
			CreateTimer(0.001, Timer_CopyMain, Client);
		else {
			SetEntityMoveType(g_iCopyTarget[Client], MOVETYPE_VPHYSICS);
			
			DispatchKeyValue(g_iCopyTarget[Client], "rendermode", "5");
			DispatchKeyValue(g_iCopyTarget[Client], "renderamt", "255");
			DispatchKeyValue(g_iCopyTarget[Client], "renderfx", "0");
			DispatchKeyValue(g_iCopyTarget[Client], "rendercolor", "255 255 255");
		}
	}
}

public Action:Timer_CoolDown(Handle:hTimer, any:iBuffer)
{
	new iClient = GetClientFromSerial(iBuffer);
	
	if (g_bBuffer[iClient])g_bBuffer[iClient] = false;
}

public Action:Command_OpenableDoorProp(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (g_bBuffer[Client])
	{
		Build_PrintToChat(Client, "You're doing it too fast! Slow it down!");
		
		return Plugin_Handled;
	}
	
	g_bBuffer[Client] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(Client));
	
	new iDoor = CreateEntityByName("prop_door_rotating");
	if (Build_RegisterEntityOwner(iDoor, Client)) {
		new String:szRange[33], String:szBrightness[33], String:szColorR[33], String:szColorG[33], String:szColorB[33];
		new String:szNamePropDoor[64];
		new Float:fOriginAim[3];
		GetCmdArg(1, szRange, sizeof(szRange));
		GetCmdArg(2, szBrightness, sizeof(szBrightness));
		GetCmdArg(3, szColorR, sizeof(szColorR));
		GetCmdArg(4, szColorG, sizeof(szColorG));
		GetCmdArg(5, szColorB, sizeof(szColorB));
		
		Build_ClientAimOrigin(Client, fOriginAim);
		fOriginAim[2] += 50;
		
		if (!IsModelPrecached("models/props_manor/doorframe_01_door_01a.mdl"))
			PrecacheModel("models/props_manor/doorframe_01_door_01a.mdl");
		
		DispatchKeyValue(iDoor, "model", "models/props_manor/doorframe_01_door_01a.mdl");
		DispatchKeyValue(iDoor, "distance", "90");
		DispatchKeyValue(iDoor, "speed", "100");
		DispatchKeyValue(iDoor, "returndelay", "-1");
		DispatchKeyValue(iDoor, "dmg", "-20");
		DispatchKeyValue(iDoor, "opendir", "0");
		DispatchKeyValue(iDoor, "spawnflags", "8192");
		//DispatchKeyValue(iDoor, "OnFullyOpen", "!caller,close,,0,-1");
		DispatchKeyValue(iDoor, "hardware", "1");
		
		DispatchSpawn(iDoor);
		
		TeleportEntity(iDoor, fOriginAim, NULL_VECTOR, NULL_VECTOR);
		
		Format(szNamePropDoor, sizeof(szNamePropDoor), "TF2SB_Door%i", GetRandomInt(1000, 5000));
		DispatchKeyValue(iDoor, "targetname", szNamePropDoor);
		SetVariantString(szNamePropDoor);
	} else
		RemoveEdict(iDoor);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_propdoor", szArgs);
	return Plugin_Handled;
}

public Action:Command_kill(Client, Args) {
	if (!Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	ForcePlayerSuicide(Client);
	
	//if (GetCmdArgs() > 0)
	//	Build_PrintToChat(Client, "Don't use unneeded args in kill");
	
	return Plugin_Handled;
}

public Action:Command_Render(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 5) {
		
		Build_PrintToChat(Client, "Usage: !render <fx amount> <fx> <R> <G> <B>");
		Build_PrintToChat(Client, "Ex. Flashing Green: !render 150 4 15 255 0");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:szRenderAlpha[20], String:szRenderFX[20], String:szColorRGB[20][3], String:szColors[128];
		GetCmdArg(1, szRenderAlpha, sizeof(szRenderAlpha));
		GetCmdArg(2, szRenderFX, sizeof(szRenderFX));
		GetCmdArg(3, szColorRGB[0], sizeof(szColorRGB));
		GetCmdArg(4, szColorRGB[1], sizeof(szColorRGB));
		GetCmdArg(5, szColorRGB[2], sizeof(szColorRGB));
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2]);
		if (StringToInt(szRenderAlpha) < 1)
			szRenderAlpha = "1";
		DispatchKeyValue(iEntity, "rendermode", "5");
		DispatchKeyValue(iEntity, "renderamt", szRenderAlpha);
		DispatchKeyValue(iEntity, "renderfx", szRenderFX);
		DispatchKeyValue(iEntity, "rendercolor", szColors);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_render", szArgs);
	return Plugin_Handled;
}

public Action:Command_Color(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 3) {
		Build_PrintToChat(Client, "Usage: !color <R> <G> <B>");
		Build_PrintToChat(Client, "Ex: Green: !color 0 255 0");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:szColorRGB[20][3], String:szColors[33];
		GetCmdArg(1, szColorRGB[0], sizeof(szColorRGB));
		GetCmdArg(2, szColorRGB[1], sizeof(szColorRGB));
		GetCmdArg(3, szColorRGB[2], sizeof(szColorRGB));
		
		Format(szColors, sizeof(szColors), "%s %s %s", szColorRGB[0], szColorRGB[1], szColorRGB[2]);
		DispatchKeyValue(iEntity, "rendermode", "5");
		DispatchKeyValue(iEntity, "renderamt", "255");
		DispatchKeyValue(iEntity, "renderfx", "0");
		DispatchKeyValue(iEntity, "rendercolor", szColors);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_color", szArgs);
	return Plugin_Handled;
}

public Action:Command_PropScale(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !propscale <number>");
		Build_PrintToChat(Client, "Notice: Physics are non-scaled.");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		
		//new Float:Scale2  = GetEntPropFloat(iEntity, Prop_Send, "m_flModelScale");
		new String:szPropScale[33];
		GetCmdArg(1, szPropScale, sizeof(szPropScale));
		
		new Float:Scale = StringToFloat(szPropScale);
		
		SetVariantString(szPropScale);
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", Scale);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_propscale", szArgs);
	return Plugin_Handled;
}

public Action:Command_Skin(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !skin <number>");
		Build_PrintToChat(Client, "Notice: Not every model have multiple skins.");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:szSkin[33];
		GetCmdArg(1, szSkin, sizeof(szSkin));
		
		SetVariantString(szSkin);
		AcceptEntityInput(iEntity, "skin", iEntity, Client, 0);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_skin", szArgs);
	return Plugin_Handled;
}

public Action:Command_Rotate(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !rotate/!r <x> <y> <z>");
		Build_PrintToChat(Client, "Ex: !rotate 0 90 0");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:szAngleX[8], String:szAngleY[8], String:szAngleZ[8];
		new Float:fEntityOrigin[3], Float:fEntityAngle[3];
		GetCmdArg(1, szAngleX, sizeof(szAngleX));
		GetCmdArg(2, szAngleY, sizeof(szAngleY));
		GetCmdArg(3, szAngleZ, sizeof(szAngleZ));
		
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fEntityAngle);
		fEntityAngle[0] += StringToFloat(szAngleX);
		fEntityAngle[1] += StringToFloat(szAngleY);
		fEntityAngle[2] += StringToFloat(szAngleZ);
		
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_rotate", szArgs);
	return Plugin_Handled;
}

public Action:Command_Fly(Client, args) {
	
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true) || !Build_AllowFly(Client))
		return Plugin_Handled;
	
	if (GetEntityMoveType(Client) != MOVETYPE_NOCLIP)
	{
		Build_PrintToChat(Client, "Noclip ON");
		SetEntityMoveType(Client, MOVETYPE_NOCLIP);
	}
	else
	{
		Build_PrintToChat(Client, "Noclip OFF");
		SetEntityMoveType(Client, MOVETYPE_WALK);
	}
	return Plugin_Handled;
}

public Action:Command_SimpleLight(Client, args) {
	
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	/*if (g_bBuffer[Client])
	{
		Build_PrintToChat(Client, "You're doing it too fast! Slow it down!");
		
		return Plugin_Handled;
	}
	
	g_bBuffer[Client] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(Client));*/
	FakeClientCommand(Client, "sm_ld 7 255 255 255");
	
	return Plugin_Handled;
}

public Action:Command_AccurateRotate(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !ar <x> <y> <z>");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:szRotateX[33], String:szRotateY[33], String:szRotateZ[33];
		new Float:fEntityOrigin[3], Float:fEntityAngle[3];
		GetCmdArg(1, szRotateX, sizeof(szRotateX));
		GetCmdArg(2, szRotateY, sizeof(szRotateY));
		GetCmdArg(3, szRotateZ, sizeof(szRotateZ));
		
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
		fEntityAngle[0] = StringToFloat(szRotateX);
		fEntityAngle[1] = StringToFloat(szRotateY);
		fEntityAngle[2] = StringToFloat(szRotateZ);
		
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_accuraterotate", szArgs);
	return Plugin_Handled;
}

public Action:Command_LightDynamic(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !ld <brightness> <R> <G> <B>");
		return Plugin_Handled;
	}
	
	if (g_bBuffer[Client])
	{
		Build_PrintToChat(Client, "You're doing it too fast! Slow it down!");
		
		return Plugin_Handled;
	}
	
	g_bBuffer[Client] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(Client));
	
	new Obj_LightDMelon = CreateEntityByName("prop_dynamic");
	if (Build_RegisterEntityOwner(Obj_LightDMelon, Client)) {
		new String:szBrightness[33], String:szColorR[33], String:szColorG[33], String:szColorB[33], String:szColor[33];
		new String:szNameMelon[64];
		new Float:fOriginAim[3];
		//GetCmdArg(1, szRange, sizeof(szRange));
		GetCmdArg(1, szBrightness, sizeof(szBrightness));
		GetCmdArg(2, szColorR, sizeof(szColorR));
		GetCmdArg(3, szColorG, sizeof(szColorG));
		GetCmdArg(4, szColorB, sizeof(szColorB));
		
		Build_ClientAimOrigin(Client, fOriginAim);
		fOriginAim[2] += 50;
		
		if (!IsModelPrecached("models/props_2fort/lightbulb001.mdl"))
			PrecacheModel("models/props_2fort/lightbulb001.mdl");
		
		if (StrEqual(szBrightness, ""))
			szBrightness = "3";
		if (StringToInt(szColorR) < 100 || StrEqual(szColorR, ""))
			szColorR = "100";
		if (StringToInt(szColorG) < 100 || StrEqual(szColorG, ""))
			szColorG = "100";
		if (StringToInt(szColorB) < 100 || StrEqual(szColorB, ""))
			szColorB = "100";
		Format(szColor, sizeof(szColor), "%s %s %s", szColorR, szColorG, szColorB);
		
		DispatchKeyValue(Obj_LightDMelon, "model", "models/props_2fort/lightbulb001.mdl");
		//DispatchKeyValue(Obj_LightDMelon, "rendermode", "5");
		//DispatchKeyValue(Obj_LightDMelon, "renderamt", "150");
		//DispatchKeyValue(Obj_LightDMelon, "renderfx", "15");
		DispatchKeyValue(Obj_LightDMelon, "rendercolor", szColor);
		
		new Obj_LightDynamic = CreateEntityByName("light_dynamic");
		
		if (StringToInt(szBrightness) > 7) {
			Build_PrintToChat(Client, "Max brightness is 7!");
			
			Build_SetLimit(Client, -1);
			return Plugin_Handled;
		}
		
		SetVariantString("500");
		AcceptEntityInput(Obj_LightDynamic, "distance", -1);
		SetVariantString(szBrightness);
		AcceptEntityInput(Obj_LightDynamic, "brightness", -1);
		SetVariantString("2");
		AcceptEntityInput(Obj_LightDynamic, "style", -1);
		SetVariantString(szColor);
		AcceptEntityInput(Obj_LightDynamic, "color", -1);
		SetEntProp(Obj_LightDMelon, Prop_Send, "m_nSolidType", 6);
		
		
		
		DispatchSpawn(Obj_LightDMelon);
		TeleportEntity(Obj_LightDMelon, fOriginAim, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(Obj_LightDynamic);
		TeleportEntity(Obj_LightDynamic, fOriginAim, NULL_VECTOR, NULL_VECTOR);
		
		Format(szNameMelon, sizeof(szNameMelon), "Obj_LightDMelon%i", GetRandomInt(1000, 5000));
		DispatchKeyValue(Obj_LightDMelon, "targetname", szNameMelon);
		SetVariantString(szNameMelon);
		AcceptEntityInput(Obj_LightDynamic, "setparent", -1);
		AcceptEntityInput(Obj_LightDynamic, "turnon", Client, Client);
		
	} else
		RemoveEdict(Obj_LightDMelon);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_ld", szArgs);
	return Plugin_Handled;
}

public Action:Command_SpawnDoor(Client, args) {
	if (!Build_AllowToUse(Client))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (g_bBuffer[Client])
	{
		Build_PrintToChat(Client, "You're doing it too fast! Slow it down!");
		
		return Plugin_Handled;
	}
	
	g_bBuffer[Client] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(Client));
	
	decl String:szDoorTarget[16], String:szType[4], String:szFormatStr[64], String:szNameStr[8];
	decl Float:iAim[3];
	Build_ClientAimOrigin(Client, iAim);
	GetCmdArg(1, szType, sizeof(szType));
	static iEntity;
	new String:szModel[128];
	
	if (StrEqual(szType[0], "1") || StrEqual(szType[0], "2") || StrEqual(szType[0], "3") || StrEqual(szType[0], "4") || StrEqual(szType[0], "5") || StrEqual(szType[0], "6") || StrEqual(szType[0], "7")) {
		new Obj_Door = CreateEntityByName("prop_dynamic");
		
		switch (szType[0]) {
			case '1':szModel = "models/props_lab/blastdoor001c.mdl";
			case '2':szModel = "models/props_lab/blastdoor001c.mdl";
			case '3':szModel = "models/props_lab/blastdoor001c.mdl";
			case '4':szModel = "models/props_lab/blastdoor001c.mdl";
			case '5':szModel = "models/props_lab/blastdoor001c.mdl";
			case '6':szModel = "models/props_lab/blastdoor001c.mdl";
			case '7':szModel = "models/props_lab/blastdoor001c.mdl";
		}
		
		DispatchKeyValue(Obj_Door, "model", szModel);
		SetEntProp(Obj_Door, Prop_Send, "m_nSolidType", 6);
		if (Build_RegisterEntityOwner(Obj_Door, Client)) {
			TeleportEntity(Obj_Door, iAim, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(Obj_Door);
		}
	} else if (StrEqual(szType[0], "a") || StrEqual(szType[0], "b") || StrEqual(szType[0], "c")) {
		
		iEntity = Build_ClientAimEntity(Client);
		if (iEntity == -1)
			return Plugin_Handled;
		
		switch (szType[0]) {
			case 'a': {
				new iName = GetRandomInt(1000, 5000);
				
				IntToString(iName, szNameStr, sizeof(szNameStr));
				Format(szFormatStr, sizeof(szFormatStr), "door%s", szNameStr);
				DispatchKeyValue(iEntity, "targetname", szFormatStr);
				
				GetEntPropString(iEntity, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
				SetClientCookie(Client, g_hCookieSDoorTarget, szFormatStr);
				SetClientCookie(Client, g_hCookieSDoorModel, szModel);
			}
			case 'b': {
				GetClientCookie(Client, g_hCookieSDoorTarget, szDoorTarget, sizeof(szDoorTarget));
				GetClientCookie(Client, g_hCookieSDoorModel, szModel, sizeof(szModel));
				
				if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,dog_open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,DisableCollision,,1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,5", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,EnableCollision,,5.1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
				} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Drop,7", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
				} else {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,4", szDoorTarget);
					DispatchKeyValue(iEntity, "OnHealthChanged", szFormatStr);
				}
			}
			case 'c': {
				GetClientCookie(Client, g_hCookieSDoorTarget, szDoorTarget, sizeof(szDoorTarget));
				GetClientCookie(Client, g_hCookieSDoorModel, szModel, sizeof(szModel));
				DispatchKeyValue(iEntity, "spawnflags", "258");
				
				if (StrEqual(szModel, "models/props_lab/blastdoor001c.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,dog_open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,DisableCollision,,1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,5", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,EnableCollision,,5.1", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
				} else if (StrEqual(szModel, "models/props_lab/RavenDoor.mdl")) {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,RavenDoor_Drop,7", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
				} else {
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,open,0", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
					Format(szFormatStr, sizeof(szFormatStr), "%s,setanimation,close,4", szDoorTarget);
					DispatchKeyValue(iEntity, "OnPlayerUse", szFormatStr);
				}
			}
		}
	} else {
		Build_PrintToChat(Client, "Usage: !sdoor <choose>");
		Build_PrintToChat(Client, "!sdoor 1~7 = Spawn door");
		Build_PrintToChat(Client, "!sdoor a = Select door");
		Build_PrintToChat(Client, "!sdoor b = Select button (Shoot to open)");
		Build_PrintToChat(Client, "!sdoor c = Select button (Press to open)");
		Build_PrintToChat(Client, "NOTE: Not all doors movable using PhysGun, use the !move command!");
	}
	return Plugin_Handled;
}


public Action:Command_Move(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !move <x> <y> <z>");
		Build_PrintToChat(Client, "Ex, move up 50: !move 0 0 50");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new Float:fEntityOrigin[3], Float:fEntityAngle[3];
		new String:szArgX[33], String:szArgY[33], String:szArgZ[33];
		GetCmdArg(1, szArgX, sizeof(szArgX));
		GetCmdArg(2, szArgY, sizeof(szArgY));
		GetCmdArg(3, szArgZ, sizeof(szArgZ));
		
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
		GetEntPropVector(iEntity, Prop_Data, "m_angRotation", fEntityAngle);
		
		fEntityOrigin[0] += StringToFloat(szArgX);
		fEntityOrigin[1] += StringToFloat(szArgY);
		fEntityOrigin[2] += StringToFloat(szArgZ);
		
		TeleportEntity(iEntity, fEntityOrigin, fEntityAngle, NULL_VECTOR);
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_move", szArgs);
	return Plugin_Handled;
}

public Action:Command_SetName(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !setname <name you want it to be>");
		Build_PrintToChat(Client, "Ex: !setname \"A teddy bear\"");
		Build_PrintToChat(Client, "Ex: !setname \"Gabe Newell\"");
		return Plugin_Handled;
	}
	
	new iEntity = Build_ClientAimEntity(Client);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:newpropname[256];
		GetCmdArg(args, newpropname, sizeof(newpropname));
		//Format(newpropname, sizeof(newpropname), "%s", args);
		SetEntPropString(iEntity, Prop_Data, "m_iName", newpropname);
	}
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_setname", szArgs);
	return Plugin_Handled;
}

public Action:Command_SpawnProp(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(Client))
	{
		Build_PrintToChat(Client, "You must be alive to use this command!");
		
		return Plugin_Handled;
	}
	
	if (args < 1) {
		Build_PrintToChat(Client, "Usage: !spawnprop/!s <Prop name>");
		Build_PrintToChat(Client, "Ex: !spawnprop goldbar");
		Build_PrintToChat(Client, "Ex: !spawnprop alyx");
		return Plugin_Handled;
	}
	
	new String:szPropName[32], String:szPropFrozen[32], String:szPropString[256], String:szModelPath[128];
	GetCmdArg(1, szPropName, sizeof(szPropName));
	GetCmdArg(2, szPropFrozen, sizeof(szPropFrozen));
	
	new IndexInArray = FindStringInArray(g_hPropNameArray, szPropName);
	
	if (StrEqual(szPropName, "explosivecan") && !Build_IsAdmin(Client, true)) {
		Build_PrintToChat(Client, "You need \x04L2 Build Access\x01 to spawn this prop!");
		return Plugin_Handled;
	}
	
	if (g_bBuffer[Client])
	{
		Build_PrintToChat(Client, "You're doing it too fast! Slow it down!");
		
		return Plugin_Handled;
	}
	
	g_bBuffer[Client] = true;
	CreateTimer(0.5, Timer_CoolDown, GetClientSerial(Client));
	
	if (IndexInArray != -1) {
		new bool:bIsDoll = false;
		new String:szEntType[33];
		GetArrayString(g_hPropTypeArray, IndexInArray, szEntType, sizeof(szEntType));
		
		if (!Build_IsAdmin(Client, true)) {
			if (StrEqual(szPropName, "explosivecan") || StrEqual(szEntType, "prop_ragdoll")) {
				Build_PrintToChat(Client, "You need \x04L2 Build Access\x01 to spawn this prop!");
				return Plugin_Handled;
			}
		}
		if (StrEqual(szEntType, "prop_ragdoll"))
			bIsDoll = true;
		
		new iEntity = CreateEntityByName(szEntType);
		
		if (Build_RegisterEntityOwner(iEntity, Client, bIsDoll)) {
			new Float:fOriginWatching[3], Float:fOriginFront[3], Float:fAngles[3], Float:fRadiansX, Float:fRadiansY;
			
			decl Float:iAim[3];
			new Float:vOriginPlayer[3];
			
			GetClientEyePosition(Client, fOriginWatching);
			GetClientEyeAngles(Client, fAngles);
			
			fRadiansX = DegToRad(fAngles[0]);
			fRadiansY = DegToRad(fAngles[1]);
			
			fOriginFront[0] = fOriginWatching[0] + (100 * Cosine(fRadiansY) * Cosine(fRadiansX));
			fOriginFront[1] = fOriginWatching[1] + (100 * Sine(fRadiansY) * Cosine(fRadiansX));
			fOriginFront[2] = fOriginWatching[2] - 20;
			
			GetArrayString(g_hPropModelPathArray, IndexInArray, szModelPath, sizeof(szModelPath));
			
			
			GetArrayString(g_hPropStringArray, IndexInArray, szPropString, sizeof(szPropString));
			
			if (!IsModelPrecached(szModelPath))
				PrecacheModel(szModelPath);
			
			DispatchKeyValue(iEntity, "model", szModelPath);
			
			//DispatchKeyValue(iEntity, "propnametf2sb", szPropString);
			SetEntPropString(iEntity, Prop_Data, "m_iName", szPropString);
			
			if (StrEqual(szEntType, "prop_dynamic"))
				SetEntProp(iEntity, Prop_Send, "m_nSolidType", 6);
			
			if (StrEqual(szEntType, "prop_dynamic_override"))
				SetEntProp(iEntity, Prop_Send, "m_nSolidType", 6);
			
			Build_ClientAimOrigin(Client, iAim);
			iAim[2] = iAim[2] + 10;
			
			GetClientAbsOrigin(Client, vOriginPlayer);
			vOriginPlayer[2] = vOriginPlayer[2] + 50;
			
			
			DispatchSpawn(iEntity);
			TeleportEntity(iEntity, iAim, NULL_VECTOR, NULL_VECTOR);
			
			
			
			TE_SetupBeamPoints(iAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
			TE_SendToAll();
			
			new random = GetRandomInt(0, 1);
			if (random == 1) {
				EmitAmbientSound("buttons/button3.wav", iAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
				EmitAmbientSound("buttons/button3.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			} else {
				EmitAmbientSound("buttons/button3.wav", iAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
				EmitAmbientSound("buttons/button3.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			}
			
			SetEntProp(iEntity, Prop_Data, "m_takedamage", 0);
			
			// Debugging issues
			//PrintToChatAll(szPropString);
			
		} else
			RemoveEdict(iEntity);
	} else {
		Build_PrintToChat(Client, "Prop not found: %s", szPropName);
	}
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_spawnprop", szArgs);
	return Plugin_Handled;
}

ReadProps() {
	BuildPath(Path_SM, g_szFile, sizeof(g_szFile), "configs/buildmod/props.ini");
	
	new Handle:iFile = OpenFile(g_szFile, "rt");
	if (iFile == INVALID_HANDLE)
		return;
	
	new iCountProps = 0;
	while (!IsEndOfFile(iFile))
	{
		decl String:szLine[255];
		if (!ReadFileLine(iFile, szLine, sizeof(szLine)))
			break;
		
		/* 略過註解 */
		new iLen = strlen(szLine);
		new bool:bIgnore = false;
		
		for (new i = 0; i < iLen; i++) {
			if (bIgnore) {
				if (szLine[i] == '"')
					bIgnore = false;
			} else {
				if (szLine[i] == '"')
					bIgnore = true;
				else if (szLine[i] == ';') {
					szLine[i] = '\0';
					break;
				} else if (szLine[i] == '/' && i != iLen - 1 && szLine[i + 1] == '/') {
					szLine[i] = '\0';
					break;
				}
			}
		}
		
		TrimString(szLine);
		
		if ((szLine[0] == '/' && szLine[1] == '/') || (szLine[0] == ';' || szLine[0] == '\0'))
			continue;
		
		ReadPropsLine(szLine, iCountProps++);
	}
	CloseHandle(iFile);
}

ReadPropsLine(const String:szLine[], iCountProps) {
	decl String:szPropInfo[4][128];
	ExplodeString(szLine, ", ", szPropInfo, sizeof(szPropInfo), sizeof(szPropInfo[]));
	
	StripQuotes(szPropInfo[0]);
	SetArrayString(g_hPropNameArray, iCountProps, szPropInfo[0]);
	
	StripQuotes(szPropInfo[1]);
	SetArrayString(g_hPropModelPathArray, iCountProps, szPropInfo[1]);
	
	StripQuotes(szPropInfo[2]);
	SetArrayString(g_hPropTypeArray, iCountProps, szPropInfo[2]);
	
	StripQuotes(szPropInfo[3]);
	SetArrayString(g_hPropStringArray, iCountProps, szPropInfo[3]);
	
	AddMenuItem(g_hPropMenuHL2, szPropInfo[0], szPropInfo[3]);
}

public Action:Command_EnableGrab(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	g_iGrabTarget[Client] = Build_ClientAimEntity(Client, true, true);
	if (g_iGrabTarget[Client] == -1)
		return Plugin_Handled;
	
	if (g_bGrabIsRunning[Client]) {
		Build_PrintToChat(Client, "You are already grabbing something!");
		return Plugin_Handled;
	}
	
	if (!Build_IsAdmin(Client)) {
		if (GetEntityFlags(g_iGrabTarget[Client]) == (FL_CLIENT | FL_FAKECLIENT))
			return Plugin_Handled;
	}
	
	if (Build_IsEntityOwner(Client, g_iGrabTarget[Client])) {
		decl String:szFreeze[20], String:szColorR[20], String:szColorG[20], String:szColorB[20], String:szColor[128];
		GetCmdArg(1, szFreeze, sizeof(szFreeze));
		GetCmdArg(2, szColorR, sizeof(szColorR));
		GetCmdArg(3, szColorG, sizeof(szColorG));
		GetCmdArg(4, szColorB, sizeof(szColorB));
		
		g_bGrabFreeze[Client] = true;
		if (StrEqual(szFreeze, "1"))
			g_bGrabFreeze[Client] = true;
		
		DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5");
		DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "150");
		DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "4");
		
		if (StrEqual(szColorR, ""))
			szColorR = "255";
		if (StrEqual(szColorG, ""))
			szColorG = "50";
		if (StrEqual(szColorB, ""))
			szColorB = "50";
		Format(szColor, sizeof(szColor), "%s %s %s", szColorR, szColorG, szColorB);
		DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", szColor);
		
		g_mtGrabMoveType[Client] = GetEntityMoveType(g_iGrabTarget[Client]);
		g_bGrabIsRunning[Client] = true;
		
		CreateTimer(0.01, Timer_GrabBeam, Client);
		CreateTimer(0.01, Timer_GrabRing, Client);
		CreateTimer(0.05, Timer_GrabMain, Client);
	}
	return Plugin_Handled;
}

public Action:Command_DisableGrab(Client, args) {
	g_bGrabIsRunning[Client] = false;
	return Plugin_Handled;
}

public Action:Timer_GrabBeam(Handle:Timer, any:Client) {
	if (IsValidEntity(g_iGrabTarget[Client]) && Build_IsClientValid(Client, Client)) {
		new Float:vOriginEntity[3], Float:vOriginPlayer[3];
		
		GetClientAbsOrigin(Client, g_vGrabPlayerOrigin[Client]);
		GetClientAbsOrigin(Client, vOriginPlayer);
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity);
		vOriginPlayer[2] += 50;
		
		new iColor[4];
		iColor[0] = GetRandomInt(50, 255);
		iColor[1] = GetRandomInt(50, 255);
		iColor[2] = GetRandomInt(50, 255);
		iColor[3] = 255;
		
		TE_SetupBeamPoints(vOriginEntity, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 0.1, 2.0, 2.0, 0, 0.0, iColor, 20);
		TE_SendToAll();
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.01, Timer_GrabBeam, Client);
	}
}

public Action:Timer_GrabRing(Handle:Timer, any:Client) {
	if (IsValidEntity(g_iGrabTarget[Client]) && Build_IsClientValid(Client, Client)) {
		new Float:vOriginEntity[3];
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity);
		
		new iColor[4];
		iColor[0] = GetRandomInt(50, 255);
		iColor[1] = GetRandomInt(50, 255);
		iColor[2] = GetRandomInt(50, 255);
		iColor[3] = 255;
		
		TE_SetupBeamRingPoint(vOriginEntity, 10.0, 15.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0);
		TE_SetupBeamRingPoint(vOriginEntity, 80.0, 100.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, iColor, 5, 0);
		TE_SendToAll();
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.3, Timer_GrabRing, Client);
	}
}

public Action:Timer_GrabMain(Handle:Timer, any:Client) {
	if (IsValidEntity(g_iGrabTarget[Client]) && Build_IsClientValid(Client, Client)) {
		if (!Build_IsAdmin(Client)) {
			if (Build_ReturnEntityOwner(g_iGrabTarget[Client]) != Client) {
				g_bGrabIsRunning[Client] = false;
				return;
			}
		}
		
		new Float:vOriginEntity[3], Float:vOriginPlayer[3];
		
		GetEntPropVector(g_iGrabTarget[Client], Prop_Data, "m_vecOrigin", vOriginEntity);
		GetClientAbsOrigin(Client, vOriginPlayer);
		
		vOriginEntity[0] += vOriginPlayer[0] - g_vGrabPlayerOrigin[Client][0];
		vOriginEntity[1] += vOriginPlayer[1] - g_vGrabPlayerOrigin[Client][1];
		vOriginEntity[2] += vOriginPlayer[2] - g_vGrabPlayerOrigin[Client][2];
		
		SetEntityMoveType(g_iGrabTarget[Client], MOVETYPE_NONE);
		TeleportEntity(g_iGrabTarget[Client], vOriginEntity, NULL_VECTOR, NULL_VECTOR);
		
		if (g_bGrabIsRunning[Client])
			CreateTimer(0.001, Timer_GrabMain, Client);
		else {
			if (GetEntityFlags(g_iGrabTarget[Client]) & (FL_CLIENT | FL_FAKECLIENT))
				SetEntityMoveType(g_iGrabTarget[Client], MOVETYPE_WALK);
			else {
				SetEntityMoveType(g_iGrabTarget[Client], g_mtGrabMoveType[Client]);
			}
			DispatchKeyValue(g_iGrabTarget[Client], "rendermode", "5");
			DispatchKeyValue(g_iGrabTarget[Client], "renderamt", "255");
			DispatchKeyValue(g_iGrabTarget[Client], "renderfx", "0");
			DispatchKeyValue(g_iGrabTarget[Client], "rendercolor", "255 255 255");
		}
	}
	return;
}

// Remover.sp

public Action:Command_DeleteAll(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client))
		return Plugin_Handled;
	
	new iCheck = 0, iCount = 0;
	while (iCheck < MAX_HOOK_ENTITIES) {
		if (IsValidEntity(iCheck)) {
			if (Build_ReturnEntityOwner(iCheck) == Client) {
				for (new i = 0; i < sizeof(DelClass); i++) {
					new String:szClass[32];
					GetEdictClassname(iCheck, szClass, sizeof(szClass));
					if (StrContains(szClass, DelClass[i]) >= 0) {
						AcceptEntityInput(iCheck, "Kill", -1);
						iCount++;
					}
					Build_RegisterEntityOwner(iCheck, -1);
				}
			}
		}
		iCheck += 1;
	}
	if (iCount > 0) {
		Build_PrintToChat(Client, "Deleted all props you owns.");
	} else {
		Build_PrintToChat(Client, "You don't have any props.");
	}
	
	Build_SetLimit(Client, 0);
	Build_SetLimit(Client, 0, true);
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_delall", szArgs);
	return Plugin_Handled;
}

public Action:Command_Delete(Client, args) {
	if (!Build_AllowToUse(Client) || !Build_IsClientValid(Client, Client, true))
		return Plugin_Handled;
	
	new iEntity = Build_ClientAimEntity(Client, true, true);
	if (iEntity == -1)
		return Plugin_Handled;
	
	if (Build_IsEntityOwner(Client, iEntity)) {
		new String:szClass[33];
		GetEdictClassname(iEntity, szClass, sizeof(szClass));
		DispatchKeyValue(iEntity, "targetname", "Del_Drop");
		
		if (!Build_IsAdmin(Client)) {
			if (StrEqual(szClass, "prop_vehicle_driveable") || StrEqual(szClass, "prop_vehicle") || StrEqual(szClass, "prop_vehicle_airboat") || StrEqual(szClass, "prop_vehicle_prisoner_pod")) {
				Build_PrintToChat(Client, "You can't delete this prop!");
				return Plugin_Handled;
			}
		}
		
		new Float:vOriginPlayer[3], Float:vOriginAim[3];
		new Obj_Dissolver = CreateDissolver("3");
		
		Build_ClientAimOrigin(Client, vOriginAim);
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = vOriginPlayer[2] + 50;
		
		new random = GetRandomInt(0, 1);
		if (random == 1) {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot1.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		} else {
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginAim, iEntity, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
			EmitAmbientSound("weapons/airboat/airboat_gun_lastshot2.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, 100);
		}
		
		DispatchKeyValue(iEntity, "targetname", "Del_Target");
		
		TE_SetupBeamRingPoint(vOriginAim, 10.0, 150.0, g_Beam, g_Halo, 0, 10, 0.6, 3.0, 0.5, ColorWhite, 20, 0);
		TE_SendToAll();
		TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_PBeam, g_Halo, 0, 66, 1.0, 3.0, 3.0, 0, 0.0, ColorBlue, 20);
		TE_SendToAll();
		
		if (Build_IsAdmin(Client)) {
			if (StrEqual(szClass, "player") || StrContains(szClass, "prop_") == 0 || StrContains(szClass, "npc_") == 0 || StrContains(szClass, "weapon_") == 0 || StrContains(szClass, "item_") == 0) {
				SetVariantString("Del_Target");
				AcceptEntityInput(Obj_Dissolver, "dissolve", iEntity, Obj_Dissolver, 0);
				AcceptEntityInput(Obj_Dissolver, "kill", -1);
				DispatchKeyValue(iEntity, "targetname", "Del_Drop");
				
				new iOwner = Build_ReturnEntityOwner(iEntity);
				if (iOwner != -1) {
					if (StrEqual(szClass, "prop_ragdoll"))
						Build_SetLimit(iOwner, -1, true);
					else
						Build_SetLimit(iOwner, -1);
					Build_RegisterEntityOwner(iEntity, -1);
				}
				return Plugin_Handled;
			}
			if (!(GetEntityFlags(iEntity) & (FL_CLIENT | FL_FAKECLIENT))) {
				AcceptEntityInput(iEntity, "kill", -1);
				AcceptEntityInput(Obj_Dissolver, "kill", -1);
				return Plugin_Handled;
			}
		}
		
		if (StrEqual(szClass, "func_physbox")) {
			AcceptEntityInput(iEntity, "kill", -1);
			AcceptEntityInput(Obj_Dissolver, "kill", -1);
		} else {
			SetVariantString("Del_Target");
			AcceptEntityInput(Obj_Dissolver, "dissolve", iEntity, Obj_Dissolver, 0);
			AcceptEntityInput(Obj_Dissolver, "kill", -1);
			DispatchKeyValue(iEntity, "targetname", "Del_Drop");
		}
		
		if (StrEqual(szClass, "prop_ragdoll"))
			Build_SetLimit(Client, -1, true);
		else
			Build_SetLimit(Client, -1);
		Build_RegisterEntityOwner(iEntity, -1);
	}
	
	new String:szTemp[33], String:szArgs[128];
	for (new i = 1; i <= GetCmdArgs(); i++) {
		GetCmdArg(i, szTemp, sizeof(szTemp));
		Format(szArgs, sizeof(szArgs), "%s %s", szArgs, szTemp);
	}
	Build_Logging(Client, "sm_del", szArgs);
	return Plugin_Handled;
}

public Action:Command_DelRange(Client, args) {
	if (!Build_IsClientValid(Client, Client))
		return Plugin_Handled;
	
	new String:szCancel[32];
	GetCmdArg(1, szCancel, sizeof(szCancel));
	if (!StrEqual(szCancel, "") && (!StrEqual(g_szDelRangeStatus[Client], "off") || !StrEqual(g_szDelRangeStatus[Client], ""))) {
		Build_PrintToChat(Client, "Canceled DelRange");
		g_szDelRangeCancel[Client] = true;
		return Plugin_Handled;
	}
	
	if (StrEqual(g_szDelRangeStatus[Client], "x"))
		g_szDelRangeStatus[Client] = "y";
	else if (StrEqual(g_szDelRangeStatus[Client], "y"))
		g_szDelRangeStatus[Client] = "z";
	else if (StrEqual(g_szDelRangeStatus[Client], "z"))
		g_szDelRangeStatus[Client] = "off";
	else {
		Build_ClientAimOrigin(Client, g_fDelRangePoint1[Client]);
		g_szDelRangeStatus[Client] = "x";
		CreateTimer(0.05, Timer_DR, Client);
	}
	return Plugin_Handled;
}

public Action:Command_DelStrider(Client, args) {
	if (!Build_IsClientValid(Client, Client))
		return Plugin_Handled;
	
	new Float:fRange, String:szRange[5], Float:vOriginAim[3];
	GetCmdArg(1, szRange, sizeof(szRange));
	
	fRange = StringToFloat(szRange);
	if (fRange < 1)
		fRange = 300.0;
	if (fRange > 5000)
		fRange = 5000.0;
	
	Build_ClientAimOrigin(Client, vOriginAim);
	
	new Handle:hDataPack;
	CreateDataTimer(0.01, Timer_DScharge, hDataPack);
	WritePackCell(hDataPack, Client);
	WritePackFloat(hDataPack, fRange);
	WritePackFloat(hDataPack, vOriginAim[0]);
	WritePackFloat(hDataPack, vOriginAim[1]);
	WritePackFloat(hDataPack, vOriginAim[2]);
	return Plugin_Handled;
}

public Action:Command_DelStrider2(Client, args) {
	if (!Build_IsClientValid(Client, Client))
		return Plugin_Handled;
	
	new Float:fRange, String:szRange[5], Float:vOriginAim[3];
	GetCmdArg(1, szRange, sizeof(szRange));
	
	fRange = StringToFloat(szRange);
	if (fRange < 1)
		fRange = 300.0;
	if (fRange > 5000)
		fRange = 5000.0;
	
	Build_ClientAimOrigin(Client, vOriginAim);
	
	new Handle:hDataPack;
	CreateDataTimer(0.01, Timer_DScharge2, hDataPack);
	WritePackCell(hDataPack, Client);
	WritePackFloat(hDataPack, fRange);
	WritePackFloat(hDataPack, vOriginAim[0]);
	WritePackFloat(hDataPack, vOriginAim[1]);
	WritePackFloat(hDataPack, vOriginAim[2]);
	return Plugin_Handled;
}


public Action:Timer_DR(Handle:Timer, any:Client) {
	if (!Build_IsClientValid(Client, Client))
		return;
	if (g_szDelRangeCancel[Client]) {
		g_szDelRangeCancel[Client] = false;
		g_szDelRangeStatus[Client] = "off";
		return;
	}
	
	new Float:vPoint2[3], Float:vPoint3[3], Float:vPoint4[3];
	new Float:vClonePoint1[3], Float:vClonePoint2[3], Float:vClonePoint3[3], Float:vClonePoint4[3];
	new Float:vOriginAim[3], Float:vOriginPlayer[3];
	
	if (StrEqual(g_szDelRangeStatus[Client], "x")) {
		Build_ClientAimOrigin(Client, vOriginAim);
		vPoint2[0] = vOriginAim[0];
		vPoint2[1] = vOriginAim[1];
		vPoint2[2] = g_fDelRangePoint1[Client][2];
		vClonePoint1[0] = g_fDelRangePoint1[Client][0];
		vClonePoint1[1] = vPoint2[1];
		vClonePoint1[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2);
		vClonePoint2[0] = vPoint2[0];
		vClonePoint2[1] = g_fDelRangePoint1[Client][1];
		vClonePoint2[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2);
		
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = (vOriginPlayer[2] + 50);
		
		DrowLine(vClonePoint1, g_fDelRangePoint1[Client], ColorRed);
		DrowLine(vClonePoint2, g_fDelRangePoint1[Client], ColorRed);
		DrowLine(vPoint2, vClonePoint1, ColorRed);
		DrowLine(vPoint2, vClonePoint2, ColorRed);
		DrowLine(vPoint2, vOriginAim, ColorBlue);
		DrowLine(vOriginAim, vOriginPlayer, ColorBlue);
		
		g_fDelRangePoint2[Client] = vPoint2;
		CreateTimer(0.001, Timer_DR, Client);
	} else if (StrEqual(g_szDelRangeStatus[Client], "y")) {
		Build_ClientAimOrigin(Client, vOriginAim);
		vPoint2[0] = g_fDelRangePoint2[Client][0];
		vPoint2[1] = g_fDelRangePoint2[Client][1];
		vPoint2[2] = g_fDelRangePoint1[Client][2];
		vClonePoint1[0] = g_fDelRangePoint1[Client][0];
		vClonePoint1[1] = vPoint2[1];
		vClonePoint1[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2);
		vClonePoint2[0] = vPoint2[0];
		vClonePoint2[1] = g_fDelRangePoint1[Client][1];
		vClonePoint2[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2);
		
		vPoint3[0] = g_fDelRangePoint1[Client][0];
		vPoint3[1] = g_fDelRangePoint1[Client][1];
		vPoint3[2] = vOriginAim[2];
		vPoint4[0] = vPoint2[0];
		vPoint4[1] = vPoint2[1];
		vPoint4[2] = vOriginAim[2];
		vClonePoint3[0] = vClonePoint1[0];
		vClonePoint3[1] = vClonePoint1[1];
		vClonePoint3[2] = vOriginAim[2];
		vClonePoint4[0] = vClonePoint2[0];
		vClonePoint4[1] = vClonePoint2[1];
		vClonePoint4[2] = vOriginAim[2];
		
		GetClientAbsOrigin(Client, vOriginPlayer);
		vOriginPlayer[2] = (vOriginPlayer[2] + 50);
		
		DrowLine(vClonePoint1, g_fDelRangePoint1[Client], ColorRed);
		DrowLine(vClonePoint2, g_fDelRangePoint1[Client], ColorRed);
		DrowLine(vPoint2, vClonePoint1, ColorRed);
		DrowLine(vPoint2, vClonePoint2, ColorRed);
		DrowLine(vPoint3, vClonePoint3, ColorRed);
		DrowLine(vPoint3, vClonePoint4, ColorRed);
		DrowLine(vPoint4, vClonePoint3, ColorRed);
		DrowLine(vPoint4, vClonePoint4, ColorRed);
		DrowLine(vPoint3, g_fDelRangePoint1[Client], ColorRed);
		DrowLine(vPoint4, vPoint2, ColorRed);
		DrowLine(vClonePoint1, vClonePoint3, ColorRed);
		DrowLine(vClonePoint2, vClonePoint4, ColorRed);
		DrowLine(vPoint4, vOriginAim, ColorBlue);
		DrowLine(vOriginAim, vOriginPlayer, ColorBlue);
		
		g_fDelRangePoint3[Client] = vPoint4;
		CreateTimer(0.001, Timer_DR, Client);
	} else if (StrEqual(g_szDelRangeStatus[Client], "z")) {
		vPoint2[0] = g_fDelRangePoint2[Client][0];
		vPoint2[1] = g_fDelRangePoint2[Client][1];
		vPoint2[2] = g_fDelRangePoint1[Client][2];
		vClonePoint1[0] = g_fDelRangePoint1[Client][0];
		vClonePoint1[1] = vPoint2[1];
		vClonePoint1[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2);
		vClonePoint2[0] = vPoint2[0];
		vClonePoint2[1] = g_fDelRangePoint1[Client][1];
		vClonePoint2[2] = ((g_fDelRangePoint1[Client][2] + vPoint2[2]) / 2);
		
		vPoint3[0] = g_fDelRangePoint1[Client][0];
		vPoint3[1] = g_fDelRangePoint1[Client][1];
		vPoint3[2] = g_fDelRangePoint3[Client][2];
		vClonePoint3[0] = vClonePoint1[0];
		vClonePoint3[1] = vClonePoint1[1];
		vClonePoint3[2] = g_fDelRangePoint3[Client][2];
		vClonePoint4[0] = vClonePoint2[0];
		vClonePoint4[1] = vClonePoint2[1];
		vClonePoint4[2] = g_fDelRangePoint3[Client][2];
		
		DrowLine(g_fDelRangePoint1[Client], vClonePoint1, ColorGreen);
		DrowLine(g_fDelRangePoint1[Client], vClonePoint2, ColorGreen);
		DrowLine(vPoint2, vClonePoint1, ColorGreen);
		DrowLine(vPoint2, vClonePoint2, ColorGreen);
		DrowLine(vPoint3, vClonePoint3, ColorGreen);
		DrowLine(vPoint3, vClonePoint4, ColorGreen);
		DrowLine(g_fDelRangePoint3[Client], vClonePoint3, ColorGreen);
		DrowLine(g_fDelRangePoint3[Client], vClonePoint4, ColorGreen);
		DrowLine(vPoint3, g_fDelRangePoint1[Client], ColorGreen);
		DrowLine(vPoint2, g_fDelRangePoint3[Client], ColorGreen);
		DrowLine(vPoint2, vClonePoint1, ColorGreen);
		DrowLine(vPoint2, vClonePoint1, ColorGreen);
		TE_SetupBeamPoints(vPoint3, g_fDelRangePoint1[Client], g_Beam, g_Halo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, ColorGreen, 20);
		TE_SendToAll();
		TE_SetupBeamPoints(g_fDelRangePoint3[Client], vPoint2, g_Beam, g_Halo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, ColorGreen, 20);
		TE_SendToAll();
		TE_SetupBeamPoints(vClonePoint3, vClonePoint1, g_Beam, g_Halo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, ColorGreen, 20);
		TE_SendToAll();
		TE_SetupBeamPoints(vClonePoint4, vClonePoint2, g_Beam, g_Halo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, ColorGreen, 20);
		TE_SendToAll();
		
		CreateTimer(0.001, Timer_DR, Client);
	} else {
		vPoint2[0] = g_fDelRangePoint2[Client][0];
		vPoint2[1] = g_fDelRangePoint2[Client][1];
		vPoint2[2] = g_fDelRangePoint1[Client][2];
		vPoint3[0] = g_fDelRangePoint1[Client][0];
		vPoint3[1] = g_fDelRangePoint1[Client][1];
		vPoint3[2] = g_fDelRangePoint3[Client][2];
		
		vClonePoint1[0] = g_fDelRangePoint1[Client][0];
		vClonePoint1[1] = vPoint2[1];
		vClonePoint1[2] = g_fDelRangePoint1[Client][2];
		vClonePoint2[0] = vPoint2[0];
		vClonePoint2[1] = g_fDelRangePoint1[Client][1];
		vClonePoint2[2] = vPoint2[2];
		vClonePoint3[0] = vClonePoint1[0];
		vClonePoint3[1] = vClonePoint1[1];
		vClonePoint3[2] = g_fDelRangePoint3[Client][2];
		vClonePoint4[0] = vClonePoint2[0];
		vClonePoint4[1] = vClonePoint2[1];
		vClonePoint4[2] = g_fDelRangePoint3[Client][2];
		
		DrowLine(vClonePoint1, g_fDelRangePoint1[Client], ColorWhite, true);
		DrowLine(vClonePoint2, g_fDelRangePoint1[Client], ColorWhite, true);
		DrowLine(vClonePoint3, g_fDelRangePoint3[Client], ColorWhite, true);
		DrowLine(vClonePoint4, g_fDelRangePoint3[Client], ColorWhite, true);
		DrowLine(vPoint2, vClonePoint1, ColorWhite, true);
		DrowLine(vPoint2, vClonePoint2, ColorWhite, true);
		DrowLine(vPoint3, vClonePoint3, ColorWhite, true);
		DrowLine(vPoint3, vClonePoint4, ColorWhite, true);
		DrowLine(vPoint2, g_fDelRangePoint3[Client], ColorWhite, true);
		DrowLine(vPoint3, g_fDelRangePoint1[Client], ColorWhite, true);
		DrowLine(vClonePoint1, vClonePoint3, ColorWhite, true);
		DrowLine(vClonePoint2, vClonePoint4, ColorWhite, true);
		
		new Obj_Dissolver = CreateEntityByName("env_entity_dissolver");
		DispatchKeyValue(Obj_Dissolver, "dissolvetype", "3");
		DispatchKeyValue(Obj_Dissolver, "targetname", "Del_Dissolver");
		DispatchSpawn(Obj_Dissolver);
		ActivateEntity(Obj_Dissolver);
		
		new Float:vOriginEntity[3], String:szClass[32];
		new iCount = 0;
		new iEntity = -1;
		for (new i = 0; i < sizeof(EntityType); i++) {
			while ((iEntity = FindEntityByClassname(iEntity, EntityType[i])) != -1) {
				GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vOriginEntity);
				vOriginEntity[2] += 1;
				if (vOriginEntity[0] != 0 && vOriginEntity[1] != 1 && vOriginEntity[2] != 0 && Build_IsInSquare(vOriginEntity, g_fDelRangePoint1[Client], g_fDelRangePoint3[Client])) {
					GetEdictClassname(iEntity, szClass, sizeof(szClass));
					if (StrEqual(szClass, "func_physbox"))
						AcceptEntityInput(iEntity, "kill", -1);
					else {
						DispatchKeyValue(iEntity, "targetname", "Del_Target");
						SetVariantString("Del_Target");
						AcceptEntityInput(Obj_Dissolver, "dissolve", iEntity, Obj_Dissolver, 0);
						DispatchKeyValue(iEntity, "targetname", "Del_Drop");
					}
					
					new iOwner = Build_ReturnEntityOwner(iEntity);
					if (iOwner != -1) {
						if (StrEqual(szClass, "prop_ragdoll"))
							Build_SetLimit(iOwner, -1, true);
						else
							Build_SetLimit(iOwner, -1);
						
						Build_RegisterEntityOwner(iEntity, -1);
					}
				}
			}
		}
		AcceptEntityInput(Obj_Dissolver, "kill", -1);
		
		if (iCount > 0)
			Build_PrintToChat(Client, "Deleted %i props.", iCount);
	}
}

public Action:Timer_DScharge(Handle:Timer, Handle:hDataPack) {
	new Float:vOriginAim[3], Float:vOriginPlayer[3];
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new Float:fRange = ReadPackFloat(hDataPack);
	vOriginAim[0] = ReadPackFloat(hDataPack);
	vOriginAim[1] = ReadPackFloat(hDataPack);
	vOriginAim[2] = ReadPackFloat(hDataPack);
	
	GetClientAbsOrigin(Client, vOriginPlayer);
	vOriginPlayer[2] = (vOriginPlayer[2] + 50);
	
	EmitAmbientSound("npc/strider/charging.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	
	new Obj_Push = CreatePush(vOriginAim, -1000.0, fRange, "20");
	AcceptEntityInput(Obj_Push, "enable", -1);
	
	new Obj_Core = CreateCore(vOriginAim, 5.0, "1");
	AcceptEntityInput(Obj_Core, "startdischarge", -1);
	/*
	new String:szPointTeslaName[128], String:szThickMin[64], String:szThickMax[64], String:szOnUser[128], String:szKill[64];
	new Obj_PointTesla = CreateEntityByName("point_tesla");
	TeleportEntity(Obj_PointTesla, vOriginAim, NULL_VECTOR, NULL_VECTOR);
	Format(szPointTeslaName, sizeof(szPointTeslaName), "szTesla%i", GetRandomInt(1000, 5000));
	new Float:fThickMin = StringToFloat(szRange) / 40;
	new Float:iThickMax = StringToFloat(szRange) / 30;
	Format(szThickMin, sizeof(szThickMin), "%i", RoundToFloor(fThickMin));
	Format(szThickMax, sizeof(szThickMax), "%i", RoundToFloor(iThickMax));
	
	DispatchKeyValue(Obj_PointTesla, "targetname", szPointTeslaName);
	DispatchKeyValue(Obj_PointTesla, "sprite", "sprites/physbeam.vmt");
	DispatchKeyValue(Obj_PointTesla, "m_color", "255 255 255");
	DispatchKeyValue(Obj_PointTesla, "m_flradius", szRange);
	DispatchKeyValue(Obj_PointTesla, "beamcount_min", "100");
	DispatchKeyValue(Obj_PointTesla, "beamcount_max", "500");
	DispatchKeyValue(Obj_PointTesla, "thick_min", szThickMin);
	DispatchKeyValue(Obj_PointTesla, "thick_max", szThickMax);
	DispatchKeyValue(Obj_PointTesla, "lifetime_min", "0.1");
	DispatchKeyValue(Obj_PointTesla, "lifetime_max", "0.1");
	
	new Float:f;
	for (f = 0.0; f < 1.3; f=f+0.05) {
		Format(szOnUser, sizeof(szOnUser), "%s,dospark,,%f", szPointTeslaName, f);
		DispatchKeyValue(Obj_PointTesla, "onuser1", szOnUser);
	}
	Format(szKill, sizeof(szKill), "%s,kill,,1.3", szPointTeslaName);
	DispatchSpawn(Obj_PointTesla);
	DispatchKeyValue(Obj_PointTesla, "onuser1", szKill);
	AcceptEntityInput(Obj_PointTesla, "fireuser1", -1);
	*/
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, ColorBlue, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	new Handle:hNewPack;
	CreateDataTimer(1.3, Timer_DSfire, hNewPack);
	WritePackCell(hNewPack, Client);
	WritePackCell(hNewPack, Obj_Push);
	WritePackCell(hNewPack, Obj_Core);
	WritePackFloat(hNewPack, fRange);
	WritePackFloat(hNewPack, vOriginAim[0]);
	WritePackFloat(hNewPack, vOriginAim[1]);
	WritePackFloat(hNewPack, vOriginAim[2]);
	WritePackFloat(hNewPack, vOriginPlayer[0]);
	WritePackFloat(hNewPack, vOriginPlayer[1]);
	WritePackFloat(hNewPack, vOriginPlayer[2]);
}

public Action:Timer_DSfire(Handle:Timer, Handle:hDataPack) {
	new Float:vOriginAim[3], Float:vOriginPlayer[3];
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new Obj_Push = ReadPackCell(hDataPack);
	new Obj_Core = ReadPackCell(hDataPack);
	new Float:fRange = ReadPackFloat(hDataPack);
	vOriginAim[0] = ReadPackFloat(hDataPack);
	vOriginAim[1] = ReadPackFloat(hDataPack);
	vOriginAim[2] = ReadPackFloat(hDataPack);
	vOriginPlayer[0] = ReadPackFloat(hDataPack);
	vOriginPlayer[1] = ReadPackFloat(hDataPack);
	vOriginPlayer[2] = ReadPackFloat(hDataPack);
	
	if (IsValidEntity(Obj_Push))
		AcceptEntityInput(Obj_Push, "kill", -1);
	if (IsValidEntity(Obj_Core))
		AcceptEntityInput(Obj_Core, "kill", -1);
	
	EmitAmbientSound("npc/strider/fire.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, ColorRed, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	new Obj_Dissolver = CreateDissolver("3");
	new Float:vOriginEntity[3];
	new iCount = 0;
	new iEntity = -1;
	for (new i = 0; i < sizeof(EntityType); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, EntityType[i])) != -1) {
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vOriginEntity);
			vOriginEntity[2] += 1;
			new String:szClass[33];
			GetEdictClassname(iEntity, szClass, sizeof(szClass));
			if (vOriginEntity[0] != 0 && vOriginEntity[1] != 1 && vOriginEntity[2] != 0 && !StrEqual(szClass, "player") && Build_IsInRange(vOriginEntity, vOriginAim, fRange)) {
				if (StrEqual(szClass, "func_physbox"))
					AcceptEntityInput(iEntity, "kill", -1);
				else {
					DispatchKeyValue(iEntity, "targetname", "Del_Target");
					SetVariantString("Del_Target");
					AcceptEntityInput(Obj_Dissolver, "dissolve", iEntity, Obj_Dissolver, 0);
					DispatchKeyValue(iEntity, "targetname", "Del_Drop");
				}
				
				new iOwner = Build_ReturnEntityOwner(iEntity);
				if (iOwner != -1) {
					if (StrEqual(szClass, "prop_ragdoll"))
						Build_SetLimit(iOwner, -1, true);
					else
						Build_SetLimit(iOwner, -1);
					
					Build_RegisterEntityOwner(iEntity, -1);
				}
				iCount++;
			}
		}
	}
	AcceptEntityInput(Obj_Dissolver, "kill", -1);
	if (iCount > 0 && Build_IsClientValid(Client, Client))
		Build_PrintToChat(Client, "Deleted %i props.", iCount);
}

public Action:Timer_DScharge2(Handle:Timer, Handle:hDataPack) {
	new Float:vOriginAim[3], Float:vOriginPlayer[3];
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new Float:fRange = ReadPackFloat(hDataPack);
	vOriginAim[0] = ReadPackFloat(hDataPack);
	vOriginAim[1] = ReadPackFloat(hDataPack);
	vOriginAim[2] = ReadPackFloat(hDataPack);
	
	GetClientAbsOrigin(Client, vOriginPlayer);
	vOriginPlayer[2] = (vOriginPlayer[2] + 50);
	
	EmitAmbientSound("npc/strider/charging.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/charging.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.3);
	
	new Obj_Push = CreatePush(vOriginAim, -1000.0, fRange, "28");
	AcceptEntityInput(Obj_Push, "enable", -1);
	
	new Obj_Core = CreateCore(vOriginAim, 5.0, "1");
	AcceptEntityInput(Obj_Core, "startdischarge", -1);
	
	/*new Float:vOriginEntity[3], String:szClass[32];
	new iEntity = -1;
	for (new i = 0; i < sizeof(EntityType); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, EntityType[i])) != -1) {
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vOriginEntity);
			vOriginEntity[2] = (vOriginEntity[2] + 1);
			if (Phys_IsPhysicsObject(iEntity)) {
				GetEdictClassname(iEntity, szClass, sizeof(szClass));
				if (Build_IsInRange(vOriginEntity, vOriginAim, fRange)) {
					Phys_EnableMotion(iEntity, true);
					if (StrEqual(szClass, "player"))
						SetEntityMoveType(iEntity, MOVETYPE_WALK);
					else
						SetEntityMoveType(iEntity, MOVETYPE_VPHYSICS);
				}
			}
		}
	}
	
	new String:szPointTeslaName[128], String:szThickMin[64], String:szThickMax[64], String:szOnUser[128], String:szKill[64];
	new Obj_PointTesla = CreateEntityByName("point_tesla");
	TeleportEntity(Obj_PointTesla, vOriginAim, NULL_VECTOR, NULL_VECTOR);
	Format(szPointTeslaName, sizeof(szPointTeslaName), "szTesla%i", GetRandomInt(1000, 5000));
	new Float:fThickMin = StringToFloat(szRange) / 40;
	new Float:iThickMax = StringToFloat(szRange) / 30;
	Format(szThickMin, sizeof(szThickMin), "%i", RoundToFloor(fThickMin));
	Format(szThickMax, sizeof(szThickMax), "%i", RoundToFloor(iThickMax));
	
	DispatchKeyValue(Obj_PointTesla, "targetname", szPointTeslaName);
	DispatchKeyValue(Obj_PointTesla, "sprite", "sprites/physbeam.vmt");
	DispatchKeyValue(Obj_PointTesla, "m_color", "255 255 255");
	DispatchKeyValue(Obj_PointTesla, "m_flradius", szRange);
	DispatchKeyValue(Obj_PointTesla, "beamcount_min", "100");
	DispatchKeyValue(Obj_PointTesla, "beamcount_max", "500");
	DispatchKeyValue(Obj_PointTesla, "thick_min", szThickMin);
	DispatchKeyValue(Obj_PointTesla, "thick_max", szThickMax);
	DispatchKeyValue(Obj_PointTesla, "lifetime_min", "0.1");
	DispatchKeyValue(Obj_PointTesla, "lifetime_max", "0.1");
	
	new Float:f;
	for (f = 0.0; f < 1.3; f=f+0.05) {
		Format(szOnUser, sizeof(szOnUser), "%s,dospark,,%f", szPointTeslaName, f);
		DispatchKeyValue(Obj_PointTesla, "onuser1", szOnUser);
	}
	Format(szKill, sizeof(szKill), "%s,kill,,1.3", szPointTeslaName);
	DispatchSpawn(Obj_PointTesla);
	DispatchKeyValue(Obj_PointTesla, "onuser1", szKill);
	AcceptEntityInput(Obj_PointTesla, "fireuser1", -1);
	*/
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 1.3, 15.0, 15.0, 0, 0.0, ColorBlue, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 1.3, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	new Handle:hNewPack;
	CreateDataTimer(1.3, Timer_DSfire2, hNewPack);
	WritePackCell(hNewPack, Client);
	WritePackCell(hNewPack, Obj_Push);
	WritePackCell(hNewPack, Obj_Core);
	WritePackFloat(hNewPack, fRange);
	WritePackFloat(hNewPack, vOriginAim[0]);
	WritePackFloat(hNewPack, vOriginAim[1]);
	WritePackFloat(hNewPack, vOriginAim[2]);
	WritePackFloat(hNewPack, vOriginPlayer[0]);
	WritePackFloat(hNewPack, vOriginPlayer[1]);
	WritePackFloat(hNewPack, vOriginPlayer[2]);
}

public Action:Timer_DSfire2(Handle:Timer, Handle:hDataPack) {
	new Float:vOriginAim[3], Float:vOriginPlayer[3];
	ResetPack(hDataPack);
	new Client = ReadPackCell(hDataPack);
	new Obj_Push = ReadPackCell(hDataPack);
	new Obj_Core = ReadPackCell(hDataPack);
	new Float:fRange = ReadPackFloat(hDataPack);
	vOriginAim[0] = ReadPackFloat(hDataPack);
	vOriginAim[1] = ReadPackFloat(hDataPack);
	vOriginAim[2] = ReadPackFloat(hDataPack);
	vOriginPlayer[0] = ReadPackFloat(hDataPack);
	vOriginPlayer[1] = ReadPackFloat(hDataPack);
	vOriginPlayer[2] = ReadPackFloat(hDataPack);
	
	if (IsValidEntity(Obj_Push))
		AcceptEntityInput(Obj_Push, "kill", -1);
	if (IsValidEntity(Obj_Core))
		AcceptEntityInput(Obj_Core, "kill", -1);
	
	EmitAmbientSound("npc/strider/fire.wav", vOriginAim, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	EmitAmbientSound("npc/strider/fire.wav", vOriginPlayer, Client, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 0.2, 15.0, 15.0, 0, 0.0, ColorRed, 20);
	TE_SendToAll();
	TE_SetupBeamPoints(vOriginAim, vOriginPlayer, g_Beam, g_Halo, 0, 66, 0.2, 20.0, 20.0, 0, 0.0, ColorWhite, 20);
	TE_SendToAll();
	
	new Obj_Dissolver = CreateDissolver("3");
	new Float:vOriginEntity[3];
	new iCount = 0;
	new iEntity = -1;
	for (new i = 0; i < sizeof(EntityType); i++) {
		while ((iEntity = FindEntityByClassname(iEntity, EntityType[i])) != -1) {
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vOriginEntity);
			vOriginEntity[2] += 1;
			new String:szClass[33];
			GetEdictClassname(iEntity, szClass, sizeof(szClass));
			if (vOriginEntity[0] != 0 && vOriginEntity[1] != 1 && vOriginEntity[2] != 0 && Build_IsInRange(vOriginEntity, vOriginAim, fRange)) {
				if (StrEqual(szClass, "func_physbox"))
					AcceptEntityInput(iEntity, "kill", -1);
				else {
					DispatchKeyValue(iEntity, "targetname", "Del_Target");
					SetVariantString("Del_Target");
					AcceptEntityInput(Obj_Dissolver, "dissolve", iEntity, Obj_Dissolver, 0);
					DispatchKeyValue(iEntity, "targetname", "Del_Drop");
				}
				new iOwner = Build_ReturnEntityOwner(iEntity);
				if (iOwner != -1) {
					if (StrEqual(szClass, "prop_ragdoll"))
						Build_SetLimit(iOwner, -1, true);
					else
						Build_SetLimit(iOwner, -1);
					
					Build_RegisterEntityOwner(iEntity, -1);
				}
				iCount++;
			}
		}
	}
	AcceptEntityInput(Obj_Dissolver, "kill", -1);
	if (iCount > 0 && Build_IsClientValid(Client, Client))
		Build_PrintToChat(Client, "Deleted %i props.", iCount);
}

public OnPropBreak(const String:output[], iEntity, iActivator, Float:delay) {
	if (IsValidEntity(iEntity))
		CreateTimer(0.1, Timer_PropBreak, iEntity);
}

public Action:Timer_PropBreak(Handle:Timer, any:iEntity) {
	if (!IsValidEntity(iEntity))
		return;
	new iOwner = Build_ReturnEntityOwner(iEntity);
	if (iOwner > 0) {
		Build_SetLimit(iOwner, -1);
		Build_RegisterEntityOwner(iEntity, -1);
		AcceptEntityInput(iEntity, "kill", -1);
	}
}

stock DrowLine(Float:vPoint1[3], Float:vPoint2[3], Color[4], bool:bFinale = false) {
	if (bFinale)
		TE_SetupBeamPoints(vPoint1, vPoint2, g_Beam, g_Halo, 0, 66, 0.5, 7.0, 7.0, 0, 0.0, Color, 20);
	else
		TE_SetupBeamPoints(vPoint1, vPoint2, g_Beam, g_Halo, 0, 66, 0.15, 7.0, 7.0, 0, 0.0, Color, 20);
	TE_SendToAll();
}

stock CreatePush(Float:vOrigin[3], Float:fMagnitude, Float:fRange, String:szSpawnFlags[8]) {
	new Push_Index = CreateEntityByName("point_push");
	TeleportEntity(Push_Index, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValueFloat(Push_Index, "magnitude", fMagnitude);
	DispatchKeyValueFloat(Push_Index, "radius", fRange);
	DispatchKeyValueFloat(Push_Index, "inner_radius", fRange);
	DispatchKeyValue(Push_Index, "spawnflags", szSpawnFlags);
	DispatchSpawn(Push_Index);
	return Push_Index;
}

stock CreateCore(Float:vOrigin[3], Float:fScale, String:szSpawnFlags[8]) {
	new Core_Index = CreateEntityByName("env_citadel_energy_core");
	TeleportEntity(Core_Index, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValueFloat(Core_Index, "scale", fScale);
	DispatchKeyValue(Core_Index, "spawnflags", szSpawnFlags);
	DispatchSpawn(Core_Index);
	return Core_Index;
}

stock CreateDissolver(String:szDissolveType[4]) {
	new Dissolver_Index = CreateEntityByName("env_entity_dissolver");
	DispatchKeyValue(Dissolver_Index, "dissolvetype", szDissolveType);
	DispatchKeyValue(Dissolver_Index, "targetname", "Del_Dissolver");
	DispatchSpawn(Dissolver_Index);
	return Dissolver_Index;
}

// SimpleMenu.sp

public Action:Command_BuildMenu(client, args)
{
	if (client > 0)
	{
		DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public Action:Command_Resupply(client, args)
{
	Build_PrintToChat(client, "You're now resupplied.");
	TF2_RegeneratePlayer(client);
}

public MainMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		
		if (StrEqual(item, "spawnlist"))
		{
			DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "equipmenu"))
		{
			DisplayMenu(g_hEquipMenu, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "playerstuff"))
		{
			DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "buildhelper"))
		{
			DisplayMenu(g_hBuildHelperMenu, param1, MENU_TIME_FOREVER);
		}
		
	}
}

public PropMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuAtItem(g_hPropMenu, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		//DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
		decl String:info[255];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "removeprops"))
		{
			DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "constructprops"))
		{
			DisplayMenu(g_hPropMenuConstructions, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "comicprops"))
		{
			DisplayMenu(g_hPropMenuComic, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "weaponsprops"))
		{
			DisplayMenu(g_hPropMenuWeapons, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "pickupprops"))
		{
			DisplayMenu(g_hPropMenuPickup, param1, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "hl2props"))
		{
			DisplayMenu(g_hPropMenuHL2, param1, MENU_TIME_FOREVER);
		}
		else
		{
			FakeClientCommand(param1, "sm_prop %s", info);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hMainMenu, param1, MENU_TIME_FOREVER);
	}
}

public CondMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenu(g_hCondMenu, param1, MENU_TIME_FOREVER);
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		
		if (StrEqual(item, "crits"))
		{
			if (TF2_IsPlayerInCondition(param1, TFCond_CritCanteen))
			{
				Build_PrintToChat(param1, "Crit Cond OFF");
				TF2_RemoveCondition(param1, TFCond_CritCanteen);
			}
			else
			{
				Build_PrintToChat(param1, "Crit Cond ON");
				TF2_AddCondition(param1, TFCond_CritCanteen, TFCondDuration_Infinite, 0);
			}
		}
		
		/*if (StrEqual(item, "infammo"))
		{
			Build_PrintToChat(param1, "Learn more at !aiamenu");
		}
		
		if (StrEqual(item, "infclip"))
		{
			Build_PrintToChat(param1, "Learn more at !aiamenu");
		}*/
		
		if (StrEqual(item, "resupply"))
		{
			TF2_RegeneratePlayer(param1);
		}
		
		if (StrEqual(item, "noclip"))
		{
			FakeClientCommand(param1, "sm_fly");
		}
		
		/*if (StrEqual(item, "buddha"))
		{
			FakeClientCommand(param1, "sm_buddha");				
		}*/
		
		if (StrEqual(item, "fly"))
		{
			if (!Build_AllowToUse(param1) || !Build_IsClientValid(param1, param1, true) || !Build_AllowFly(param1))
				return 0;
			
			if (GetEntityMoveType(param1) != MOVETYPE_FLY)
			{
				Build_PrintToChat(param1, "Fly ON");
				SetEntityMoveType(param1, MOVETYPE_FLY);
			}
			else
			{
				Build_PrintToChat(param1, "Fly OFF");
				SetEntityMoveType(param1, MOVETYPE_WALK);
			}
		}
		
		if (StrEqual(item, "minicrits"))
		{
			if (TF2_IsPlayerInCondition(param1, TFCond_NoHealingDamageBuff))
			{
				Build_PrintToChat(param1, "Mini-Crits OFF");
				TF2_RemoveCondition(param1, TFCond_NoHealingDamageBuff);
			}
			else
			{
				Build_PrintToChat(param1, "Mini-Crits ON");
				TF2_AddCondition(param1, TFCond_NoHealingDamageBuff, TFCondDuration_Infinite, 0);
			}
		}
		
		if (StrEqual(item, "damagereduce"))
		{
			if (TF2_IsPlayerInCondition(param1, TFCond_DefenseBuffNoCritBlock))
			{
				Build_PrintToChat(param1, "Damage Reduction OFF");
				TF2_RemoveCondition(param1, TFCond_DefenseBuffNoCritBlock);
			}
			else
			{
				Build_PrintToChat(param1, "Damage Reduction ON");
				TF2_AddCondition(param1, TFCond_DefenseBuffNoCritBlock, TFCondDuration_Infinite, 0);
			}
		}
		
		if (StrEqual(item, "speedboost"))
		{
			if (TF2_IsPlayerInCondition(param1, TFCond_HalloweenSpeedBoost))
			{
				Build_PrintToChat(param1, "Speed Boost OFF");
				TF2_RemoveCondition(param1, TFCond_HalloweenSpeedBoost);
			}
			else
			{
				Build_PrintToChat(param1, "Speed Boost ON");
				TF2_AddCondition(param1, TFCond_HalloweenSpeedBoost, TFCondDuration_Infinite, 0);
			}
		}
		
		if (StrEqual(item, "removeweps"))
		{
			TF2_RemoveAllWeapons(param1);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
	}
	return 0;
}

public PlayerStuff(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		
		if (StrEqual(item, "cond"))
		{
			DisplayMenu(g_hCondMenu, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "sizes"))
		{
			Build_PrintToChat(param1, "Not yet implemented");
			DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "health"))
		{
			Build_PrintToChat(param1, "Not yet implemented");
			DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "speed"))
		{
			Build_PrintToChat(param1, "Not yet implemented");
			DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "model"))
		{
			Build_PrintToChat(param1, "Not yet implemented");
			DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
		}
		
		if (StrEqual(item, "pitch"))
		{
			Build_PrintToChat(param1, "Not yet implemented");
			DisplayMenu(g_hPlayerStuff, param1, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hMainMenu, param1, MENU_TIME_FOREVER);
	}
}

public EquipMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenu(g_hEquipMenu, param1, MENU_TIME_FOREVER);
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		
		/*if (StrEqual(item, "portalgun"))
		{
				FakeClientCommand(param1, "sm_portalgun");
		}*/
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hMainMenu, param1, MENU_TIME_FOREVER);
	}
}

public RemoveMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		
		if (StrEqual(item, "remove"))
		{
			FakeClientCommand(param1, "sm_del");
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
	}
}

public BuildHelperMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenu(g_hBuildHelperMenu, param1, MENU_TIME_FOREVER);
		new String:item[64];
		GetMenuItem(menu, param2, item, sizeof(item));
		
		if (StrEqual(item, "delprop"))
		{
			FakeClientCommand(param1, "sm_del");
		}
		else if (StrEqual(item, "colors"))
		{
			FakeClientCommand(param1, "sm_color");
		}
		else if (StrEqual(item, "effects"))
		{
			FakeClientCommand(param1, "sm_render");
		}
		else if (StrEqual(item, "skin"))
		{
			FakeClientCommand(param1, "sm_skin");
		}
		else if (StrEqual(item, "rotate"))
		{
			FakeClientCommand(param1, "sm_rotate");
		}
		else if (StrEqual(item, "accuraterotate"))
		{
			FakeClientCommand(param1, "sm_accuraterotate");
		}
		else if (StrEqual(item, "lights"))
		{
			FakeClientCommand(param1, "sm_simplelight");
		}
		else if (StrEqual(item, "doors"))
		{
			FakeClientCommand(param1, "sm_propdoor");
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hMainMenu, param1, MENU_TIME_FOREVER);
	}
}

public PropMenuHL2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuAtItem(g_hPropMenuHL2, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		//DisplayMenu(g_hPropMenuPickup, param1, MENU_TIME_FOREVER);
		decl String:info[255];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "removeprops"))
		{
			DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			FakeClientCommand(param1, "sm_prop %s", info);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
	}
}

public PropMenuConstructions(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuAtItem(g_hPropMenuConstructions, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		//DisplayMenu(g_hPropMenuConstructions, param1, MENU_TIME_FOREVER);
		decl String:info[255];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "removeprops"))
		{
			DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			FakeClientCommand(param1, "sm_prop %s", info);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
	}
}

public PropMenuComics(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuAtItem(g_hPropMenuComic, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		//DisplayMenu(g_hPropMenuComic, param1, MENU_TIME_FOREVER);
		decl String:info[255];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "removeprops"))
		{
			DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			FakeClientCommand(param1, "sm_prop %s", info);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
	}
}

public PropMenuWeapons(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuAtItem(g_hPropMenuWeapons, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		//DisplayMenu(g_hPropMenuWeapons, param1, MENU_TIME_FOREVER);
		decl String:info[255];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "removeprops"))
		{
			DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			FakeClientCommand(param1, "sm_prop %s", info);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
	}
}

public PropMenuPickup(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select && IsClientInGame(param1))
	{
		DisplayMenuAtItem(g_hPropMenuPickup, param1, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		//DisplayMenu(g_hPropMenuPickup, param1, MENU_TIME_FOREVER);
		decl String:info[255];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "removeprops"))
		{
			DisplayMenu(g_hRemoveMenu, param1, MENU_TIME_FOREVER);
		}
		else
		{
			FakeClientCommand(param1, "sm_prop %s", info);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && IsClientInGame(param1))
	{
		DisplayMenu(g_hPropMenu, param1, MENU_TIME_FOREVER);
	}
}


// GravityGun.SP


public Action:ClientRemoveAll(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fda <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg, 
				client, 
				target_list, 
				MAXPLAYERS, 
				0, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		FakeClientCommand(target_list[i], "sm_delall");
	}
	
	return Plugin_Handled;
}

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new building = GetEventInt(event, "index");
	if (Build_RegisterEntityOwner(building, client)) {
		Build_SetLimit(client, -1);
		decl String:classname[48];
		GetEntityClassname(building, classname, sizeof(classname));
		if (StrEqual(classname, "obj_sentrygun"))
		{
			SetEntPropString(building, Prop_Data, "m_iName", "Sentry Gun");
		}
		if (StrEqual(classname, "obj_dispenser"))
		{
			SetEntPropString(building, Prop_Data, "m_iName", "Dispenser");
		}
		if (StrEqual(classname, "obj_teleporter"))
		{
			SetEntPropString(building, Prop_Data, "m_iName", "Teleporter");
		}
	}
	return Plugin_Continue;
}

stock GetAimOrigin(client, Float:hOrigin[3])
{
	new Float:vAngles[3], Float:fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	GetClientEyeAngles(client, vAngles);
	
	fOrigin[2] += 75.0;
	
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hOrigin, trace);
		CloseHandle(trace);
		return 1;
	}
	
	CloseHandle(trace);
	return 0;
}

public bool:TraceRayDontHitEntity(entity, mask, any:data)
{
	if (entity == data)
		return false;
	
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
} 