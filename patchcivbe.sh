#!/usr/bin/env bash

game_directory="/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth"

# Allow game directory to be overridden as a command-line parameter
if [ -n "${1}" ]; then
    game_directory="$1"
fi

# Validate game directory
if [[ ! -f "${game_directory}/CivBE" ]]; then
    echo "Error: Beyond Earth installation directory not found. Please provide the path to Beyond Earth, e.g."
    echo "    $0 \"/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth\""
    exit 1
fi

echo "Copying libtbb.so.2 (fixes crashes after game starts)"
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 "${game_directory}"

echo "Copying libopenal.so.1 (prevents issues with audio)"
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libopenal.so.1 "${game_directory}"

echo "Fixing terrain bug"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "${game_directory}/steamassets/assets/ui/ingame/worldview/diplocorner.lua"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "${game_directory}/steamassets/assets/dlc/expansion1/ui/ingame/worldview/diplocorner.lua"

echo "Applying mod crash patch"
patch=$(cat << 'EOF'
00a17f00: 8b # mov    0x844(%esp),%eax ; Put the address of list of needed DLC in $eax
00a17f01: 84
00a17f02: 24
00a17f03: 44
00a17f04: 08
00a17f05: 00
00a17f06: 00
00a17f07: 89 # mov    %eax,0x4(%esp)   ; Put $eax in $esp+0x4 (second parameter)
00a17f08: 44
00a17f09: 24
00a17f0a: 04
00a17f0b: 8b # mov    0x70(%esp),%eax  ; Put the address of list of activated DLC in $eax
00a17f0c: 44
00a17f0d: 24
00a17f0e: 70
00a17f0f: 89 # mov    %eax,(%esp)      ; Put $eax in $esp (first parameter)
00a17f10: 04
00a17f11: 24
00a17f12: e8 # call   0x8b896b6        ; Check if activated DLC != needed DLC
00a17f13: 9f
00a17f14: 97
00a17f15: 12
00a17f16: 00
00a17f17: 84 # test   %al,%al          ; Test the result of the function call
00a17f18: c0
00a17f19: 74 # je     0x8a5ff32        ; If zero (i.e. equal), jump past call to LoadCvGameCoreDLL
00a17f1a: 17
00a17f1b: 90 # nop                     ; Clear out remaining instructions up to LoadCvGameCoreDLL
00a17f1c: 90
00a17f1d: 90
00a17f1e: 90
00a17f1f: 90
00a17f20: 90
00a17f30: 90 # nop                     ; Clear out instructions after LoadCvGameCoreDLL
00a17f31: 90
00a17f32: 90
00a17f33: 90
00a17f34: 90
00a17f35: 90
00a17f36: 90
00a17f37: 90
EOF
)
checksum=$(md5sum "${game_directory}/CivBE" | awk '{print $1}')
# Unmodified
if [ "$checksum" = "316a3d1b2c29fbe6b59a7cc04c240808" ] ||
    # Cheevo patch has been applied
    [ "$checksum" = "6e29371fd4e8f573e7f29426e314dd7f" ]; then
    xxd -c1 -r <(echo "$patch") "${game_directory}/CivBE"
fi

echo "Deleting intro logo videos"
rm -f "${game_directory}/steamassets/%aspyr.bk2"
rm -f "${game_directory}/steamassets/aspyr.bk2"
rm -f "${game_directory}/steamassets/civbe_logos.bk2"

echo "Enabling achievements with mods"
sed -i 's/SELECT ModID from Mods where Activated = 1/SELECT ModID from Mods where Activated = 2/' "${game_directory}/CivBE"
