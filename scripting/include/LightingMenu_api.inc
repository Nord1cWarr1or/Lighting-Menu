#if defined _LightingMenu_api_included
	#endinput
#endif
#define _LightingMenu_api_included

/*
* Called before a lighting level will be setted
* You can stop execution of changing level light by this forward
*
* @param iLevel     Index of a choosen lighting level
*
* @noreturn
*/
forward OnSetLightingLevelPre(iLevel);

/*
* Called after a lighting level is setted
*
* @param iLevel     Index of a choosen lighting level
*
* @noreturn
*/
forward OnSetLightingLevelPost(iLevel);

/*
* Returns an id of current lighting level
*
* @return iLevel     Index of a current lighting level
*/
native get_custom_lighting_level();

/*
* Sets the lighting level
* Note: lighting levels start from 0, according to the config file
*
* @param iLevel     Index of a choosen lighting level
*
* @return			true if a lighting level is setted, false otherwise
*/
native set_custom_lighting_level(iLevel);