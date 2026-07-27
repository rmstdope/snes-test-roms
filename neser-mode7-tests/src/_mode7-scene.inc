// Shared Mode 7 test scene (NESER #2881)
//
// A 128x128-tile (1024x1024 px) Mode 7 tilemap built from solid
// colour tiles, asymmetric so wrapping, flips and rotation are all
// unambiguous:
//
//   - 1-tile white border ring around the map edge,
//   - 16x16-tile corner blocks: red (top-left), green (top-right),
//     blue (bottom-left), yellow (bottom-right),
//   - a 4-tile-wide magenta centre cross,
//   - a cyan / dark-grey checkerboard (8x8-tile squares) elsewhere.
//
// Tile 0 is a solid orange "screen-over fill" marker (only visible
// via M7SEL out-of-screen = tile 0). The backdrop is dark blue (only
// visible via M7SEL out-of-screen = colour 0).
//
// Provides SetupMode7Scene (VRAM + CGRAM upload) and the
// SetMode7Matrix macro. Each ROM writes BGMODE, TM, M7SEL and the
// matrix itself.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib


// Write the Mode 7 matrix, centre and scroll registers.
//
// REQUIRES: 8 bit A, DB = 0x80
macro SetMode7Matrix(evaluate a, evaluate b, evaluate c, evaluate d, evaluate x, evaluate y, evaluate hofs, evaluate vofs) {
    lda.b   #{a} & 0xff
    sta.w   M7A
    lda.b   #({a} >> 8) & 0xff
    sta.w   M7A

    lda.b   #{b} & 0xff
    sta.w   M7B
    lda.b   #({b} >> 8) & 0xff
    sta.w   M7B

    lda.b   #{c} & 0xff
    sta.w   M7C
    lda.b   #({c} >> 8) & 0xff
    sta.w   M7C

    lda.b   #{d} & 0xff
    sta.w   M7D
    lda.b   #({d} >> 8) & 0xff
    sta.w   M7D

    lda.b   #{x} & 0xff
    sta.w   M7X
    lda.b   #({x} >> 8) & 0x1f
    sta.w   M7X

    lda.b   #{y} & 0xff
    sta.w   M7Y
    lda.b   #({y} >> 8) & 0x1f
    sta.w   M7Y

    lda.b   #{hofs} & 0xff
    sta.w   M7HOFS
    lda.b   #({hofs} >> 8) & 0x1f
    sta.w   M7HOFS

    lda.b   #{vofs} & 0xff
    sta.w   M7VOFS
    lda.b   #({vofs} >> 8) & 0x1f
    sta.w   M7VOFS
}


// Upload the Mode 7 tilemap (VRAM low bytes), tiles (VRAM high
// bytes) and palette.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupMode7Scene {
    ldx.w   #0
    stx.w   VMADD
    Dma.ForceBlank.ToVramL(Resources.M7_Map)

    ldx.w   #0
    stx.w   VMADD
    Dma.ForceBlank.ToVramH(Resources.M7_Tiles)

    stz.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Palette)

    rts
}


namespace Resources {

// Mode 7 tiles are 8bpp linear: one byte per pixel (CGRAM index).
// Tile 0 = orange fill marker (colour 15), tiles 1-8 = colours 1-8.
M7_Tiles:
    fill    64, 15

    variable _t = 1
    while _t <= 8 {
        fill    64, _t
        _t = _t + 1
    }

constant M7_Tiles.size = pc() - M7_Tiles


// CGRAM: 0 = dark blue backdrop, 1-8 = tile colours, 15 = orange.
Palette:
    dw      ToPalette( 0,  0,  6)
    dw      ToPalette( 6,  6,  6), ToPalette(31,  0,  0), ToPalette( 0, 31,  0)
    dw      ToPalette( 0,  0, 31), ToPalette(31, 31,  0), ToPalette(31,  0, 31)
    dw      ToPalette( 0, 31, 31), ToPalette(31, 31, 31)
    fill    (15 - 9) * 2
    dw      ToPalette(31, 16,  0)

constant Palette.size = pc() - Palette


// 128x128 tilemap bytes.
M7_Map:
    variable _ty = 0
    variable _tx = 0
    variable _tile = 0
    while _ty < 128 {
        _tx = 0
        while _tx < 128 {
            // checkerboard base
            if (_tx / 8 + _ty / 8) % 2 == 0 {
                _tile = 1
            } else {
                _tile = 7
            }
            // centre cross
            if (_tx >= 62 && _tx < 66) || (_ty >= 62 && _ty < 66) {
                _tile = 6
            }
            // corner blocks
            if _tx < 16 && _ty < 16 {
                _tile = 2
            }
            if _tx >= 112 && _ty < 16 {
                _tile = 3
            }
            if _tx < 16 && _ty >= 112 {
                _tile = 4
            }
            if _tx >= 112 && _ty >= 112 {
                _tile = 5
            }
            // border ring
            if _tx == 0 || _tx == 127 || _ty == 0 || _ty == 127 {
                _tile = 8
            }
            db  _tile
            _tx = _tx + 1
        }
        _ty = _ty + 1
    }

constant M7_Map.size = pc() - M7_Map

}
