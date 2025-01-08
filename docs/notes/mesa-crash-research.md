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

#### Mesa 24.2.8

Upgrading to mesa 24.2.8 causes the game to crash before the match even starts or just after it starts. Backtrace:

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

#### Build Mesa from source

Build Mesa from source so we can do a Git bisect and submit an upstream issue:

1. Check out mesa from Git
1. Check out the tag, e.g. `mesa-23.3.3`
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

1. Compile

   ```
   PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig:$PKG_CONFIG_PATH meson setup --cross-file cross --wipe builddir/ && meson compile -j 4 -C builddir/
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
