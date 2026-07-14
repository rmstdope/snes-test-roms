# NESER PPU OBJ feature test ROMs

Static one-screen OBJ (sprite) test ROMs authored for
[NESER issue #2879][2879], covering PPU OBJ features that no vendored
upstream test ROM exercises. Written against the undisbeliever
snes-test-roms bass framework (skeletons derived from his
`object-dropout-test.asm`; zlib license, see [LICENSE](./LICENSE)).
Sources live in [`src/`](./src/); the built `.sfc` files are committed
here.

All scenes set up VRAM/CGRAM/OAM once during force-blank and then idle
forever, so they settle within a few frames and suit screen-CRC goldens.
The OBJ tiles are undisbeliever's `hex8` glyphs: every 8x8 tile displays
its own tile number, so each capture shows exactly which tiles were
fetched.

## ROMs

- `obj-size-grid-0.sfc` ... `obj-size-grid-7.sfc`: one small and one
  large sprite side by side for each OBSEL size select value (0-7,
  including the undocumented rectangular 16x32/32x64 and 16x32/32x32
  pairs). Shared source in `src/_obj-size-grid.inc` plus one stub per
  value.
- `obj-palettes.sfc`: eight 16x16 sprites showing the same glyphs
  through OBJ palettes 0-7 (CGRAM 128 + 16*p), left to right.
- `obj-priority.sfc`: overlapping sprite clusters demonstrating that the
  lower OAM index is always in front, even when the back sprite has
  higher OAM priority bits.
- `oam-x8.sfc`: the OAM high-table X bit 8 -- a control sprite, a
  right-edge clip (X=240), a negative X (X=496/-16, left half clipped)
  and X=256 (fully off-screen).
- `obj-bg-priority.sfc`: mode 1 with BG1 bands of tilemap priority 0 and
  1 crossed by four sprites with OAM priorities 0-3 (expected layering:
  OBJ3 > BG1 pri-1 > OBJ2 > BG1 pri-0 > OBJ1/OBJ0).
- `first-sprite-rotation.sfc`: OAMADDH bit 7 priority rotation with
  OAMADD selecting sprite 2, flipping which sprite of an overlapping
  pair wins, plus an unaffected control pair.
- `obj-y-wrap.sfc`: sprites at y=240 wrapping around to the top of the
  screen (16x32 size), unflipped and V-flipped, plus a fully visible
  control. As of NESER #3003 the V-flipped wrapped sprite diverges from
  Mesen2, so this ROM has no approved golden yet.

Parked (unused) OAM entries sit at X=256 via the high-table X bit 8
rather than the usual y=240 filler: at X=256 a sprite is invisible at
every size, whereas 32px-tall sprites at y=240 wrap into screen lines
0-15 (and still consume per-scanline evaluation limits).

## Rebuilding

Requires GNU make, Python 3 and a C++ compiler. Build inside the source
mirror used by the other undisbeliever ROMs:

```sh
cd ../undisbeliever-inidisp
./update-sources                       # refresh the source mirror
cd sources
git submodule update --init bass-untech
# On clang (macOS): fix an argument-evaluation-order bug in bass first:
patch -p1 -d bass-untech < ../../undisbeliever-ppu-bg/bass-untech-arg-eval-order.patch
make -C bass-untech/bass -j4           # build the assembler
make directories
cp -r ../../neser-obj-tests/src src/neser-obj-tests
make $(printf 'bin/neser-obj-tests/%s ' $(ls ../../neser-obj-tests/*.sfc | xargs -n1 basename))
# then copy the built bin/neser-obj-tests/*.sfc files back here
```

[2879]: https://github.com/rmstdope/neser/issues/2879
