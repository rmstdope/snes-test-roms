# undisbeliever PPU window / INIDISP fade test ROMs

Window mask, single-window HDMA shape and INIDISP fade demo ROMs by
Marcus Rowe (undisbeliever), built from
[undisbeliever/snes-test-roms][r] (zlib license, see
[LICENSE](./LICENSE)).

Upstream publishes no prebuilt release containing these ROMs, so they
are built once locally from the source mirror in
[`../undisbeliever-inidisp/sources/`](../undisbeliever-inidisp/sources/)
and the resulting `.sfc` files are committed here.

## ROMs

All from `src/effects/`:

  - `window-mask-logic.sfc` — interactive demo of every window
    mask-logic setting applied to the color window: Right/Left cycle
    the 4-bit logic value (bits 0-1 = OR/AND/XOR/XNOR, bit 2 = invert
    window 1, bit 3 = invert window 2), L toggles window 1 enable,
    R toggles window 2 enable, Select toggles the instruction text.
    Two HDMA-driven window shapes (rectangles + diamonds) render as
    black clipped regions on a white backdrop.
  - `window-shapes-single.sfc` — 14 hard-coded HDMA single-window
    shape tables (rectangles, trapeziums, triangles, octagon, circle,
    multi-shape, left>right). Auto-advances to the next shape every
    120 frames until any button is pressed; afterwards Right/B = next
    shape, Left/Y = previous shape. Pressing A locks the automatic
    advance without changing the selected shape (A is only read by
    the initial any-button check, not by the navigation loop).
  - `window-precalculated-single.sfc` — precalculated
    non-symmetrical single-window shape bouncing around the screen
    (HDMA double-buffered from WRAM, animates every frame).
  - `window-precalculated-symmetrical.sfc` — precalculated
    horizontally-symmetrical single-window variant of the above.
  - `inidisp_fadein_fadeout.sfc` — INIDISP fade-in / fade-to-force-
    blank screen transition demo: alternates between two images, each
    shown with a 0→15 fade-in (4 frames per brightness step), a
    one-second hold, a 15→0 fade-out and a force-blank gap.

`inidisp_extend_vblank.sfc` from the same source directory is
deliberately not vendored here: it is an IRQ-timed extended-VBlank
demo and belongs with the PPU timing work (issue #2883).

## Rebuilding

Requires GNU make, Python 3 and a C++ compiler. Same procedure and
bass-untech clang patch as [`../undisbeliever-ppu-bg/`](../undisbeliever-ppu-bg/README.md):

```sh
cd ../undisbeliever-inidisp
./update-sources                       # refresh the source mirror
cd sources
git submodule update --init bass-untech
patch -p1 -d bass-untech < ../../undisbeliever-ppu-bg/bass-untech-arg-eval-order.patch
make -C bass-untech/bass -j4           # build the assembler
make directories
make bin/effects/window-mask-logic.sfc \
     bin/effects/window-shapes-single.sfc \
     bin/effects/window-precalculated-single.sfc \
     bin/effects/window-precalculated-symmetrical.sfc \
     bin/effects/inidisp_fadein_fadeout.sfc
# then copy the built bin/effects/*.sfc files into this directory
```

[r]: https://github.com/undisbeliever/snes-test-roms
