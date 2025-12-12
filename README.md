Various fixes and workarounds for Sid Meier's Civilization: Beyond Earth on Linux

📌 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

💡 Much of the information here may also apply to the Steam Deck

## Native or Proton?

👉 Most people will have a better experience playing the game with Proton (better performance, fewer bugs, better graphics)

#### Choose the native Linux version or Proton

1. Open Steam and go to _Library_

1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1. _Compatibility_ > check _Force the use of a specific Steam Play compatibility tool_

1. Click the dropdown

   - To use Proton, choose a version of _Proton_

     - Normally the latest stable version is fine. If you have issues, try another version.

   - To use native, choose _Steam Linux Runtime 1.0_

1. (Recommended) Run the [all-in-one patch script](#all-in-one-patch-script)

## All-in-one patch script

ⓘ This includes fixes for many issues (mostly for the native Linux version) as well as quality-of-life changes like enabling achievements with mods, disabling intro videos and EULA dialogues, etc.

1. Download the patch script: [patchcivbe.sh](patchcivbe.sh)

1. (Optional) Open the patch script and comment out any undesired changes

1. Run the patch script

   ```
   ./patchcivbe.sh
   ```

   ⓘ It will default to `"/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth"` for the Beyond Earth installation directory. If you have it installed somewhere else you can provide it as a parameter to the script, e.g.

   ```
   ./patchcivbe.sh /some/other/path
   ```

⚠️ If you switch between Proton and native, uninstall the game, or verify the integrity of the game files, the patches will be uninstalled and will need to be re-applied.

## Uninstall

To uninstall the all-in-one patch script or any other modifications:

1. Open Steam and go to _Library_

1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1. _Installed Files_ > _Verify integrity of game files_

## Troubleshooting

- The [all-in-one patch script](#all-in-one-patch-script) has fixes for many common issues, in particular with the native Linux version
- If you're using the native Linux version and run into issues, [try Proton](#choose-the-native-linux-version-or-proton)
- If you're using Proton and run into issues, try a newer version of Proton or [try the native Linux version](#choose-the-native-linux-version-or-proton)
  - The Proton version seems to crash when uninstalling mods while the game is running, particularly during mod development

#### Crash when using Mesa >= 24 and Intel Iris graphics

ⓘ The native Linux version will crash when using Mesa 24 or later and Intel Iris graphics. It's possible this may affect other Intel or AMD graphics cards.

To fix this, switch to the Proton version or use this workaround:

1.  Open Steam and go to _Library_

1.  Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1.  Under _Launch Options_, add this:

    ```
    MESA_LOADER_DRIVER_OVERRIDE=zink %command%
    ```

#### Other issues

See [here](docs/troubleshooting.md) for more general troubleshooting tips or [here](docs/linux-fixes.md) for troubleshooting issues with the native Linux version
