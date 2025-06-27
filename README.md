# ConVar Checker
ConVar Checker is a plugin for Counter-Strike Source v34 (Build 4044) Servers made in Sourcepawn
and require Metamod + Sourcemod to run.
The point of this plugin is simple, this plugin detects clients(players) that are using custom convar values to give them
self advantage.
Aggresive ConVar blocking because someone could potentially use it in a "bad" way is bad approach but this plugin is made for servers
with high restriction.

## Compilation Dependencies:
- Clientmod Library (Included)
- MultiColor Library and Sub libraries (Included)
- Standard Sourcemod Libraries

## Required to Run:
- [Metamod 1.10+](https://www.metamodsource.net/)
- [Sourcemod 1.11+](https://sourcemod.net) (1.11 is recommended but the plugin should work on later versions too)
- [ClientMod Api](https://github.com/Reg1oxeN/ClientMod-Api/tree/master)

## Convars
| Console variable | Description |
| --- | --- |
| **sm_cvc_adminflag** | ``Admin flag for ConVar Checker panel/menu access.`` |
| **sm_cvc_autodetect** | ``Automatically check players on join.``<br/>**0** - disabled<br/>**1** - enabled<br/> |
| **sm_cvc_punishmode** | ``Punishment mode.``<br/>**0** - Report<br/>**1** - Kick<br/>**2** - Ban<br/> |
| **sm_cvc_ban_mode** | ``Ban mode.``<br/>**1** - SteamID<br/>**2** - IP Address<br/> |
| **sm_cvc_ban_duration** | ``Ban duration in minutes (0=permanent)`` |
| **sm_cfg <br/>sm_cvc <br/>sm_convarchecker** | ``Opens ConVar Checker menu.`` |

## Todo
- Grow the convar database
