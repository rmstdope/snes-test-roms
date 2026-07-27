# NESER Mode 7 test ROMs

NESER-authored Mode 7 test ROMs (issue neser#2881), written against
the undisbeliever bass test ROM framework (zlib license, see
[LICENSE](./LICENSE); skeletons derived from
[undisbeliever/snes-test-roms][r]). Sources live in [`src/`](./src/)
and the built `.sfc` files are committed alongside them. They cover
the M7SEL out-of-screen (wrap / colour 0 / tile 0 fill) and flip
behaviour with a fixed, statically-written matrix - features the
animated PeterLemon Mode 7 demos exercise only incidentally.

## The shared scene

All ROMs render the static 1024x1024 px Mode 7 scene from
[`src/_mode7-scene.inc`](./src/_mode7-scene.inc): a white border
ring, coloured 128px corner blocks (red TL, green TR, blue BL,
yellow BR), a magenta centre cross and a cyan/dark-grey
checkerboard. Tile 0 is a solid orange fill marker (visible only via
M7SEL out-of-screen = tile 0); the backdrop is dark blue (visible
only via out-of-screen = colour 0). The matrix is written once
during init; nothing animates.

## ROMs

  - `m7-identity.sfc` - identity matrix baseline (top-left 256x224 px
    of the scene).
  - `m7-scale-wrap.sfc` - A = D = 8.0 zoom-out, M7SEL out-of-screen =
    repeat: the map tiles/wraps beyond 1024 px.
  - `m7-scale-color0.sfc` - same matrix, out-of-screen = colour 0:
    dark blue backdrop beyond the map.
  - `m7-scale-tile0.sfc` - same matrix, out-of-screen = tile 0:
    orange fill beyond the map.
  - `m7-rot30.sfc` - 30-degree rotation about the map centre
    (M7X = M7Y = 512), centre cross mid-screen.
  - `m7-flip-h.sfc` / `m7-flip-v.sfc` - M7SEL screen flips over the
    identity matrix.
  - `m7-mosaic.sfc` - identity matrix with MOSAIC size 16 on BG1
    (Mode 7 mosaic).

## Rebuilding

Same procedure as
[`../neser-colormath-tests/`](../neser-colormath-tests/README.md):
copy `src/` into the undisbeliever source mirror as
`src/neser-mode7-tests`, `make directories`, build
`bin/neser-mode7-tests/<rom>.sfc` and copy the results back here.

[r]: https://github.com/undisbeliever/snes-test-roms
