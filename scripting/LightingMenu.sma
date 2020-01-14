/* *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*                                                                             *
*    Plugin: Lighting menu                                                    *
*                                                                             *
*    Official plugin support: https://dev-cs.ru/threads/8898/                 *
*    Official repository: https://github.com/Nord1cWarr1or/Lighting-Menu      *
*    Contacts of the author: Telegram: @NordicWarrior                         *
*                                                                             *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*                                                                             *
*    Плагин: Меню освещения                                                   *
*                                                                             *
*    Официальная поддержка плагина: https://dev-cs.ru/threads/8898/           *
*    Официальный репозиторий: https://github.com/Nord1cWarr1or/Lighting-Menu  *
*    Связь с автором: Telegram: @NordicWarrior                                *
*                                                                             *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */

#include <amxmodx>
#include <amxmisc>
#include <engine>

new const PLUGIN_VERSION[] = "0.1.1";

new const CONFIG_FILE[] = "LightingMenu.ini";   // Name of the config file with lighting parameters

#define MENU_ACCESS         ADMIN_BAN           // An admin flag that allows access to lighting menu
#define RELOAD_CFG_ACCESS   ADMIN_RCON          // An admin flag that allows access to reload config of the plugin

enum _:LightsInfo
{
    LIGHTING_LEVEL[2],
    LIGHTING_NAME[64]
};

const DEFAULT_LIGHT_LEVEL = -1;

new g_szLightingInfo[LightsInfo];
new g_iArrayInfoSize;
new Array:g_ArrayLightingInfo;
new g_iCurrentLightingLevel = DEFAULT_LIGHT_LEVEL;
new g_iFwdSetLightingPre, g_iFwdSetLightingPost;

