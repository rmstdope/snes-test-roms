// OBJ vertical wrap-around test (NESER #2879)
//
// A sprite whose Y position puts part of it past line 255 wraps around
// to the top of the screen. Uses the 16x32 small size of OBSEL mode 6 so
// the wrap also exercises rectangular tile-row fetching:
//
//   - control: a 16x32 sprite fully visible at (64, 64) -- tile rows
//     00/01, 10/11, 20/21, 30/31 top to bottom.
//   - wrap: the same sprite at (128, 240): rows 2-3 (tiles 20/21 and
//     30/31) must appear at screen lines 0-15.
//   - wrap + V flip: at (192, 240): the visible wrapped rows are the
//     flipped rows 0-1 (tiles 10/11 above 00/01, each glyph upside
//     down).
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 NESER contributors
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OBJ Y WRAP"
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

    lda.b   #OBSEL.size.s16x32_32x64 | (VRAM_OBJ_TILES_WADDR / OBSEL.base.walign) << OBSEL.base.shift
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
    _P($ccad33) // 1: yellow - wrapped
    _P($33cccc) // 2: teal   - wrapped + V flip
    // Pad the five unused OBJ palettes.
    fill    5 * 16 * 2

constant Obj_Palette.size = pc() - Obj_Palette


variable __nObjects = 0

// OAM attribute byte: %vhoopppN.
macro _obj(evaluate x, evaluate y, evaluate tile, evaluate attr) {
    db  {x}, {y}, {tile}, {attr}
    __nObjects = __nObjects + 1
}

Obj_Oam:
    _obj(64, 64, 0, 0 << 1)              // control, fully visible
    _obj(128, 240, 0, 1 << 1)            // wraps: rows 2-3 at lines 0-15
    _obj(192, 240, 0, (1 << 7) | (2 << 1)) // wraps, V flipped

    // Park the unused sprites at X = 256 (fully off-screen at any size).
    // Their Y deliberately avoids the wrap lines: at X = 256 a sprite is
    // invisible but still counts toward the per-scanline range/time
    // limits, and 125 parked 16x32 sprites at y = 240 would wrap into
    // lines 0-15 and starve the visible wrapped sprites' tile slivers.
    // y = 160 puts them on lines where this ROM renders nothing.
    variable _i = __nObjects
    while _i < 128 {
        _obj(0, 160, 0, 0)
        _i = _i + 1
    }

Obj_OamHiTable:
    // Sprites 0-2 use the small (16x32) size with X bit 8 clear; parked
    // sprites are small with X bit 8 set.
    db  %01000000
    fill    31, %01010101

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
