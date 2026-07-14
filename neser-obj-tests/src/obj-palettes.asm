// OBJ palette selection test (NESER #2879)
//
// Renders eight 16x16 sprites in a row, all showing the same tile glyphs,
// each using one of the eight OBJ palettes (CGRAM 128 + 16*p). A static
// screen: every sprite must appear in its own hue, left to right palette
// 0 through 7.
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 NESER contributors
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OBJ PALETTES"
define VERSION = 0

architecture wdc65816-strict

include "../common.inc"

createCodeBlock(code,       0x808000, 0x80ffaf)

createRamBlock(lowram,      0x7e0100, 0x7e1f7f)
createRamBlock(stack,       0x7e1f80, 0x7e1fff)

constant VRAM_OBJ_TILES_WADDR = $6000

include "../reset_handler.inc"
include "../break_handler.inc"
include "../dma_forceblank.inc"

// VBlank routine.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
macro VBlank() {
    assert8a()
    assert16i()
}

include "../vblank_interrupts.inc"


// Setup PPU registers and load data to the PPU.
//
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupPpu {
    stz.w   BGMODE

    lda.b   #OBSEL.size.s8_16 | (VRAM_OBJ_TILES_WADDR / OBSEL.base.walign) << OBSEL.base.shift
    sta.w   OBSEL

    ldx.w   #VRAM_OBJ_TILES_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Obj_Tiles)

    stz.w   CGADD
    stz.w   CGDATA
    stz.w   CGDATA

    lda.b   #128
    sta.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Obj_Palette)

    stz.w   OAMADDL
    stz.w   OAMADDH
    Dma.ForceBlank.ToOam(Resources.Obj_Oam)

    lda.b   #TM.obj
    sta.w   TM

    rts
}


au()
iu()
code()
function Main {
    rep     #$30
    sep     #$20
a8()
i16()
    lda.b   #INIDISP.force | 0x0f
    sta.w   INIDISP

    jsr     SetupPpu

    EnableVblankInterrupts()

    jsr     WaitFrame

    lda.b   #0x0f
    sta.w   INIDISP

    MainLoop:
        jsr     WaitFrame
        jmp     MainLoop
}


namespace Resources {
    insert Obj_Tiles,    "../../gen/obj-tests/hex8-4bpp-tiles.tiles"


Obj_Palette:
    macro _P(evaluate rgb) {
        evaluate r = (({rgb} >> 16) & 0xff) >> 3
        evaluate g = (({rgb} >>  8) & 0xff) >> 3
        evaluate b = (({rgb} >>  0) & 0xff) >> 3

        dw      0,  ToPalette({r}, {g}, {b}), ToPalette({r}, {g}, {b})
        fill    (16 - 3) * 2
    }
    _P($cc3333) // hsl(  0, 60, 50)
    _P($ccad33) // hsl( 45, 60, 50)
    _P($80cc33) // hsl( 90, 60, 50)
    _P($33cc59) // hsl(135, 60, 50)
    _P($33cccc) // hsl(180, 60, 50)
    _P($3359cc) // hsl(225, 60, 50)
    _P($8033cc) // hsl(270, 60, 50)
    _P($cc33a6) // hsl(315, 60, 50)

constant Obj_Palette.size = pc() - Obj_Palette


variable __nObjects = 0

// OAM attribute byte: %vhoopppN (v/h flip, oo priority, ppp palette,
// N tile-number bit 8).
macro _obj(evaluate x, evaluate y, evaluate tile, evaluate attr) {
    db  {x}, {y}, {tile}, {attr}
    __nObjects = __nObjects + 1
}

Obj_Oam:
    // Eight 16x16 sprites in a row, same char, palettes 0-7.
    constant N_SPRITES = 8
    constant X_START   = 16
    constant X_SPACING = 28
    constant Y_POS     = 104

    variable _i = 0
    while _i < N_SPRITES {
        _obj(X_START + _i * X_SPACING, Y_POS, 0, _i << 1)
        _i = _i + 1
    }

    fill    (128 - __nObjects) * 4, -16

Obj_OamHiTable:
    // All eight sprites use the large (16x16) size, X bit 8 clear.
    assert(N_SPRITES % 4 == 0)
    fill    N_SPRITES / 4, %10101010

    fill    (128 - __nObjects) / 4, 0

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
