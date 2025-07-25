```c++
//   _    _ _   _ _____ _______ ______ _____   __          __     _____  
//  | |  | | \ | |_   _|__   __|  ____|  __ \  \ \        / /\   |  __ \ 
//  | |  | |  \| | | |    | |  | |__  | |  | |  \ \  /\  / /  \  | |__) |
//  | |  | | . ` | | |    | |  |  __| | |  | |   \ \/  \/ / /\ \ |  _  / 
//  | |__| | |\  |_| |_   | |  | |____| |__| |    \  /\  / ____ \| | \ \ 
//   \____/|_| \_|_____|  |_|  |______|_____/      \/  \/_/    \_\_|  \_\

// Author: SirBrambley (Special thanks to F9Bomber, JJ, GBD, N1, and the entire community)
// References:
// 1. https://steamcommunity.com/sharedfiles/filedetails/?id=1488402495
// 2. https://www.lua.org/docs.html
```

# ////////// VEHICLE SELECTION //////////
*Still learning some of that Lua goon shit!* 🌛

1. **Listbox** fills in text from `instant_startvehicles.odf`.
1. Selected **listbox** item returns string to `script.menu.vehicle`.
1. Based on race: item converts to a **.fbx** model in `Update()` and *set* to `script.menu.vehicleFBX`.
1. **Viewer** loads `script.menu.vehicleFBX`.

## Enabler Shit 👷‍♂️
Enabler components that get everything working lol.

### Object Definition File 🧱
Fills in the config with *human readable* vehicle names:
- `instant_startvehicles.odf`

#### Contents:
```c++
Scout
Recon
Tank
Missile Tank
Assault Tank
Walker
```

## Config Changes 🏓

All relevant variables:
- `script.menu.myside` → Integer between **0→1** corresponding to **ISDF** or **Scion**.
- `script.menu.vehicle` → **Human-readable** vehicle name pulled from the UI listbox.
- `script.menu.vehicleFBX` → Model **.fbx** name that gets set for the viewer.

> Note: *renamed `script.menu.vehicleODF` → `script.menu.vehicleFBX`*

### Configure Config Vars 🤖
```c++
ConfigureVarSys()
{
    // SETS RACE INTEGER
	CreateInteger("script.menu.myside", 0);
	SetIntegerRange("script.menu.myside", 0, 1);

	// ADDITIONALLY INITIALIZES DEFAULT
	CreateString("script.menu.vehicle", "Scout");
	CreateString("script.menu.vehicleFBX", "ivscout00.fbx");
}
```

### Listbox 📃
```c++
CreateControl("TestListbox", "LISTBOX")
{
    FillFromFile("instant_startvehicles.odf");
    UseVar("script.menu.vehicle");
}
```
### Race Button ✅
```c++
CreateControl("TestRace1", "BUTTON")
{
    Text("SCION");
    UseVar("script.menu.myside");
    Value(0);
}
```

### Viewer 🗿

```c++
CreateControl("TestViewer", "VIEWER")
{
    UseVar("script.menu.vehicleFBX");
}
```

## Lua 🌔

### IFace Table 💊
```lua
local IFace = {
    test_myside = "script.menu.myside",
    test_vehicle = "script.menu.vehicle",
    test_vehicleFBX= "script.menu.vehicleFBX"
}
```
### Vehicle Lookup Table
```lua
local LookupStartVehicle = {
    ["Scout"] = {
        classnames = {"fvscout", "ivscout"},
        models = {"fvscout_skel.fbx", "ivscout00.fbx"}
    },
    ["Recon"] = {
        classnames = {"fvsent", "ivmbike"},
        models = {"fvsent_skel.fbx", "ivmbik00.fbx"}
    },
    ["Tank"] = {
        classnames = {"fvtank", "ivtank"},
        models = {"fvtank_skel.fbx", "ivtank00.fbx"}
    },
    ["Missile Tank"] = {
        classnames = {"fvarch", "ivmisl_dm"},
        models = {"fvlancer_skel.fbx", "ivmisl00.fbx"}
    },
    ["Assault Tank"] = {
        classnames = {"fvatank", "ivatank"},
        models = {"fvtitan_skel.fbx", "ivatnk00.fbx"}
    },
    ["Walker"] = {
        classnames = {"fvwalk", "ivwalk"},
        models = {"fvwalk_skel.fbx", "ivwalk_skel.fbx"}
    }
}
```

### GetUnitModelFilename()
```lua
function GetUnitModelFilename(humanName, race)
   local entry = LookupStartVehicle[humanName]
   if entry and entry.models and entry.models[race + 1] then
       return entry.models[race + 1]
   else
       return nil
   end
end
```

### Update()
```lua
-- SETS THE UI MENU VIEWER WITH THE SELECTED ITEM IN THE LISTBOX, BY CONVERTING THE NAME TO .FBX
playerVehicleFBX = GetUnitModelFilename(
    IFace_GetString(IFace.test_vehicle),
    IFace_GetInteger(IFace.test_myside)
    )
IFace_SetString(IFace.test_vehicleFBX, playerVehicleFBX)
```