// OAM first-sprite priority rotation test (NESER #2879)
//
// When OAMADDH bit 7 is set, sprite priority evaluation starts at the
// sprite selected by the OAM word address (index = OAMADD >> 1) instead
// of sprite 0 (implementation-backed: Mesen2 SnesPpu.cpp evaluates from
// (InternalOamAddress & 0x1FC) >> 2 when EnableOamPriority is set; ares
// object.cpp sets firstSprite = oamAddress >> 2 when oamPriority is set).
//
// This ROM sets OAMADD to sprite 2 with the rotation bit enabled after
// uploading OAM. Two overlapping pairs:
//
//   - Left: sprites 1 (yellow) and 2 (green) overlap. With rotation the
//     evaluation order is 2,3,...,127,0,1, so sprite 2 must cover
//     sprite 1 (without rotation, 1 would cover 2).
//   - Right control: sprites 10 (teal) and 11 (blue) overlap. Their
//     relative order is unchanged by the rotation (10 still precedes
//     11), so 10 must cover 11 either way.
//
// Skeleton derived from undisbeliever's object-dropout-test.asm.
//
// SPDX-FileCopyrightText: © 2026 NESER contributors
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OAM ROTATION"
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

    // Enable priority rotation with sprite 2 as the first sprite: the OAM
    // word address selects the sprite (index = OAMADD >> 1) and OAMADDH
    // bit 7 enables the rotation. Written after the OAM upload so the
    // address sticks for every subsequent frame.
    lda.b   #4
    sta.w   OAMADDL
    lda.b   #$80
    sta.w   OAMADDH

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
    _P($cc3333) // 0: red (unused sprite 0, parked off-screen)
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
    // Sprite 0 parked off-screen below the visible area.
    _obj(0, 240, 0, 0 << 1)

    // Left pair: with rotation starting at sprite 2, sprite 2 covers 1.
    _obj(40, 96, 0, 1 << 1)
    _obj(48, 104, 0, 2 << 1)

    // Park sprites 3-9 off-screen.
    variable _i = 3
    while _i < 10 {
        _obj(0, 240, 0, 0)
        _i = _i + 1
    }

    // Right control pair: 10 covers 11 with or without rotation.
    _obj(160, 96, 0, 3 << 1)
    _obj(168, 104, 0, 4 << 1)

    fill    (128 - __nObjects) * 4, -16

Obj_OamHiTable:
    // Sprites 1, 2, 10, 11 large (16x16); everything else small; X bit 8
    // clear everywhere. (2 bits per sprite, LSB first: sprite 10 = bits
    // 4-5 and sprite 11 = bits 6-7 of the third byte.)
    db  %00101000, 0, %10100000
    fill    29, 0

constant Obj_Oam.size = pc() - Obj_Oam
assert(Obj_Oam.size == 544)

}
