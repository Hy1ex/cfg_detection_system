# CFG Detection System
CFG Detection System is a plugin for Counter-Strike Source v34 (Build 4044) Servers made in Sourcepawn
and need Metamod + Sourcemod to run.
The point of this plugin is simple, this plugin detects clients(players) that are using cfgs to give them
self advantage and using unfair scripts(aliases) to greif the server.
This plugin doesn't do much because the advantage that some players can get from cfgs and scripts(aliases)
is not too much and doesn't effect the gameplay at all, This plugin is meant for server with high restrictions and
fair play rules.

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
| **sm_cfgds_adminflag** | ``Admin flag for CFG Detection System panel/menu access.`` |
| **sm_cfgds_autodetect** | ``Automatically check players on join.``<br/>**0** - disabled<br/>**1** - enabled<br/> |
| **sm_cfgds_punishmode** | ``Punishment mode.``<br/>**0** - Report<br/>**1** - Kick<br/>**2** - Ban<br/> |
| **sm_cfgds_ban_mode** | ``Ban mode.``<br/>**1** - SteamID<br/>**2** - IP Address<br/> |
| **sm_cfgds_ban_duration** | ``Ban duration in minutes (0=permanent)`` |

## Todo
- Grow the convar database
