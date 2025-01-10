# Mesa crash research

## Details

After upgrading to Ubuntu 24.04, the game crashes even without mods. It can crash when opening the Steam overlay. Most of the time the match will start fine, but then in the match the graphics (specifically text) will not show or become corrupt, and flicker back and forth between not showing/corrupt or just fine. And the game will eventually crash within a few minutes.

Backtrace:

```
Thread 17 "CivBE:gl0" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0xe2193b40 (LWP 57944)]
Download failed: Invalid argument.  Continuing without source file ./string/../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S.
__memcpy_sse2_unaligned () at ../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S:480
warning: 480	../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S: No such file or directory
(gdb) bt
#0  __memcpy_sse2_unaligned () at ../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S:480
#1  0xf2f2f770 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#2  0xf2f2d5bb in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#3  0xf2c9b73a in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#4  0xf2c9ba5b in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#5  0xf2a1d4fe in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#6  0xf2bbdd16 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#7  0xf2bbf266 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#8  0xf2c310a1 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#9  0xf29d40cb in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#10 0xf299fc9b in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#11 0xf762fff7 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:447
#12 0xf76c75b8 in clone3 () at ../sysdeps/unix/sysv/linux/i386/clone3.S:111
```

## Troubleshooting

#### Overview

I don't remember why, but at some point I suspected Mesa; if I knew more I would've suspected it right away from the backtrace as "Iris" is the Intel graphics driver for Mesa.

Ubuntu 22.04 (which I used previously) uses Mesa 23.2.1 I think. But Ubuntu 24.04 uses Mesa 24.0.

#### More on Mesa

From what I understand, Mesa is basically the OpenGL graphics library for Linux used by open source drivers, which includes all Intel drivers (also some AMD drivers, but Nvidia support is unofficial). Mesa converts OpenGL calls to the API used by the device using user-space drivers (Crocus for older Intel graphics cards, Iris for newer ones). Then these user-space drivers call drivers in the kernel (i915 I think).

I don't know if a program that uses Vulkan would go through Mesa too.

But Mesa does have a "Zink" driver that converts OpenGL calls to Vulkan and then passes those calls to the device's Vulkan API. But due to the extra translation this isn't perfect and can result in some graphics anomalies and a performance hit due to the extra translation.

#### First steps

1. First, I ran the game with gdb to get the backtrace (above), e.g.

   ```
   gdb CivBe
   (gdb) start
   (gdb) cont
   (after crash)
   (gdb) bt
   ```

