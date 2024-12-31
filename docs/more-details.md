# More details

## libtbb

The CivBE binary requires the shared library libtbb.so.2 ([Threading Building Blocks](https://github.com/oneapi-src/oneTBB)). Civ 5 also requires this file and includes it in the installation ([https://steamdb.info/depot/282301/](https://steamdb.info/depot/282301/)), but Beyond Earth doesn't.

#### A recent version of libtbb is installed

If a recent version of libtbb is installed on the system, you will see something like this:

```
$ ldd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE | grep libtbb
	libtbb.so.2 => /lib/i386-linux-gnu/libtbb.so.2 (0xf1d31000)
```

Unfortunately this is the wrong version of the library. The game should start but it will crash after a few turns.

#### libtbb isn't installed anywhere

When libtbb isn't installed, you should see this when you run the command below:

```
$ ldd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE | grep libtbb
	libtbb.so.2 => not found
```

In this case, Steam has its own copy of the library in the Steam Linux Runtime 1.0, and it will automatically use that version. This is the correct version, and the game should work fine.

The problem with this is that if libtbb gets installed later, it could cause the game to start crashing if it's the wrong version.

#### The proper version of libtbb is installed

```
$ ldd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE | grep libtbb
	libtbb.so.2 => ./libtbb.so.2 (0xe7d14000)
```

The fix listed in the [readme](../README.md) involves copying libtbb from the Steam Linux Runtime to the game directory. This ensures this version is always used, even if it's installed elsewhere on the system.

## Terrain is not displayed correctly

The terrain bug seems to appear any time there are errors with Lua scripts. This normally occurs with mods but unfortunately, the game ships with a Lua error, and so this bug will occur without any mods installed.

The Lua error in question seems to be a reference to a "culture overview UI" button. As best as I can tell, this code was copied from Civ 5 as this button doesn't even seem to exist in Beyond Earth.

The bug also seems to exist in the non-Linux versions of the game but I'm not sure if they exhibit the same behaviour.

## libopenal

As with the libtbb.so.2 fix above, this is a required library that isn't included in the game, and it's possible there could be a library compatibility issue with a system library.
