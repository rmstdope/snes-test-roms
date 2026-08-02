// Shared mid-frame hires-transition test scene (NESER #3034)
//
// The scene is built so that a scanline rendered in a hires mode and a
// scanline rendered in a native mode look nothing alike, which is what
// makes an HDMA-driven mid-frame switch legible in a screenshot:
//
//   - BG1 (main screen): vertical stripes, tilemap column c uses tile
//     (c%8)+1, palette 0 (saturated colours).
//   - BG2 (sub screen): horizontal bands, tilemap row r uses tile
//     (r%8)+1, palette 1 (dimmer, distinct hues).
//   - CGWSEL.addSubscreen is set, so in a hires mode the sub screen
//     supplies the even output column and the main screen the odd one.
//
// A native line therefore shows BG1's vertical stripes alone (BG2 is
// only a colour-math operand, and colour math is off), while a hires
// line shows BG1 and BG2 interleaved per half-pixel. The boundary
// between the two halves of the frame is unmistakable.
//
// Each ROM sets up its own HDMA channel and calls SetupHiresScene.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

constant VRAM_BG1_MAP_WADDR = 0x0000
constant VRAM_BG2_MAP_WADDR = 0x0400
constant VRAM_BG_TILES4_WADDR = 0x1000

// Display line at which the HDMA table switches the frame from a
// native mode to a hires one. Well inside the visible region so both
// halves are large, and not a multiple of 8, so a whole-tile-row
// off-by-one in the switch would be visible rather than hidden by the
// scene's own 8-pixel period.
constant HIRES_SWITCH_LINE = 100


// Setup tilemaps, tiles and palettes for the scene.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupHiresScene {
    // BG1 tilemap at word 0x0000, 32x32
    stz.w   BG1SC
    // BG2 tilemap at word 0x0400, 32x32
    lda.b   #(VRAM_BG2_MAP_WADDR / 1024) << 2
    sta.w   BG2SC

    // BG1 + BG2 4bpp tiles at word 0x1000
    lda.b   #(VRAM_BG_TILES4_WADDR / 4096) | ((VRAM_BG_TILES4_WADDR / 4096) << 4)
    sta.w   BG12NBA

    ldx.w   #VRAM_BG_TILES4_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Tiles4bpp)

    ldx.w   #VRAM_BG1_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg1_Map)

    ldx.w   #VRAM_BG2_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg2_Map)

    stz.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Palette)

    // BG1 on the main screen, BG2 on the sub screen, sub screen
    // displayed (the hires interleave needs it).
    lda.b   #TM.bg1
    sta.w   TM

    lda.b   #TS.bg2
    sta.w   TS

    lda.b   #CGWSEL.addSubscreen
    sta.w   CGWSEL

    stz.w   CGADSUB

    rts
}


namespace Resources {

// 4bpp tiles: tile 0 transparent, tiles 1-8 all pixels colour 1-8.
Tiles4bpp:
    fill    32

    variable _t = 1
    variable _row = 0
    while _t <= 8 {
        _row = 0
        while _row < 8 {
            if _t & 1 {
                db  0xff
            } else {
                db  0x00
            }
            if _t & 2 {
                db  0xff
            } else {
                db  0x00
            }
            _row = _row + 1
        }
        _row = 0
        while _row < 8 {
            if _t & 4 {
                db  0xff
            } else {
                db  0x00
            }
            if _t & 8 {
                db  0xff
            } else {
                db  0x00
            }
            _row = _row + 1
        }
        _t = _t + 1
    }

constant Tiles4bpp.size = pc() - Tiles4bpp


// CGRAM 0: backdrop. Palette 0 colours 1-8: BG1 stripe colours.
// Palette 1 colours 1-8: BG2 band colours (dimmer, distinct hues).
Palette:
    dw      ToPalette( 2,  2,  2)
    dw      ToPalette(31,  0,  0), ToPalette( 0, 31,  0), ToPalette( 0,  0, 31)
    dw      ToPalette(31, 31,  0), ToPalette(31,  0, 31), ToPalette( 0, 31, 31)
    dw      ToPalette(31, 31, 31), ToPalette(31, 16,  0)
    fill    (16 - 9) * 2
    dw      0
    dw      ToPalette(15,  4,  4), ToPalette( 4, 15,  4), ToPalette( 4,  4, 15)
    dw      ToPalette(15, 15,  4), ToPalette(15,  4, 15), ToPalette( 4, 15, 15)
    dw      ToPalette(15, 15, 15), ToPalette(15,  8,  4)
    fill    (16 - 9) * 2

constant Palette.size = pc() - Palette


// BG1 tilemap: vertical stripes (column c = tile (c%8)+1).
Bg1_Map:
    variable _r = 0
    variable _c = 0
    while _r < 32 {
        _c = 0
        while _c < 32 {
            dw  (_c % 8) + 1
            _c = _c + 1
        }
        _r = _r + 1
    }

constant Bg1_Map.size = pc() - Bg1_Map


// BG2 tilemap: horizontal bands (row r = tile (r%8)+1) in palette 1.
Bg2_Map:
    variable _r2 = 0
    variable _c2 = 0
    while _r2 < 32 {
        _c2 = 0
        while _c2 < 32 {
            dw  ((_r2 % 8) + 1) | (1 << 10)
            _c2 = _c2 + 1
        }
        _r2 = _r2 + 1
    }

constant Bg2_Map.size = pc() - Bg2_Map

}
