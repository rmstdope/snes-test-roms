// OAM high-table X bit 8 test (NESER #2879)
//
// The 9th X bit lives in the OAM high table and makes X signed-ish:
// 32x32 sprites are placed at X = 32 (control, fully visible),
// X = 240 (clipped by the right edge), X = 496 i.e. -16 (left half
// clipped, right half visible at the left edge) and X = 256 (fully
// off-screen -- it must not appear anywhere).
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 NESER contributors
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OAM X8"
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

    lda.b   #OBSEL.size.s8_32 | (VRAM_OBJ_TILES_WADDR / OBSEL.base.walign) << OBSEL.base.shift
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
    _P($cc3333) // 0: red    - control
    _P($ccad33) // 1: yellow - right-edge clip
    _P($33cccc) // 2: teal   - negative X
    _P($8033cc) // 3: purple - X=256 (must be invisible)
    // Pad the four unused OBJ palettes.
    fill    4 * 16 * 2

constant Obj_Palette.size = pc() - Obj_Palette


variable __nObjects = 0

// OAM attribute byte: %vhoopppN.
macro _obj(evaluate x, evaluate y, evaluate tile, evaluate attr) {
    db  {x}, {y}, {tile}, {attr}
    __nObjects = __nObjects + 1
}

Obj_Oam:
    _obj(32, 64, 0, 0 << 1)          // control, X = 32
    _obj(240, 64, 0, 1 << 1)         // X = 240: right 16px clipped
    _obj(240, 128, 0, 2 << 1)        // X = 496 (-16) via X bit 8: left half clipped
    _obj(0, 128, 0, 3 << 1)          // X = 256 via X bit 8: fully off-screen

    fill    (128 - __nObjects) * 4, -16

Obj_OamHiTable:
    // Per sprite (2 bits, LSB first): 0 = large; 1 = large; 2 = large +
    // X bit 8; 3 = large + X bit 8.
    db  %11111010
    fill    31, 0

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
