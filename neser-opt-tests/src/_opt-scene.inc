// Shared offset-per-tile test scene (NESER #2881)
//
// BG1 (and optionally BG2) are filled with solid 8x8 colour tiles so
// any per-column scroll override is visible as a re-arrangement of
// coloured stripes/bands:
//
//   - OPT_BG1_HSTRIPES: BG1 tilemap row r uses tile (r%8)+1
//     (horizontal bands; vertical offsets are visible).
//   - OPT_BG1_VSTRIPES: BG1 tilemap column c uses tile (c%8)+1
//     (vertical stripes; horizontal offsets are visible).
//   - OPT_BG1_DIAGONAL: BG1 tilemap entry (r,c) uses tile
//     ((r+c)%8)+1 (diagonal bands; both offset kinds are visible).
//   - OPT_BG1_GAPS: BG1 leaves odd tilemap columns transparent so a
//     lower-priority BG2 shows through.
//   - OPT_BG2_HSTRIPES: BG2 tilemap row r uses tile (r%8)+1 with
//     palette 1 (BG2 band colours differ from BG1's).
//   - OPT_MODE4: BG1 uses the 8bpp tile set at VRAM word 0x2000
//     (BG modes 3/4); otherwise BG1/BG2 use the 4bpp set at 0x1000.
//
// BG3 is the offset-per-tile map at VRAM word 0x0800: tilemap row 0
// (words 0-31) holds the horizontal entries, row 1 (words 32-63) the
// vertical entries. Each ROM provides a 64-word `OptData` table with
// an `OptData.size` constant. BG3HOFS/BG3VOFS stay at the reset
// value 0.
//
// Each ROM writes BGMODE, TM and the BG1/BG2 scroll registers itself
// after calling SetupOptScene.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

constant VRAM_BG1_MAP_WADDR = 0x0000
constant VRAM_BG2_MAP_WADDR = 0x0400
constant VRAM_BG3_MAP_WADDR = 0x0800
constant VRAM_BG_TILES4_WADDR = 0x1000
constant VRAM_BG_TILES8_WADDR = 0x2000

// Offset-per-tile entry flag bits
constant OPT_APPLY_BG1 = 1 << 13
constant OPT_APPLY_BG2 = 1 << 14
constant OPT_VERTICAL = 1 << 15


// Setup tilemaps, tiles, palettes and the OPT table for the scene.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupOptScene {
    // BG1 tilemap at word 0x0000, 32x32
    stz.w   BG1SC
    // BG2 tilemap at word 0x0400, 32x32
    lda.b   #(VRAM_BG2_MAP_WADDR / 1024) << 2
    sta.w   BG2SC
    // BG3 (offset-per-tile) tilemap at word 0x0800, 32x32
    lda.b   #(VRAM_BG3_MAP_WADDR / 1024) << 2
    sta.w   BG3SC

    if {defined OPT_MODE4} {
        // BG1 8bpp tiles at word 0x2000
        lda.b   #(VRAM_BG_TILES8_WADDR / 4096)
        sta.w   BG12NBA
    } else {
        // BG1 + BG2 4bpp tiles at word 0x1000
        lda.b   #(VRAM_BG_TILES4_WADDR / 4096) | ((VRAM_BG_TILES4_WADDR / 4096) << 4)
        sta.w   BG12NBA
    }

    ldx.w   #VRAM_BG_TILES4_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Tiles4bpp)

    if {defined OPT_MODE4} {
        ldx.w   #VRAM_BG_TILES8_WADDR
        stx.w   VMADD
        Dma.ForceBlank.ToVram(Resources.Tiles8bpp)
    }

    ldx.w   #VRAM_BG1_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg1_Map)

    if {defined OPT_BG2_HSTRIPES} {
        ldx.w   #VRAM_BG2_MAP_WADDR
        stx.w   VMADD
        Dma.ForceBlank.ToVram(Resources.Bg2_Map)
    }

    ldx.w   #VRAM_BG3_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(OptData)

    stz.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Palette)

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


if {defined OPT_MODE4} {
// 8bpp tiles: tile 0 transparent, tiles 1-8 all pixels colour 1-8
// (same CGRAM entries as the 4bpp palette-0 colours).
Tiles8bpp:
    fill    64

    variable _t8 = 1
    variable _pp = 0
    variable _row8 = 0
    while _t8 <= 8 {
        _pp = 0
        while _pp < 4 {
            _row8 = 0
            while _row8 < 8 {
                if (_t8 >> (_pp * 2)) & 1 {
                    db  0xff
                } else {
                    db  0x00
                }
                if (_t8 >> (_pp * 2)) & 2 {
                    db  0xff
                } else {
                    db  0x00
                }
                _row8 = _row8 + 1
            }
            _pp = _pp + 1
        }
        _t8 = _t8 + 1
    }

constant Tiles8bpp.size = pc() - Tiles8bpp
}


// CGRAM 0: backdrop. Palette 0 colours 1-8: BG1 stripe colours.
// Palette 1 colours 1-8: BG2 stripe colours (dimmer, distinct hues).
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


// BG1 tilemap, style selected by the OPT_BG1_* defines.
Bg1_Map:
    variable _r = 0
    variable _c = 0
    variable _tile = 0
    while _r < 32 {
        _c = 0
        while _c < 32 {
            _tile = 0
            if {defined OPT_BG1_HSTRIPES} {
                _tile = (_r % 8) + 1
            }
            if {defined OPT_BG1_VSTRIPES} {
                _tile = (_c % 8) + 1
            }
            if {defined OPT_BG1_DIAGONAL} {
                _tile = ((_r + _c) % 8) + 1
            }
            if {defined OPT_BG1_GAPS} {
                if _c % 2 == 1 {
                    _tile = 0
                }
            }
            dw  _tile
            _c = _c + 1
        }
        _r = _r + 1
    }

constant Bg1_Map.size = pc() - Bg1_Map


if {defined OPT_BG2_HSTRIPES} {
// BG2 tilemap: horizontal bands using palette 1.
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

}
