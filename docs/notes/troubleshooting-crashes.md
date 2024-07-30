#### Troubleshoot other crashes related to mods

1. CD to the game directory, e.g.

   ```
   cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth
   ```

1. Set some commands

   ```
   cat << 'EOF' >> commands.gdb
   define print_dlc
     set $list_head = $arg0
     set $node = *(void**)$list_head
     while $node != $list_head
       printf "GUID: "
       x/4wx $node+8
       set $node = *(void**)$node
     end
   end

   define print_mods
     set $list_head = $arg0
     set $node = *(void**)$list_head
     while $node != $list_head
       printf "GUID: "
       x/s $node+8
       set $node = *(void**)$node
     end
   end
   EOF
   ```

1. Start the game with gdb

   ```
   gdb CivBE
   ```

1. Source the commands

   ```
   source commands.gdb
   ```

1. Run the game

   ```
   run
   ```

1. Once the game gets to the main menu, pause it (Ctrl-C)

1. Set a break point at SetActiveDLCandMods

   ```
   break SetActiveDLCandMods
   ```

1. Continue the game

   ```
   cont
   ```

1. Once the breakpoint is reached

   1. Print activated DLC

      ```
      print_dlc *(void**)($sp+0x4)+0x5d4
      ```

   1. Print DLC to activate

      ```
      print_dlc *(void**)($sp+0x8)
      ```

   1. Print activated mods

      ```
      print_mods *(void**)($sp+0x4)+0x5e0
      ```

   1. Print mods to activate

      ```
      print_mods *(void**)($sp+0xc)
      ```
