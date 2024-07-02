# When mods are loaded
break CvModdingFrameworkAppSide::ActivateModsAndDLCForEnabledMods
commands
  # When it comes time to unload/load CvGameCoreDLL
  tbreak CvModdingFrameworkAppSide::LoadCvGameCoreDLL
  commands
    # Return early without running the rest of the function
    return (int)0
    # Detach gdb to avoid a performance hit when playing the game
    detach
  end
  continue
end

run
