#!/usr/bin/env bash

game_directory="/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth"

# Allow game directory to be overridden as a command-line parameter
if [ -n "${1}" ]; then
    game_directory="$1"
fi

# Validate game directory
if [[ -f "${game_directory}/CivBE" ]]; then
    echo "Error: This script is for the Proton version of Beyond Earth. You have the native Linux version."
    exit 1
fi
if [[ ! -f "${game_directory}/CivilizationBE_DX11.exe" ]]; then
    echo "Error: Beyond Earth installation directory not found. Please provide the path to Beyond Earth, e.g."
    echo "    $0 \"/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth\""
    exit 1
fi

echo "Fixing terrain bug"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "${game_directory}/assets/UI/InGame/WorldView/DiploCorner.lua"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "${game_directory}/assets/DLC/Expansion1/UI/InGame/WorldView/DiploCorner.lua"

echo "Deleting intro logo videos"
rm -f "${game_directory}/CivBE_Logos.bk2"

echo "Enabling achievements with mods"
sed -i 's/SELECT ModID from Mods where Activated = 1/SELECT ModID from Mods where Activated = 2/' "${game_directory}/CivilizationBE_DX11.exe"
sed -i 's/SELECT ModID from Mods where Activated = 1/SELECT ModID from Mods where Activated = 2/' "${game_directory}/CivilizationBE_Mantle.exe"

# https://forums.civfanatics.com/threads/spoiler-all-starships-unlockables-for-beyond-earth.544763/
# These all require linking with 2K games account, which is apparently no longer possible, hence the patch
echo "Unlocking Starships unlockables"
sed -i 's/FiraxisLiveUnlockKey=".*"//' "${game_directory}/assets/Gameplay/XML/Civilizations/CivBECargo.xml"
sed -i 's/FiraxisLiveUnlockKey=".*"//' "${game_directory}/assets/Gameplay/XML/Civilizations/CivBEColonists.xml"
sed -i 's/FiraxisLiveUnlockKey=".*"//' "${game_directory}/assets/Gameplay/XML/Civilizations/CivBESpacecraft.xml"
sed -i 's/FiraxisLiveKey = ".*",//' "${game_directory}/assets/Maps/Inland_Sea.lua"
sed -i 's/FiraxisLiveKey = ".*",//' "${game_directory}/assets/Maps/Tiny_Islands.lua"
sed -i 's/FiraxisLiveKey = ".*",//' "${game_directory}/assets/Maps/Inland_Sea.lua"
sed -i 's/FiraxisLiveKey = ".*",//' "${game_directory}/assets/DLC/Expansion1/Maps/Tiny_Islands.lua"
sed -i 's/RequiresMy2K = 1,//' "${game_directory}/assets/Maps/Ice_Age.lua"
sed -i 's/RequiresMy2K = 1,//' "${game_directory}/assets/DLC/Expansion1/Maps/Ice_Age.lua"

# https://www.pcgamingwiki.com/wiki/Sid_Meier%27s_Civilization:_Beyond_Earth#Skip_legal_screen
echo "Skip legal screen"
sed -i 's/        UIManager:QueuePopup( Controls.LegalScreen, PopupPriority.LegalScreen );/        -- UIManager:QueuePopup( Controls.LegalScreen, PopupPriority.LegalScreen );/' "${game_directory}/assets/UI/FrontEnd/FrontEnd.lua"

echo "Skip mods EULA dialogue"
sed -i 's/^g_HasAcceptedEULA = false;/g_HasAcceptedEULA = true;/' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
sed -i '/--if not isHide and g_HasAcceptedEULA then/s/--//' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
sed -i '/--\s*NavigateForward();/s/--//' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
sed -i '/--end/s/--//' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
sed -i '/--if(not isHide and g_QueueEulaToHide) then/s/--//' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
sed -i '/--\s*NavigateBack();/s/--//' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
sed -i '/--end/s/--//' "${game_directory}/assets/UI/FrontEnd/Modding/EULA.lua"
