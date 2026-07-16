# NESER colour-math / window / brightness test ROMs

NESER-authored PPU colour-math, window and INIDISP-brightness test
ROMs (issue neser#2880), written against the undisbeliever bass test
ROM framework (zlib license, see [LICENSE](./LICENSE); skeletons
derived from [undisbeliever/snes-test-roms][r]). Sources live in
[`src/`](./src/) and the built `.sfc` files are committed alongside
them.

## The shared scene

All ROMs render the static Mode 1 quadrant scene from
[`src/_colormath-scene.inc`](./src/_colormath-scene.inc):

  - BG1 (main screen): 8 vertical bars, 24px wide (columns 0-191),
    full height.
  - BG2 (sub screen): 8 horizontal bars, 24px tall (rows 0-191),
    full width.
  - Backdrop: (4, 8, 12).

This yields 64 (main, sub) colour crossings plus three fallback
regions: backdrop-main x sub bars (right strip), main bars x
transparent sub (bottom strip, exercising the fixed-colour fallback
which disables halving on hardware), and backdrop x transparent sub
(bottom-right corner). Bar colours discriminate clamp-at-31 (16+16),
floor-at-0 (8-16) and halve-after-add ((15+1)/2 = 8).

## ROMs

  - `cm-add-clamp.sfc` — CGADSUB add, full; per-component clamp at 31.
  - `cm-sub-floor.sfc` — CGADSUB subtract, full; per-component floor at 0.
  - `cm-add-half.sfc` — add + half; halve-after-add rounding.
  - `cm-sub-half.sfc` — subtract + half; subtract/floor/halve order.
  - `cm-fixed-add.sfc` — CGWSEL fixed-colour addend, COLDATA written
    per plane (R=31, G=16, B=8); per-plane latching.
  - `cm-fixed-sub-half.sfc` — fixed-colour subtract + half
    (COLDATA all planes = 9).
  - `cm-sub-backdrop.sfc` — sub-screen bars cover only the centre
    columns; the sides must add the fixed colour (R=20, B=20)
    WITHOUT halving (transparent-sub fallback rule).
  - `cm-obj-palettes.sfc` — eight identical grey sprites, one per OBJ
    palette; colour math must apply only to palettes 4-7.
  - `cm-window-clip.sfc` — colour window 1 (x = 64-191) with CGWSEL
    clip-to-black inside / prevent-math outside; the clipped region
    adds the sub colour at full strength (halving disabled).
  - `win-layer-masks.sfc` — layer windows: BG1 masked by window 1,
    BG2 by inverted-window-1 AND window 2 (WBGLOG), both via TMW.
  - `brightness-steps.sfc` — the NMI handler steps INIDISP from the
    frame counter: brightness level N shown for frames 64N..64N+63
    (N = 0-15), full brightness held for frames 1024-1151,
    force-blank from frame 1152. Sample mid-plateau (frame 64N + 32).

## Rebuilding

Requires GNU make, Python 3 and a C++ compiler. Uses the
undisbeliever source mirror and the bass-untech clang patch, exactly
like [`../undisbeliever-ppu-bg/`](../undisbeliever-ppu-bg/README.md):

```sh
cd ../undisbeliever-inidisp/sources
git submodule update --init bass-untech
patch -p1 -d bass-untech < ../../undisbeliever-ppu-bg/bass-untech-arg-eval-order.patch
make -C bass-untech/bass -j4
cp -r ../../neser-colormath-tests/src src/neser-colormath-tests
make directories
make $(for r in cm-add-clamp cm-sub-floor cm-add-half cm-sub-half \
    cm-fixed-add cm-fixed-sub-half cm-sub-backdrop cm-obj-palettes \
    cm-window-clip win-layer-masks brightness-steps; do \
    echo bin/neser-colormath-tests/$r.sfc; done)
# then copy bin/neser-colormath-tests/*.sfc back into this directory
```

[r]: https://github.com/undisbeliever/snes-test-roms
