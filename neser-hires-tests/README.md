# NESER mid-frame hires-transition test ROMs

NESER-authored test ROMs for hires modes turned on part-way down a
frame (issue neser#3034), written against the undisbeliever bass test
ROM framework (zlib license, see [LICENSE](./LICENSE); skeletons
derived from [undisbeliever/snes-test-roms][r]). Sources live in
[`src/`](./src/) and the built `.sfc` files are committed alongside
them.

No redistributable third-party ROM covering a mid-frame hires switch
could be found. Every hires ROM in this collection — `MosaicMode5`,
the six `Interlace*` demos, the four `HiColor*` pseudo-hires demos and
`neser-opt-tests/opt-m6` — writes BGMODE/SETINI once during init, and
ddribin's `hdrvtest` toggles interlace only between frames, so these
were authored for NESER.

## The shared scene

Both ROMs render the static scene from
[`src/_hires-scene.inc`](./src/_hires-scene.inc), built so that a
hires scanline and a native scanline cannot be confused:

  - BG1 (main screen): vertical stripes, tilemap column c uses tile
    (c%8)+1, palette 0 (saturated colours).
  - BG2 (sub screen): horizontal bands, tilemap row r uses tile
    (r%8)+1, palette 1 (dimmer, distinct hues).
  - `CGWSEL.addSubscreen` is set, so in a hires mode the sub screen
    supplies the even output column and the main screen the odd one.

Colour math is off, so a native line shows BG1's stripes alone (BG2 is
only a would-be operand) while a hires line shows BG1 and BG2
interleaved per half-pixel.

One HDMA channel writes the switching register every scanline, native
for the first 100 display lines and hires for the remaining 124
(`HIRES_SWITCH_LINE`). 100 is deliberately not a multiple of 8, so a
whole-tile-row error in where the switch lands would show rather than
hide inside the scene's own 8-pixel period.

## ROMs

  - `hires-hdma-bgmode.sfc` — HDMA writes BGMODE (`$2105`), mode 1
    above the switch line and mode 5 (true hires) below it. Both
    values keep the BG tile-size bits clear, so the mode is the only
    thing changing mid-frame.
  - `hires-hdma-setini.sfc` — HDMA writes SETINI (`$2133`), clear
    above the switch line and pseudo-hires (bit 3) below it, with
    BGMODE left at mode 1 all frame. Every other SETINI bit stays
    clear, so neither overscan nor screen interlace is disturbed.

## Expected output

Hardware and Mesen2 present the whole frame as one 512x448 picture:
the rows drawn before the switch are re-laid-out when it happens
rather than left in the narrow layout. So in a capture, output rows
0-199 are column-doubled, rows 200-447 carry true half-pixel pairs,
and every row pair is identical. `neser_hires_tests.rs` asserts
exactly that alongside the golden CRC.

## Rebuilding

Same procedure as
[`../neser-colormath-tests/`](../neser-colormath-tests/README.md):

```sh
cd ../undisbeliever-inidisp/sources
git submodule update --init bass-untech
patch -p1 -d bass-untech < ../../undisbeliever-ppu-bg/bass-untech-arg-eval-order.patch
make -C bass-untech/bass -j4
cp -r ../../neser-hires-tests/src src/neser-hires-tests
make directories
make bin/neser-hires-tests/hires-hdma-bgmode.sfc bin/neser-hires-tests/hires-hdma-setini.sfc
# then copy bin/neser-hires-tests/*.sfc back into this directory,
# remove src/neser-hires-tests and revert the bass-untech patch
```

[r]: https://github.com/undisbeliever/snes-test-roms
