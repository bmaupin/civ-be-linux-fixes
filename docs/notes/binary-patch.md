# Binary patch notes

## Goal

A patch to the CivBE binary to fix the crash when mods are used.

## Idea 1: Skip LoadCvGameCoreDLL if CvGameCoreDLL already loaded

Figure out if there's some way inside SetActiveDLCandMods to know which CvGameCoreDLL will be loaded by LoadCvGameCoreDLL. Then if it's already loaded, skip it.

I'm not sure this would work in situations where a mod needed a different CvGameCoreDLL other than the one that's already loaded ...

#### Implementation ideas

- Need to know
  - If any CvGameCoreDLL is active, and which
  - Which CvGameCoreDLL will be activated
    - The second parameter to SetActiveDLCandMods does contain the list of DLC, and the CvGameCoreDLL can be

## Idea 2: Skip LoadCvGameCoreDLL if mods are used

Similarly to what we're doing now, see if there's some way inside SetActiveDLCandMods to see if mods are being used, and if so, skip LoadCvGameCoreDLL.

SetActiveDLCandMods seems to have a couple parameters with list of mods and DLC. If one of these is the list of mods and DLC that are to be loaded, they could be checked against the GUIDs of the DLC. For example:

1. Check if the GUID for Rising Tide is in the list of mods and DLC
1. If it is, and the length of the list is greater than 1, then that should mean that mods are in use and LoadCvGameCoreDLL should be skipped; I think the list only contains gameplay-related DLC so I don't think it would contain the GUID for the planet DLC
1. If the GUID for Rising Tide is not in the list and the length of the list is greater than 0, then that should mean that mods are in use and LoadCvGameCoreDLL should be skipped

#### Implementation ideas

- SetActiveDLCandMods

  - If enabled mods list (parameter 3) is empty, skip LoadCvGameCoreDLL

    - Its length is stored in the 3rd byte of the object:

      1. Get the address of the list at $sp+0xc, then add 8 to that, e.g.

         ```
         print *(int)((*(void**)($sp+0xc))+0x8)
         ```

    - !! This is stored in a variable near the top of the function!!

  - Use CvModdingFrameworkAppSide::GetActivatedMods to see if mods are activated and skip LoadCvGameCoreDLL?
    - return (char \*)this + 1504;

- GetActiveDLCForMods
  - Modify it?
    - We'd need to first see what's being passed to SetActiveDLCandMods to see what we would need
  - ~~Empty it after it's called?~~
    - Would be complicated since there are fewer stopwatch calls in ActivateModsAndDLCForEnabledMods, and none between GetActiveDLCForMods and SetActiveDLCandMods

#### Workflow

1. CvModdingFrameworkAppSide::ActivateModsAndDLCForEnabledMods
   1. Gets list of enabled mods from database
   1. Calls GetActiveDLCForMods
      1. Gets corresponding DLC for those mods
      1. Calls GetDLCToEnable
         1. Searches database for mods and DLC dependencies of those mods
   1. Calls SetActiveDLCandMods

#### More details

There seems to be some kind of benchmark code in SetActiveDLCandMods before and after LoadCvGameCoreDLL is called. This code could potentially be replaced with no-op (`0x90`) and the extra space could be used to add the necessary conditionals for the above ideas.

If this is done, the benchmarking code after LoadCvGameCoreDLL also needs to be set to no-op, otherwise there will be a fault (trying to free memory for a variable that hasn't been set or something).

But I'm not even sure there is enough space to implement these ideas in that space. I think there is a function that checks the contents of the mods/DLC list (`cvContentPackageIDList::Contains`), so this could probably be used. And the GUID for the Rising Tide DLC should already be in the binary. So between these two, it should save some space. But I'm still not sure there would be enough. Also it would require a bit of work to understand the different parameters and other state in the function to see if there's enough information available to do either of these ideas.

## Notes

### `CvModdingFrameworkAppSide::SetActiveDLCandMods`

#### Parameters

1. (CvModdingFrameworkAppSide)
   - `$sp+0x4`
   - Offset 0x5d4: contains a package ID list???
   - Offset 0x5e8
     - Integer; number of enabled mods??
2. (cvContentPackageIDList)
   - List of mod/DLC GUIDs???
   - $sp+0x8
3. (list \*)???
   - List of enabled mods (GUID as string and version as integer)
   - $sp+0xc
   - `x/20xw *(int)($sp+0xc)`
   - Offset 0x4:
   - Offset 0x8: length of list ???
4. (boolean) - If true, seems to skip some kind of requirement that a package at some location in parameter 1 must also be in the list in parameter 2. Always set to false in the game code.
5. (boolean) - Seems to indicate whether this is the initial load. Otherwise, everything needs to be unloaded first.

```
struct cvContentPackageIDList {
    void *unknown;             // Some data (likely 4 bytes, based on the offset to the next element)
    cvContentPackageIDList *next; // Pointer to the next element in the linked list
    _GUID guid;                // GUID, starting at offset 8 bytes from the start
};
```

#### SetupDLL

#### lActivateAllowedDLC

- GUID of Expansion 1 is at x/4xw \*(int)($sp+0xc)+0x10
  - In param 3 ???

### cvContentPackageIDList

#### Structure

- Object
  - First byte: Points to the first GUID, or the object if no GUID
  - Second byte: Points to the last GUID, or the object if no GUID
  - Third byte: number of elements in list?
- GUID
  - First byte:
    - Points to next GUID if there's a next GUID
    - Otherwise points to address of list object
  - Second byte:
    - Points to previous GUID if there's a previous GUID
    - Otherwise points to address of list object
  - Third byte: start of GUID

#### Functions

- Add GUID or list
- Contains GUID
- Remove GUID or list
- == cvContentPackageIDList
- != cvContentPackageIDList
- = cvContentPackageIDList

### Mod list

#### Structure

- Object
  - First byte: address of first item in list, otherwise address of list if empty
  - Second byte: address of last item in list, otherwise address of list if empty
  - Third byte: number of items in list
- Item
  - First byte: address of previous item in list, otherwise address of list if no previous item
  - Second byte: address of next item in list, otherwise address of list if no next item

## Notes

#### Get parameter content

```
gdb CivBE
break SetActiveDLCandMods
run
```

Print DLC:

```
define print_guids
  set $list_head = *(void**)($esp+0x8)
  set $node = *(void**)$list_head
  while $node != $list_head
    printf "GUID: "
    x/4wx $node+8
    set $node = *(void**)$node
  end
end
```

Print Mods:

```
x/20xw *(void**)($sp+0xc)
```

#### Content of DLC/mods in SetActiveDLCandMods

- First starting the game
  1. CivBEApp::SetupDLL
  - DLC
    - Expansion 1
    - Maps
  - Mods: none?
  1. cvLuaModdingLibrary::lActivateAllowedDLC
  - DLC
    - Expansion 1
    - Maps
  - Mods: none?
- Deactivate/activate DLC from DLC menu
  1. CvModdingFrameworkAppSide::DeactivateMods
     - DLC: list of activated DLC
     - Mods: none
  1. cvLuaModdingLibrary::lActivateAllowedDLC
     - DLC: list of activated DLC
     - Mods: none
  1. cvLuaModdingLibrary::lActivateAllowedDLC
     - DLC: list of activated DLC
     - Mods: none
- Activating mods from Mods menu
  1. cvLuaModdingLibrary::lActivateEnabledMods > CvModdingFrameworkAppSide::ActivateModsAndDLCForEnabledMods
     - DLC: list of activated DLC, e.g.
       - Expansion 1
       - Maps
     - Mods: list of activated mods
