Troubleshooting various crashes with Sid Meier's Civilization: Beyond Earth on Linux.

## Game crashes within 10 turns

If the game successfully starts but crashes within 10 turns or so, try this fix:

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

## Game crashes before it starts when using mods

⚠️ Work in progress: [docs/notes/mod-crash.md](docs/notes/mod-crash.md)

ⓘ Mod support seems to have been added in December 2014 but very quickly afterwards users were reporting that starting any game with mods would make the game crash.
