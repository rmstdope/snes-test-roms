// Colour-math OBJ palette rule test (NESER #2880)
//
// Shared quadrant scene plus eight 8x8 sprites (priority 3, one per
// OBJ palette 0-7, all the same grey colour) in a row at y = 56,
// over the white sub-screen bar. CGADSUB = add + half with math on
// OBJ + BG1 + backdrop. On hardware colour math applies ONLY to
// sprites using palettes 4-7: the left four sprites must stay raw
// grey, the right four must blend with the sub screen below them.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER CM OBJ PALETTES"
define VERSION = 0

architecture wdc65816-strict

include "../common.inc"

createCodeBlock(code,       0x808000, 0x80ffaf)

createRamBlock(lowram,      0x7e0100, 0x7e1f7f)
createRamBlock(stack,       0x7e1f80, 0x7e1fff)

constant VRAM_OBJ_TILES_WADDR = 0x6000

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

include "_colormath-scene.inc"


// Setup PPU registers and load data to the PPU.
//
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupPpu {
    jsr     SetupColormathScene

    lda.b   #OBSEL.size.s8_16 | (VRAM_OBJ_TILES_WADDR / OBSEL.base.walign) << OBSEL.base.shift
    sta.w   OBSEL

    ldx.w   #VRAM_OBJ_TILES_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Obj_Tiles)

    lda.b   #128
    sta.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Obj_Palette)

    stz.w   OAMADDL
    stz.w   OAMADDH
    Dma.ForceBlank.ToOam(Resources.Obj_Oam)

    // sprites join BG1 on the main screen
    lda.b   #TM.bg1 | TM.obj
    sta.w   TM

    lda.b   #CGWSEL.addSubscreen
    sta.w   CGWSEL

    // add, half, math on OBJ + BG1 + backdrop
    lda.b   #%01110001
    sta.w   CGADSUB

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

Obj_Tiles:
    // tile 0: all pixels colour 1 (plane 0 set)
    variable _t = 0
    while _t < 8 {
        db  0xff, 0x00
        _t = _t + 1
    }
    fill    16

constant Obj_Tiles.size = pc() - Obj_Tiles


// Every OBJ palette's colour 1 is the same grey so the maths, not
// the palette contents, is the only visible difference.
Obj_Palette:
    variable _p = 0
    while _p < 8 {
        dw      0, ToPalette(20, 20, 20)
        fill    (16 - 2) * 2
        _p = _p + 1
    }

constant Obj_Palette.size = pc() - Obj_Palette


variable __nObjects = 0

// OAM attribute byte: %vhoopppN (v/h flip, oo priority, ppp palette,
// N tile-number bit 8).
macro _obj(evaluate x, evaluate y, evaluate tile, evaluate attr) {
    db  {x}, {y}, {tile}, {attr}
    __nObjects = __nObjects + 1
}

Obj_Oam:
    // Eight 8x8 sprites in a row over the white sub bar (rows 48-71),
    // priority 3, palettes 0-7.
    constant N_SPRITES = 8
    constant X_START   = 16
    constant X_SPACING = 28
    constant Y_POS     = 56

    variable _i = 0
    while _i < N_SPRITES {
        _obj(X_START + _i * X_SPACING, Y_POS, 0, %00110000 | _i << 1)
        _i = _i + 1
    }

    fill    (128 - __nObjects) * 4, -16

Obj_OamHiTable:
    // All eight sprites use the small (8x8) size, X bit 8 clear.
    fill    32

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