1. Then I tried some high-level troubleshooting

   - Check game Lua logs to make sure it's not a game issue
   - Try X11 instead of Wayland
   - Try with just one monitor
   - Try full screen instead of windowed
   - Try without mods
   - Try different libtbb
   - Try `taskset` (I'd read about this elsewhere and seems to fix issues with too many cores)

1. Next I ran the game with `MESA_DEBUG=verbose` to look for errors:

   ```
   MESA_DEBUG=verbose LD_PRELOAD='/home/bmaupin/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so' LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/lib ./CivBE
   ```

   And I saw:

   ```
   Mesa: error: GL_OUT_OF_MEMORY in glMapBufferRange(map failed)
   ...
   Segmentation fault
   ```

1. I tried a handful of workarounds:

   - `GALLIUM_THREAD=0 ./CivBE` fixed the crash and the graphic corruption, but the graphics still flickered
   - `LIBGL_ALWAYS_SOFTWARE=1 ./CivBE` switched to software rendering, which worked but the game was unbearably slow. I suppose this confirmed the crash was an issue with hardware rendering
   - `MESA_LOADER_DRIVER_OVERRIDE=zink` fixed all of the issues I was having, but unfortunately it had some annoying graphical anomalies like flickering textures

1. I confirmed that the game had no issues on a different computer; this computer was using the Crocus Mesa driver (it has older intel Graphics)

1. I confirmed again that the game had no issues on another computer with Iris graphics running Ubuntu 22.04 (Mesa 23.2), so it seemed the issue must be with Mesa and more specifically with the Iris driver and with a newer version of Mesa between 23.2 and 24.0

#### Mesa 24.2.8

I wanted to see if upgrading Mesa corrected the issue in case it had already been discovered and fixed upstream.

Unfortunately upgrading to mesa 24.2.8 caused the game to crash before the match even started or just after it started.

Also I noticed that the `GALLIUM_THREAD=0` workaround didn't work any more.

Backtrace:

```
Thread 8 "CivBE" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0xe5effb40 (LWP 9584)]
0xf3ae7aff in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
(gdb) bt
#0  0xf3ae7aff in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#1  0xf3aea3f4 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#2  0xf3ab6f1f in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#3  0xf344f997 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#4  0xf3453614 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#5  0xf3140666 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#6  0xf345242f in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#7  0xf25e9c5c in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#8  0xf25ba31f in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#9  0xf25bd882 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#10 0xf25c3c56 in ?? ()
--Type <RET> for more, q to quit, c to continue without paging--c
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#11 0x0996862f in ID3D11ShaderResourceView_Mac::ASLTexSubImage2D(unsigned int, int, int, int, int, int, unsigned int, unsigned int, void const*, int, int) const ()
#12 0x09963a4b in ID3D11ShaderResourceView_Mac::ASLUpdateSubresource(ID3D11Texture2D_Mac*, unsigned int, D3D11_BOX const*) ()
#13 0x09964169 in ID3D11Texture2D_Mac::ASLUpdateSubresource(unsigned int, D3D11_BOX const*, void const*, unsigned int) ()
#14 0x0994eb7d in ID3D11DeviceContext_Mac::UpdateSubresource(ID3D11Resource*, unsigned int, D3D11_BOX const*, void const*, unsigned int, unsigned int) ()
#15 0x0929e49b in Graphics::_INTERNAL::UpdateSubresource_Workaround(ID3D11Device*, ID3D11DeviceContext*, ID3D11Resource*, unsigned int, D3D11_BOX const*, void const*, unsigned int, unsigned int, unsigned int, bool*) ()
#16 0x092a9f98 in ?? ()
#17 0x092a7a20 in Graphics::Renderer::Render() ()
#18 0x089fc4d5 in CivBEApp::RenderFrame(float) ()
#19 0x089f7b96 in CivBEApp::OnIdle() ()
#20 0x089f6859 in CivBEApp::Tick(AppHost::TickInfo const*) ()
#21 0x0903b6e8 in AppHost::RunApp(int, char**, AppHost::Application*) ()
#22 0x0903a8d0 in AppHost::RunApp(char*, AppHost::Application*) ()
#23 0x089f0ff8 in WinMain ()
#24 0x08987301 in ?? ()
#25 0x089bfcb5 in ThreadHANDLE::ThreadProc(void*) ()
#26 0xf762fff7 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:447
#27 0xf76c75b8 in clone3 () at ../sysdeps/unix/sysv/linux/i386/clone3.S:111
```

#### Downgrade Mesa

Since upgrading Mesa didn't work, it seemed like whatever issue I was running into hasn't yet been identified and fixed. So next, I wanted to downgrade Mesa to indeed confirm it was the issue:

1. Go here: https://launchpad.net/ubuntu/+source/mesa
2. In the list in the main part of the page click _The Noble Numbat_
3. Click on a version under _Releases in Ubuntu_
4. Under _Builds_ click _amd64_
5. Copy the URL for libegl-mesa0, e.g. https://launchpad.net/ubuntu/+source/mesa/23.3.0-1ubuntu1/+build/27036119/+files/libegl-mesa0_23.3.0-1ubuntu1_amd64.deb
6. Get the list of packages we need and copy to a new file in vscode

   ```
   dpkg -l | egrep "mesa|gbm|axtracker" | awk '{print $2}' | egrep -v "mesa-utils|\-dev" | cut -d : -f 1 | sort -u
   ```

7. Prepend each package name with the first part of the URL, and append with the last
8. Prepend `wget ` to each package name and copy to terminal to download
9. Go back to step for, click i386, repeat (it will have a different build number)
   - Or just get the build number for i386 and replace, and replace `amd64` with `i386`
10. Install the packages

    ```
    sudo dpkg -i *.deb
    ```

11. Reboot and test

#### Build Mesa from source

References:

- https://docs.mesa3d.org/install.html
- https://docs.mesa3d.org/meson.html
  - 👉 In particular, see _Cross-compilation and 32-bit builds_
- https://gist.github.com/Venemo/a9483106565df3a83fc67a411191edbd?permalink_comment_id=3951924

Build Mesa from source so we can do a Git bisect and submit an upstream issue:

1. Check out mesa from Git

   https://gitlab.freedesktop.org/mesa/mesa

   ⚠️ This was a huge pain because the `git clone` kept timing out. I tried a bunch of stuff but in the end this is what worked (as per https://stackoverflow.com/a/57082400/399105):

   ```
   Host gitlab.freedesktop.org
        IPQoS=throughput
   ```

1. Install dependencies, e.g.

   ```
   sudo apt install libdrm-dev:i386 zlib1g-dev:i386 libzstd-dev:i386 libxcb1-dev:i386 libx11-dev:i386 libxext-dev:i386 libxfixes-dev:i386 libxcb-glx0-dev:i386 libxcb-shm0-dev:i386 libx11-xcb-dev:i386 libxcb-keysyms1-dev:i386 libxcb-dri2-0-dev:i386 libxcb-dri3-dev:i386 libxcb-present-dev:i386 libxxf86vm-dev:i386 libxrandr-dev:i386 libxshmfence-dev:i386 libwayland-dev:i386 libsensors-dev:i386 libva-dev:i386 libvdpau-dev:i386 libwayland-egl-backend-dev:i386 libelf-dev:i386 libexpat1-dev:i386 libudev-dev:i386
   ```

1. Make cross compile file, e.g.

   ```
   echo "[binaries]
   c = '/usr/bin/gcc'
   cpp = '/usr/bin/g++'
   ar = '/usr/bin/gcc-ar'
   strip = '/usr/bin/strip'
   pkg-config = '/usr/bin/pkgconf'
   llvm-config = '/usr/bin/llvm-config-17'

   [properties]
   c_args = ['-m32']
   c_link_args = ['-m32']
   cpp_args = ['-m32']
   cpp_link_args = ['-m32']

   [host_machine]
   system = 'linux'
   cpu_family = 'x86'
   cpu = 'i686'
   endian = 'little'" > cross
   ```

1. Check out a tag, e.g. `mesa-23.3.3`

   ⚠️ This is only for testing a specific version. Don't use tags with git bisect

1. Compile

   ```
   rm -rf builddir/; \
       meson compile -C builddir/ --clean; \
       PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig:$PKG_CONFIG_PATH meson setup --cross-file cross -Dprefix=$(pwd)/built -Dgallium-drivers=iris -Dvulkan-drivers= -Dbuildtype=release --wipe builddir/ && \
       meson compile -j 6 -C builddir/
   ```

   👉 Adjust `meson compile -j 6` to the number of cores you wish to use, e.g. `-j 6` will use 6 cores

   - `-Dprefix`: set a prefix to install to; it's too hard to use the compiled Mesa otherwise except for just very simple scenarios (e.g. with `meson devenv`)
   - `-Dgallium-drivers=iris -Dvulkan-drivers=`: only build the iris driver to save time
   - `-Dbuildtype=release`

1. Install

   ```
   meson install -C builddir/
   ```

1. Sanity check

   1. Download 32-bit glxinfo

      I downloaded the mesa-utils i386 .deb from here and extracted glxinfo from it: https://launchpad.net/ubuntu/+source/mesa-demos/8.4.0-1build1/+build/15697776

   1. Run this command and make sure you see the version you just built

      ```
      $ LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/lib ~/Desktop/tmp-mesa/mesa-utils-i386/glxinfo | grep -i mesa
      ```

1. Test

   ```
   cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth
   MESA_DEBUG=verbose LD_PRELOAD='/home/bmaupin/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so' LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/lib ./CivBE
   ```

If you get a build error, go up the logs and look for the actual error (it may not be at the end due to parallel compilation), e.g.

```
/usr/bin/ld: /usr/lib/x86_64-linux-gnu/libxcb.so: error adding symbols: file in wrong format
collect2: error: ld returned 1 exit status
```

Then search for which package contains the file:

```
$ apt-file search /usr/lib/x86_64-linux-gnu/libxcb.so
libxcb1: /usr/lib/x86_64-linux-gnu/libxcb.so.1
libxcb1: /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0
libxcb1-dev: /usr/lib/x86_64-linux-gnu/libxcb.so
```

And install the 32-bit version, e.g.

```
sudo apt install libxcb1-dev:i386
```

It may also help to uninstall the 64-bit version:

```
sudo apt purge libxcb1-dev
```

#### Bisect

⚠️ Don't bisect with a tag, e.g. `git checkout mesa-23.3.3`

```
git checkout main
git bisect start
git log -p VERSION
git checkout fac4f526acfa300139c37e7270dd8ec84b31ce0f
# build
# test
git bisect good
git checkout 69d1e29dc318bb0f1c395c9a9ba1a94056d4dbef
# rebuild
# test
git bisect bad
# rebuild, test, repeat
```
