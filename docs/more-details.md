# More details

## libtbb

The CivBE binary requires the shared library libtbb.so.2 ([Threading Building Blocks](https://github.com/oneapi-src/oneTBB)). Civ 5 also requires this file and includes it in the installation ([https://steamdb.info/depot/282301/](https://steamdb.info/depot/282301/)), but Beyond Earth doesn't.

#### The proper version of libtbb is installed

The fix listed in the [readme](../README.md) involves copying libtbb from the Steam Linux Runtime to the game directory. This ensures this version is always used, even if it's installed elsewhere on the system. Here's the md5sum of that version:

```
$ md5sum ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/libtbb.so.2
b71a4c4dad0fcf5ab3a0d9c28d4dee43  /home/bryan/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/libtbb.so.2
```

#### A recent version of libtbb is installed

If a recent version of libtbb is installed on the system, the game may start and even may work for 10 or 20 turns but it will eventually crash.

Here is an example backtrace:

```
[New Thread 0x98987ac0 (LWP 45198)]

Thread 50 "CivBE" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0x98987ac0 (LWP 45198)]
0x08b71d76 in FireGrafix::DynamicsLock<Graphics::BuildingDataDynamicConsts>::DynamicsLock(Graphics::SurfaceSet**, FireGrafix::SurfaceSetPoolAllocator*, unsigned short) ()
(gdb) bt
#0  0x08b71d76 in FireGrafix::DynamicsLock<Graphics::BuildingDataDynamicConsts>::DynamicsLock(Graphics::SurfaceSet**, FireGrafix::SurfaceSetPoolAllocator*, unsigned short) ()
#1  0x08c25f76 in cvLandmarkVisSystem::cvLandmarkVisDynamicConstantUpdaterSS::HandleBuildingShader(Graphics::FGXShaderPackageInstanceView*, FireGrafix::FGXModelNode*, FGXVector4*) ()
#2  0x08c25f08 in cvLandmarkVisSystem::cvLandmarkVisDynamicConstantUpdaterSS::UpdateNode(Graphics::FGXShaderPackageInstanceView*, FireGrafix::FGXModelNode*, FGXVector4*) ()
#3  0x08c25e2c in FireGrafix::FGXModelRenderByNodeSSExample_Shadow<cvLandmarkVisSystem::cvLandmarkVisDynamicConstantUpdaterSS, 2, FireGrafix::FGXModelRenderEndSuperclass>::RenderNode(unsigned int*, FireGrafix::FGX_SPIV_GENERIC*, FireGrafix::FGXModelNode*, FGXVector4*) ()
#4  0x08c24ff5 in cvLandmarkVisSystem::LandmarkRenderJob::Execute(unsigned int) ()
#5  0x093d26d9 in Platform::JobTask::execute() ()
#6  0xf7667aee in ?? () from ./libtbb.so.2
#7  0xf7667e3a in ?? () from ./libtbb.so.2
#8  0xf7661011 in ?? () from ./libtbb.so.2
#9  0xf765f5ca in ?? () from ./libtbb.so.2
#10 0xf765b4c5 in ?? () from ./libtbb.so.2
#11 0xf765b738 in ?? () from ./libtbb.so.2
#12 0xf7486c01 in ?? () from /lib/i386-linux-gnu/libc.so.6
#13 0xf752372c in ?? () from /lib/i386-linux-gnu/libc.so.6
(gdb)
```

#### libtbb isn't installed anywhere

When libtbb isn't installed, you should see this when you run the command below:

```
$ ldd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE | grep libtbb
	libtbb.so.2 => not found
```

In this case, Steam has its own copy of the library in the Steam Linux Runtime 1.0, and it will automatically use that version. This is the correct version, and the game should work fine.

The problem with this is that if libtbb gets installed later, it could cause the game to start crashing if it's the wrong version.

## Terrain appears above cities and units, no water or hills are visible

The terrain bug seems to appear any time there are errors with Lua scripts. This normally occurs with mods but unfortunately, the game ships with a Lua error, and so this bug will occur without any mods installed.

The Lua error in question seems to be a reference to a "culture overview UI" button. As best as I can tell, this code was copied from Civ 5 as this button doesn't even seem to exist in Beyond Earth.

The bug also seems to exist in the non-Linux versions of the game but I'm not sure if they exhibit the same behaviour.

## Sound issues

As with the libtbb.so.2 fix above, this is a required library that isn't included in the game, and it's possible there could be a library compatibility issue with a system library.
