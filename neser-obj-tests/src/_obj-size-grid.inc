// OBJ size-pair test, parameterized by OBSEL size select (NESER #2879)
//
// Renders one small and one large sprite side by side for the OBSEL size
// select value in SIZE_SELECT (0-7). The hex glyph tiles display their own
// tile numbers, so the rendered grid shows exactly which tiles were
// fetched for each sprite dimension (including the undocumented 16x32 /
// 32x64 and 16x32 / 32x32 pairs of size selects 6 and 7).
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
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

    lda.b   #(SIZE_SELECT << 5) | (VRAM_OBJ_TILES_WADDR / OBSEL.base.walign) << OBSEL.base.shift
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
    _P($33cccc) // hsl(180, 60, 50)
    // Pad the six unused OBJ palettes.
    fill    6 * 16 * 2

constant Obj_Palette.size = pc() - Obj_Palette


variable __nObjects = 0

// OAM attribute byte: %vhoopppN.
macro _obj(evaluate x, evaluate y, evaluate tile, evaluate attr) {
    db  {x}, {y}, {tile}, {attr}
    __nObjects = __nObjects + 1
}

Obj_Oam:
    // One small sprite (palette 0, red) and one large sprite (palette 1,
    // cyan), top-aligned, with room for the largest (64x64) pair.
    _obj(32, 64, 0, 0 << 1)
    _obj(128, 64, 0, 1 << 1)

    // Park the unused sprites at X = 256 (via the high-table X bit 8),
    // fully off-screen for every size. The usual y = 240 filler
    // convention is not off-screen here: the 32px-tall small sizes of
    // OBSEL 6/7 would wrap around to the top of the screen.
    variable _i = __nObjects
    while _i < 128 {
        _obj(0, 240, 0, 0)
        _i = _i + 1
    }

Obj_OamHiTable:
    // Sprite 0 small, sprite 1 large, X bit 8 clear; all parked sprites
    // small with X bit 8 set.
    db  %01011000
    fill    31, %01010101

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
