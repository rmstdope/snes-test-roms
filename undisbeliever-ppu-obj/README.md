# undisbeliever PPU OBJ / sprite-limit test ROMs

OBJ (sprite) hardware-limit test ROMs by Marcus Rowe (undisbeliever),
built from [undisbeliever/snes-test-roms][r] (zlib license, see
[LICENSE](./LICENSE)).

Upstream publishes no prebuilt release containing these ROMs, so they
are built once locally from the source mirror in
[`../undisbeliever-inidisp/sources/`](../undisbeliever-inidisp/sources/)
and the resulting `.sfc` files are committed here.

## ROMs

From `src/hardware-tests/`:

  - `object-dropout-test.sfc` (v3): a static, self-running scene that
    exercises the PPU OBJ hardware limits on a single screen:
      - 36 sprites sharing one scanline (only 32 can be evaluated per
        line; the excess sprites drop out). This is the official
        **range-over** limit ($213E bit 6), though the ROM source names
        it `TimeOverflowTest`.
      - Rows of 16px-spaced overlapping sprites producing more than 34
        8x1 tile slivers on a line (excess slivers drop out), plus a
        V/H-flipped variant. This is the official **time-over** limit
        ($213E bit 7), though the ROM source names it
        `RangeOverflowTest`.
      - **X=256 bug**: a sprite at X=256 counts against the
        sprites/slivers-per-scanline limits even though it is
        off-screen.
    The scene uses 4bpp OBJ tiles, all eight OBJ palettes and OAM
    attribute flipping, sets up OAM/CGRAM/VRAM once via DMA during
    forced blank, and then idles forever — ideal for a screen-CRC
    golden.

## Rebuilding

Requires GNU make, Python 3 and a C++ compiler.

```sh
cd ../undisbeliever-inidisp
./update-sources                       # refresh the source mirror
cd sources
git submodule update --init bass-untech
# On clang (macOS): fix an argument-evaluation-order bug in bass first:
patch -p1 -d bass-untech < ../../undisbeliever-ppu-bg/bass-untech-arg-eval-order.patch
make -C bass-untech/bass -j4           # build the assembler
make directories
make bin/hardware-tests/object-dropout-test.sfc
# then copy the built .sfc into this directory
```

See [`../undisbeliever-ppu-bg/README.md`](../undisbeliever-ppu-bg/README.md)
for details on the bass-untech clang fix.

[r]: https://github.com/undisbeliever/snes-test-roms
