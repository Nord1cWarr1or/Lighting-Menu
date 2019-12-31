/* *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*                                                                             *
*    Plugin: Lighting menu                                                    *
*                                                                             *
*    Official repository: https://github.com/Nord1cWarr1or/Lighting-Menu      *
*    Contacts of the author: Telegram: @NordicWarrior                         *
*                                                                             *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
*                                                                             *
*    Плагин: Меню освещения                                                   *
*                                                                             *
*    Официальный репозиторий: https://github.com/Nord1cWarr1or/Lighting-Menu  *
*    Связь с автором: Telegram: @NordicWarrior                                *
*                                                                             *
*  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  */

#include <amxmodx>
#include <amxmisc>
#include <engine>

new const PLUGIN_VERSION[] = "0.0.1";

new const CONFIG_FILE[] = "/lighting_menu.ini";  // Name of the config file with lighting parameters

#define MENU_ACCESS     ADMIN_BAN                // Admin flag that allows access to lighting menu

enum _:LightsInfo
{
    LIGHTING_LEVEL[2],
    LIGHTING_NAME[64]
};

new g_szLightingInfo[LightsInfo];
new g_iArrayInfoSize;
new Array:g_ArrayLightingInfo;

public plugin_init()
{
    register_plugin("Lighting Menu", PLUGIN_VERSION, "Nordic Warrior");

    register_dictionary("lightingmenu.txt");

    register_clcmd("amx_lightmenu", "cmdShowLightingMenu", MENU_ACCESS);

    g_ArrayLightingInfo = ArrayCreate(LightsInfo, 1);

    ReadConfig();
}

ReadConfig()
{
    new szConfigFile[MAX_RESOURCE_PATH_LENGTH + 1];
    get_configsdir(szConfigFile, charsmax(szConfigFile));

    add(szConfigFile, charsmax(szConfigFile), CONFIG_FILE);

    new iFilePointer = fopen(szConfigFile, "r");

    if(!iFilePointer)
    {
        set_fail_state("File %s is missing or invalid!", CONFIG_FILE);
        return;
    }

    new szBuffer[sizeof g_szLightingInfo[LIGHTING_LEVEL] + sizeof g_szLightingInfo[LIGHTING_NAME]];

    while(!feof(iFilePointer))
    {
        fgets(iFilePointer, szBuffer, charsmax(szBuffer));
        trim(szBuffer);

        if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#')
            continue;

        if(parse(szBuffer,
            g_szLightingInfo[LIGHTING_LEVEL], charsmax(g_szLightingInfo[LIGHTING_LEVEL]),
            g_szLightingInfo[LIGHTING_NAME], charsmax(g_szLightingInfo[LIGHTING_NAME])) == 2)   // Thanks to neugomon for example code
        {
            ArrayPushArray(g_ArrayLightingInfo, g_szLightingInfo);
        }

        g_iArrayInfoSize = ArraySize(g_ArrayLightingInfo);

        if(!g_iArrayInfoSize)
        {
            set_fail_state("File %s is empty or incorrect!", CONFIG_FILE);
            return;        
        }
    }
    fclose(iFilePointer);
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

    menu_additem(iMenu, fmt("%l^n", "LIGHTINGMENU_MENU_DEFAULT"));

    for(new i; i < g_iArrayInfoSize; i++)
    {
        ArrayGetArray(g_ArrayLightingInfo, i, g_szLightingInfo);

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
    switch(iItem)
    {
        case MENU_EXIT:
        {
            menu_destroy(iMenu);
            return PLUGIN_HANDLED;
        }
        case 0:
        {
            set_lights("#OFF");
            client_print_color(0, id, "^4* %l", "LIGHTINGMENU_CHAT_DEFAULT", id);
        }
        default:
        {
            new szLightingLevel[2], szLightingName[64];

            menu_item_getinfo(iMenu, iItem,
            .info = szLightingLevel,
            .infolen = charsmax(szLightingLevel),
            .name = szLightingName,
            .namelen = charsmax(szLightingName));

            set_lights(szLightingLevel);

            client_print_color(0, id, "^4* %l", "LIGHTINGMENU_CHAT_OTHER", id, szLightingName);
        }
    }
    menu_destroy(iMenu);
    return LightingMenu(id);
}