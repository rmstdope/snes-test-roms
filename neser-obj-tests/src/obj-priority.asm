// OBJ-vs-OBJ priority test (NESER #2879)
//
// Among overlapping sprites the lower OAM index is always in front,
// regardless of the OAM priority bits (those only order OBJ against
// backgrounds). Renders two clusters of overlapping 16x16 sprites in
// distinct palettes:
//
//   - Left: sprites 0 (red) and 1 (yellow) overlap; 0 must cover 1.
//     Sprite 1 carries a HIGHER OAM priority-bit value (3 vs 0), which
//     must NOT bring it in front of sprite 0.
//   - Right: sprites 2 (green), 3 (teal) and 4 (blue) form a staggered
//     stack; 2 covers 3 covers 4.
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 NESER contributors
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OBJ PRIORITY"
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
    _P($cc3333) // 0: red
    _P($ccad33) // 1: yellow
    _P($80cc33) // 2: green
    _P($33cccc) // 3: teal
    _P($3359cc) // 4: blue
    // Pad the three unused OBJ palettes.
    fill    3 * 16 * 2

constant Obj_Palette.size = pc() - Obj_Palette


variable __nObjects = 0

// OAM attribute byte: %vhoopppN.
macro _obj(evaluate x, evaluate y, evaluate tile, evaluate attr) {
    db  {x}, {y}, {tile}, {attr}
    __nObjects = __nObjects + 1
}

Obj_Oam:
    // Left cluster: 0 over 1 despite 1's higher priority bits.
    _obj(40, 96, 0, (0 << 4) | (0 << 1))
    _obj(48, 104, 0, (3 << 4) | (1 << 1))

    // Right cluster: 2 over 3 over 4.
    _obj(160, 96, 0, 2 << 1)
    _obj(168, 104, 0, 3 << 1)
    _obj(176, 112, 0, 4 << 1)

    fill    (128 - __nObjects) * 4, -16

Obj_OamHiTable:
    // Sprites 0-4 large (16x16), X bit 8 clear.
    db  %10101010, %00000010
    fill    30, 0

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
