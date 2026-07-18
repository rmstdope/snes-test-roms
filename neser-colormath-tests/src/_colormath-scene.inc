// Shared colour-math test scene (NESER #2880)
//
// Mode 1 quadrant scene:
//   - BG1 (main screen): 8 vertical bars, 24px wide, columns 0-191,
//     covering every visible row (0-223). Palette colour 1 per bar.
//   - BG2 (sub screen): 8 horizontal bars, 24px tall, rows 0-191,
//     covering every column. Palette colour 2 per bar.
//   - Backdrop (CGRAM 0): (4, 8, 12).
//
// This yields four regions:
//   - main bar x sub bar: 64 distinct (main, sub) colour-math pairs,
//   - columns 192-255, rows 0-191: backdrop main x sub bar,
//   - columns 0-191, rows 192-223: main bar x transparent sub
//     (fixed-colour fallback; halving is disabled on hardware),
//   - bottom-right corner: backdrop main x transparent sub.
//
// Bar colours are chosen so one screen discriminates clamp-at-31
// (16+16), floor-at-0 (8-16), and halve-after-add ((15+1)/2 = 8).
//
// If CM_BG2_CENTER_ONLY is defined, BG2 bars span only tile columns
// 10-21 so both sub-present and sub-transparent behaviour is visible
// on every horizontal bar row.
//
// Requires: "../common.inc", "../dma_forceblank.inc" already included.
// Provides: SetupColormathScene and namespace Resources.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

constant VRAM_BG1_MAP_WADDR = 0x0000
constant VRAM_BG2_MAP_WADDR = 0x0400
constant VRAM_BG_TILES_WADDR = 0x1000


// Setup BG mode, tilemaps, tiles and palettes for the shared scene.
//
// Sets TM = BG1 (main) and TS = BG2 (sub); callers override afterwards
// as needed.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupColormathScene {
    lda.b   #BGMODE.mode1
    sta.w   BGMODE

    // BG1 tilemap at word 0x0000, 32x32
    stz.w   BG1SC
    // BG2 tilemap at word 0x0400, 32x32
    lda.b   #(VRAM_BG2_MAP_WADDR / 1024) << 2
    sta.w   BG2SC
    // BG1 + BG2 tiles at word 0x1000
    lda.b   #(VRAM_BG_TILES_WADDR / 4096) | ((VRAM_BG_TILES_WADDR / 4096) << 4)
    sta.w   BG12NBA

    ldx.w   #VRAM_BG_TILES_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Cm_Tiles)

    ldx.w   #VRAM_BG1_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg1_Map)

    ldx.w   #VRAM_BG2_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg2_Map)

    stz.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Cm_Palette)

    lda.b   #TM.bg1
    sta.w   TM
    lda.b   #TS.bg2
    sta.w   TS

    rts
}


namespace Resources {

Cm_Tiles:
    // tile 0: transparent (all pixels colour 0)
    fill    32

    // tile 1: all pixels colour 1 (plane 0 set)
    variable _t = 0
    while _t < 8 {
        db  0xff, 0x00
        _t = _t + 1
    }
    fill    16

    // tile 2: all pixels colour 2 (plane 1 set)
    _t = 0
    while _t < 8 {
        db  0x00, 0xff
        _t = _t + 1
    }
    fill    16

constant Cm_Tiles.size = pc() - Cm_Tiles


// Palette p: colour 1 = main bar colour M[p], colour 2 = sub bar
// colour S[p]. CGRAM word 0 (palette 0 colour 0) is the backdrop.
Cm_Palette:
    dw      ToPalette( 4,  8, 12), ToPalette( 8, 16, 24), ToPalette( 8,  8,  8)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette(31, 31, 31), ToPalette(16, 16, 16)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette(15, 15, 15), ToPalette(31, 31, 31)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette( 1,  3,  5), ToPalette( 1,  1,  1)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette( 0,  0,  0), ToPalette( 0,  2,  4)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette(16, 16, 16), ToPalette(17, 17, 17)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette(30,  1, 17), ToPalette( 1, 30, 14)
    fill    (16 - 3) * 2
    dw      0,                     ToPalette(15,  0, 31), ToPalette( 0, 31,  1)
    fill    (16 - 3) * 2

constant Cm_Palette.size = pc() - Cm_Palette


// BG1: vertical bars. Tile columns 0-23 = bar (column / 3) using
// tile 1, every tilemap row (the visible 28 rows all show bars).
// Columns 24-31 transparent.
Bg1_Map:
    variable _r = 0
    variable _c = 0
    while _r < 32 {
        _c = 0
        while _c < 32 {
            if _c < 24 {
                dw  1 | (_c / 3) << 10
            } else {
                dw  0
            }
            _c = _c + 1
        }
        _r = _r + 1
    }

constant Bg1_Map.size = pc() - Bg1_Map


// BG2: horizontal bars. Tilemap rows 0-23 = bar (row / 3) using
// tile 2. Rows 24-31 transparent (sub screen shows through to the
// fixed-colour fallback on the bottom strip).
Bg2_Map:
    _r = 0
    while _r < 32 {
        _c = 0
        while _c < 32 {
            if {defined CM_BG2_CENTER_ONLY} {
                if _r < 24 && _c >= 10 && _c < 22 {
                    dw  2 | (_r / 3) << 10
                } else {
                    dw  0
                }
            } else {
                if _r < 24 {
                    dw  2 | (_r / 3) << 10
                } else {
                    dw  0
                }
            }
            _c = _c + 1
        }
        _r = _r + 1
    }

constant Bg2_Map.size = pc() - Bg2_Map

}
