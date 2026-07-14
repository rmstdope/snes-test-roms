// OBJ-vs-BG priority interaction test (NESER #2879)
//
// Mode 1 with only BG1 and OBJ enabled. BG1 shows two horizontal bands:
// a low-priority band (tilemap priority 0, blue) on screen row 12 and a
// high-priority band (tilemap priority 1, orange) on rows 13-14. Four
// 32x32 sprites with OAM priorities 0-3 start above the bands (top 8px
// over the backdrop) and hang down across both.
//
// Expected layering (mode 1, front to back with only BG1):
//   OBJ3 > BG1 pri-1 > OBJ2 > BG1 pri-0 > OBJ1 > OBJ0
//
//   - priority 3 sprite: fully visible over both bands
//   - priority 2 sprite: visible over the pri-0 band, hidden by pri-1
//   - priority 0/1 sprites: hidden by both bands, visible on backdrop
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OBJ BG PRIO"
define VERSION = 0

architecture wdc65816-strict

include "../common.inc"

createCodeBlock(code,       0x808000, 0x80ffaf)

createRamBlock(lowram,      0x7e0100, 0x7e1f7f)
createRamBlock(stack,       0x7e1f80, 0x7e1fff)

constant VRAM_OBJ_TILES_WADDR = $6000
constant VRAM_BG1_TILES_WADDR = $1000
constant VRAM_BG1_MAP_WADDR   = $0400

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
    lda.b   #1
    sta.w   BGMODE

    lda.b   #OBSEL.size.s8_32 | (VRAM_OBJ_TILES_WADDR / OBSEL.base.walign) << OBSEL.base.shift
    sta.w   OBSEL

    lda.b   #(VRAM_BG1_MAP_WADDR / BGXSC.base.walign) << BGXSC.base.shift | BGXSC.map.s32x32
    sta.w   BG1SC

    lda.b   #(VRAM_BG1_TILES_WADDR / BG12NBA.walign) << BG12NBA.bg1.shift
    sta.w   BG12NBA

    ldx.w   #VRAM_OBJ_TILES_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Obj_Tiles)

    ldx.w   #VRAM_BG1_TILES_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg_Tiles)

    ldx.w   #VRAM_BG1_MAP_WADDR
    stx.w   VMADD
    Dma.ForceBlank.ToVram(Resources.Bg_Tilemap)

    stz.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Bg_Palette)

    lda.b   #128
    sta.w   CGADD
    Dma.ForceBlank.ToCgram(Resources.Obj_Palette)

    stz.w   OAMADDL
    stz.w   OAMADDH
    Dma.ForceBlank.ToOam(Resources.Obj_Oam)

    lda.b   #TM.obj | TM.bg1
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


// Three 4bpp BG tiles: 0 transparent, 1 solid color 1, 2 solid color 2.
Bg_Tiles:
    fill    32, 0
    variable _r = 0
    while _r < 8 {
        db  $ff, $00
        _r = _r + 1
    }
    fill    16, 0
    variable _r = 0
    while _r < 8 {
        db  $00, $ff
        _r = _r + 1
    }
    fill    16, 0
constant Bg_Tiles.size = pc() - Bg_Tiles


// 32x32 tilemap: row 12 = pri-0 band (tile 1), rows 13-14 = pri-1 band
// (tile 2, tilemap priority bit set).
Bg_Tilemap:
    variable _row = 0
    while _row < 32 {
        variable _col = 0
        while _col < 32 {
            if _row == 12 {
                dw  1
            } else if (_row == 13) || (_row == 14) {
                dw  2 | (1 << 13)
            } else {
                dw  0
            }
            _col = _col + 1
        }
        _row = _row + 1
    }
constant Bg_Tilemap.size = pc() - Bg_Tilemap


Bg_Palette:
    // Backdrop black; color 1 dim blue (pri-0 band), color 2 dim orange
    // (pri-1 band).
    dw      0, ToPalette(6, 8, 18), ToPalette(20, 12, 4)
constant Bg_Palette.size = pc() - Bg_Palette


Obj_Palette:
    macro _P(evaluate rgb) {
        evaluate r = (({rgb} >> 16) & 0xff) >> 3
        evaluate g = (({rgb} >>  8) & 0xff) >> 3
        evaluate b = (({rgb} >>  0) & 0xff) >> 3

        dw      0,  ToPalette({r}, {g}, {b}), ToPalette({r}, {g}, {b})
        fill    (16 - 3) * 2
    }
    _P($cc3333) // 0: red    - OAM priority 0
    _P($ccad33) // 1: yellow - OAM priority 1
    _P($80cc33) // 2: green  - OAM priority 2
    _P($33cccc) // 3: teal   - OAM priority 3
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
    // Four 32x32 sprites, OAM priority equal to their palette index.
    // y = 88: rows 88-95 backdrop, 96-103 pri-0 band, 104-119 pri-1 band.
    variable _i = 0
    while _i < 4 {
        _obj(24 + _i * 56, 88, 0, (_i << 4) | (_i << 1))
        _i = _i + 1
    }

    fill    (128 - __nObjects) * 4, -16

Obj_OamHiTable:
    // Sprites 0-3 large (32x32), X bit 8 clear.
    db  %10101010
    fill    31, 0

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
