# undisbeliever PPU Mode 7 test ROMs

Mode 7 VRAM layout / VMAIN address-remapping and Mode 7 tilemap demo
ROMs by Marcus Rowe (undisbeliever), built from
[undisbeliever/snes-test-roms][r] (zlib license, see
[LICENSE](./LICENSE)).

Upstream publishes no prebuilt release containing these ROMs, so they
are built once locally from the source mirror in
[`../undisbeliever-inidisp/sources/`](../undisbeliever-inidisp/sources/)
and the resulting `.sfc` files are committed here (same approach as
[`../undisbeliever-ppu-bg/`](../undisbeliever-ppu-bg/)).

## ROMs

From `src/vmain-address-remapping/` (Mode 7 interleaved VRAM writes at
each VMAIN increment/remapping setting; all four display the same
static Mode 7 image when VMAIN is emulated correctly):

  - `vmain-mode7-image-no-remapping.sfc` -- low-byte-only writes,
    increment after $2118
  - `vmain-mode7-image-tilemap.sfc` -- tilemap written first, then
    tiles, using both increment modes
  - `vmain-mode7-image-with-8bit-remapping.sfc` -- 8-bit VMAIN address
    remapping
  - `vmain-mode7-image-with-10bit-remapping.sfc` -- 10-bit VMAIN
    address remapping

From `src/effects/` (Mode 7 tilemap update demos):

  - `vmain-mode7-tilemap-columns.sfc` -- writes Mode 7 tilemap columns
    using VMAIN increment-after-$2119 mode
  - `vmain-mode7-tilemap-rows.sfc` -- writes Mode 7 tilemap rows using
    VMAIN increment-after-$2118 mode

## Rebuilding

Follow the procedure in
[`../undisbeliever-ppu-bg/README.md`](../undisbeliever-ppu-bg/README.md)
(including the bass-untech clang patch), then:

```sh
cd ../undisbeliever-inidisp/sources
make bin/vmain-address-remapping/vmain-mode7-image-no-remapping.sfc \
     bin/vmain-address-remapping/vmain-mode7-image-tilemap.sfc \
     bin/vmain-address-remapping/vmain-mode7-image-with-8bit-remapping.sfc \
     bin/vmain-address-remapping/vmain-mode7-image-with-10bit-remapping.sfc \
     bin/effects/vmain-mode7-tilemap-columns.sfc \
     bin/effects/vmain-mode7-tilemap-rows.sfc
# then copy the built .sfc files into this directory
```

[r]: https://github.com/undisbeliever/snes-test-roms
