# NESER offset-per-tile test ROMs

NESER-authored offset-per-tile (BG modes 2/4/6) test ROMs (issue
neser#2881), written against the undisbeliever bass test ROM
framework (zlib license, see [LICENSE](./LICENSE); skeletons derived
from [undisbeliever/snes-test-roms][r]). Sources live in
[`src/`](./src/) and the built `.sfc` files are committed alongside
them. No redistributable third-party ROM covering offset-per-tile
could be found, so these were authored for NESER.

## The shared scene

All ROMs render a static scene from
[`src/_opt-scene.inc`](./src/_opt-scene.inc): BG1 (and, where used,
BG2) are filled with solid 8x8 colour tiles - horizontal bands,
vertical stripes or diagonal bands - so a per-column scroll override
re-arranges the coloured pattern in an unambiguous way. BG3's tilemap
(word 0x0800) is the offset map: row 0 holds the 32 horizontal
entries, row 1 the 32 vertical entries. BG3HOFS/BG3VOFS stay 0.

## ROMs

  - `opt-m2-bg1-v.sfc` - mode 2, growing vertical offsets (4*j, full
    pixel granularity) on BG1; every fourth entry lacks the BG1 flag
    and must not apply; leftmost column unaffected, entry j maps to
    screen column j+1.
  - `opt-m2-bg1-h.sfc` - mode 2, horizontal offsets 8*j on even
    entries; odd entries lack the BG1 flag and must not apply.
  - `opt-m2-fine-hofs.sfc` - mode 2, BG1HOFS = 5; horizontal entries
    8*j + (j%8): the low 3 bits of horizontal entries are ignored and
    the 5px fine scroll from BG1HOFS is retained in every column.
  - `opt-m2-bg2-select.sfc` - mode 2, BG1 (with transparent gap
    columns) over BG2; vertical entries cycle BG2-only / BG1-only /
    both apply flags.
  - `opt-m4.sfc` - mode 4 (BG1 8bpp), single offset row: bit 15
    selects H (even entries, 8*j) or V (odd entries, 4*j) per column;
    the second tilemap row holds flag-less 0x03FF filler that mode 4
    must never read.
  - `opt-m6.sfc` - mode 6 (hires), both offset rows applied to BG1
    (H = 8*j, V = 4*j) over diagonal bands.

## Rebuilding

Same procedure as
[`../neser-colormath-tests/`](../neser-colormath-tests/README.md):
copy `src/` into the undisbeliever source mirror as
`src/neser-opt-tests`, `make directories`, build
`bin/neser-opt-tests/<rom>.sfc` and copy the results back here.

[r]: https://github.com/undisbeliever/snes-test-roms
