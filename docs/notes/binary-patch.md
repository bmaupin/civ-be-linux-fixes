# Binary patch notes

## Goal

A patch to the CivBE binary to fix the crash when mods are used.

## Implementation

#### Idea 1: Skip LoadCvGameCoreDLL if CvGameCoreDLL already loaded

Figure out if there's some way inside SetActiveDLCandMods to know which CvGameCoreDLL will be loaded by LoadCvGameCoreDLL. Then if it's already loaded, skip it.

I'm not sure this would work in situations where a mod needed a different CvGameCoreDLL other than the one that's already loaded ...

#### Idea 2: Skip LoadCvGameCoreDLL if mods are used

Similarly to what we're doing now, see if there's some way inside SetActiveDLCandMods to see if mods are being used, and if so, skip LoadCvGameCoreDLL.

SetActiveDLCandMods seems to have a couple parameters with list of mods and DLC. If one of these is the list of mods and DLC that are to be loaded, they could be checked against the GUIDs of the DLC. For example:

1. Check if the GUID for Rising Tide is in the list of mods and DLC
1. If it is, and the length of the list is greater than 1, then that should mean that mods are in use and LoadCvGameCoreDLL should be skipped; I think the list only contains gameplay-related DLC so I don't think it would contain the GUID for the planet DLC
1. If the GUID for Rising Tide is not in the list and the length of the list is greater than 0, then that should mean that mods are in use and LoadCvGameCoreDLL should be skipped

#### More details

There seems to be some kind of benchmark code in SetActiveDLCandMods before and after LoadCvGameCoreDLL is called. This code could potentially be replaced with no-op (`0x90`) and the extra space could be used to add the necessary conditionals for the above ideas.

If this is done, the benchmarking code after LoadCvGameCoreDLL also needs to be set to no-op, otherwise there will be a fault (trying to free memory for a variable that hasn't been set or something).

But I'm not even sure there is enough space to implement these ideas in that space. I think there is a function that checks the contents of the mods/DLC list (`cvContentPackageIDList::Contains`), so this could probably be used. And the GUID for the Rising Tide DLC should already be in the binary. So between these two, it should save some space. But I'm still not sure there would be enough. Also it would require a bit of work to understand the different parameters and other state in the function to see if there's enough information available to do either of these ideas.