public plugin_init()
{
    register_plugin("Lighting Menu", PLUGIN_VERSION, "Nordic Warrior");

    register_dictionary("lightingmenu.txt");

    register_clcmd("amx_lightmenu", "cmdShowLightingMenu", MENU_ACCESS);
    register_concmd("amx_lightmenu_reload", "cmdReloadConfig", RELOAD_CFG_ACCESS);

    g_iFwdSetLightingPre = CreateMultiForward("OnSetLightingLevelPre", ET_STOP, FP_CELL);
    g_iFwdSetLightingPost = CreateMultiForward("OnSetLightingLevelPost", ET_IGNORE, FP_CELL);

    g_ArrayLightingInfo = ArrayCreate(LightsInfo, 1);

    ReadConfig();

    register_cvar("amx_lightmenu_save", "1");
    register_cvar("amx_lightmenu_saved_value", fmt("%i", DEFAULT_LIGHT_LEVEL));     // Don't modify!

    LoadLightLevel();

    register_cvar("LightingMenu_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
}

public plugin_natives()
{
    register_native("get_custom_lighting_level", "native_get_custom_lighting_level");
    register_native("set_custom_lighting_level", "native_set_custom_lighting_level");
}

ReadConfig()
{
    ArrayClear(g_ArrayLightingInfo);

    new szConfigFile[MAX_RESOURCE_PATH_LENGTH + 1];
    get_configsdir(szConfigFile, charsmax(szConfigFile));

    add(szConfigFile, charsmax(szConfigFile), fmt("/%s", CONFIG_FILE));

    new iFilePointer = fopen(szConfigFile, "r");

    if(!iFilePointer)
    {
        set_fail_state("File %s is missing or invalid!", CONFIG_FILE);
        return;
    }

    new szBuffer[sizeof g_szLightingInfo];

    while(!feof(iFilePointer))
    {
        fgets(iFilePointer, szBuffer, charsmax(szBuffer));
        trim(szBuffer);

        if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#')
            continue;

        if(parse(szBuffer,
            g_szLightingInfo[LIGHTING_LEVEL], charsmax(g_szLightingInfo[LIGHTING_LEVEL]),
            g_szLightingInfo[LIGHTING_NAME], charsmax(g_szLightingInfo[LIGHTING_NAME])) == 2)   // Thanks neugomon for example code
        {
            ArrayPushArray(g_ArrayLightingInfo, g_szLightingInfo);
        }
    }
    fclose(iFilePointer);

    g_iArrayInfoSize = ArraySize(g_ArrayLightingInfo);

    if(!g_iArrayInfoSize)
    {
        set_fail_state("File %s is empty or incorrect!", CONFIG_FILE);
        return;        
    }
}

public cmdShowLightingMenu(const id, level, cid)
{
    if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED;

    LightingMenu(id);
    return PLUGIN_HANDLED;
}

public LightingMenu(const id)
{
    SetGlobalTransTarget(id);

    new iMenu = menu_create(fmt("%l", "LIGHTINGMENU_MENU_HEAD"), "LightingMenu_handler");

    if(g_iCurrentLightingLevel == DEFAULT_LIGHT_LEVEL)
    {
        menu_additem(iMenu, fmt("\d%l \y*^n", "LIGHTINGMENU_MENU_DEFAULT"));
    }
    else
    {
        menu_additem(iMenu, fmt("%l^n", "LIGHTINGMENU_MENU_DEFAULT"));
    }
    
    for(new i; i < g_iArrayInfoSize; i++)
    {
        ArrayGetArray(g_ArrayLightingInfo, i, g_szLightingInfo);

        if(i == g_iCurrentLightingLevel)
        {
            menu_additem(iMenu, fmt("\d%s \y*", g_szLightingInfo[LIGHTING_NAME]));
            continue;
        }

        menu_additem(iMenu, g_szLightingInfo[LIGHTING_NAME], g_szLightingInfo[LIGHTING_LEVEL]);
    }

    menu_setprop(iMenu, MPROP_EXITNAME, fmt("%l", "LIGHTINGMENU_MENU_EXIT"));
    menu_setprop(iMenu, MPROP_BACKNAME, fmt("%l", "LIGHTINGMENU_MENU_BACK"));
    menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%l", "LIGHTINGMENU_MENU_MORE"));

    menu_display(id, iMenu);
    return PLUGIN_HANDLED;
}

public LightingMenu_handler(const id, iMenu, iItem)
{
    if(iItem == MENU_EXIT)
    {
        menu_destroy(iMenu);
        return PLUGIN_HANDLED;
    }

    new iChoosenLightingLevel = iItem - 1;

    new iReturn;
    ExecuteForward(g_iFwdSetLightingPre, iReturn, iChoosenLightingLevel);

    if(iReturn == PLUGIN_HANDLED)
		return PLUGIN_HANDLED;

    if(iChoosenLightingLevel == g_iCurrentLightingLevel)
        return LightingMenu(id);

    switch(iItem)
    {
        case 0:
        {
            set_lights("#OFF");

            client_print_color(0, id, "^4* %l", "LIGHTINGMENU_CHAT_DEFAULT", id);
        }
        default:
        {
            menu_item_getinfo(iMenu, iItem,
                .info = g_szLightingInfo[LIGHTING_LEVEL],
                .infolen = charsmax(g_szLightingInfo[LIGHTING_LEVEL]),
                .name = g_szLightingInfo[LIGHTING_NAME],
                .namelen = charsmax(g_szLightingInfo[LIGHTING_NAME]));

            set_lights(g_szLightingInfo[LIGHTING_LEVEL]);

            client_print_color(0, id, "^4* %l", "LIGHTINGMENU_CHAT_OTHER", id, g_szLightingInfo[LIGHTING_NAME]);
        }
    }
    g_iCurrentLightingLevel = iChoosenLightingLevel;

    menu_destroy(iMenu);

    ExecuteForward(g_iFwdSetLightingPost, iReturn, iChoosenLightingLevel);
    return LightingMenu(id);
}

public cmdReloadConfig(const id, level, cid)
{
    if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED;

    ReadConfig();

    console_print(id, "Reload successful!");
    return PLUGIN_HANDLED;
}

public native_get_custom_lighting_level(iPluginId, iParams)
{
    return g_iCurrentLightingLevel;
}

public native_set_custom_lighting_level(iPluginId, iParams)
{
    new iLevel = get_param(1);

    if(!(DEFAULT_LIGHT_LEVEL <= iLevel < g_iArrayInfoSize))
        return false;

    g_iCurrentLightingLevel = iLevel;

    SetLightLevel(g_iCurrentLightingLevel);
    return true;  
}

public LoadLightLevel()
{
    g_iCurrentLightingLevel = get_cvar_num("amx_lightmenu_saved_value");

    if(!get_cvar_num("amx_lightmenu_save"))
    {
        g_iCurrentLightingLevel = DEFAULT_LIGHT_LEVEL;
    }

    SetLightLevel(g_iCurrentLightingLevel);
}

SetLightLevel(iLevel)
{
    if(iLevel == DEFAULT_LIGHT_LEVEL)
    {
        set_lights("#OFF");
    }
    else
    {
        for(new i; i < g_iArrayInfoSize; i++)
        {
            ArrayGetArray(g_ArrayLightingInfo, i, g_szLightingInfo);

            if(i == iLevel)
            {
                set_lights(g_szLightingInfo[LIGHTING_LEVEL]);
                break;
            }
        }
    }
}

public plugin_end()
{
    set_cvar_num("amx_lightmenu_saved_value", g_iCurrentLightingLevel);
}