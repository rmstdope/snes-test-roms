// Colour-math transparent-sub fallback test (NESER #2880)
//
// Shared quadrant scene built with CM_BG2_CENTER_ONLY: the sub-screen
// bars cover only tile columns 10-21, so every main bar row shows
// both a sub-present centre (halved add with the sub colour) and
// sub-transparent sides. On hardware the sides must add the fixed
// colour (COLDATA R=20, B=20) WITHOUT halving.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER CM SUB BACKDROP"
define VERSION = 0

define CM_BG2_CENTER_ONLY

architecture wdc65816-strict

include "../common.inc"

createCodeBlock(code,       0x808000, 0x80ffaf)

createRamBlock(lowram,      0x7e0100, 0x7e1f7f)
createRamBlock(stack,       0x7e1f80, 0x7e1fff)

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

    lda.b   #CGWSEL.addSubscreen
    sta.w   CGWSEL

    // add, half, math on BG1 + backdrop
    lda.b   #%01100001
    sta.w   CGADSUB

    lda.b   #COLDATA.plane.red | 20
    sta.w   COLDATA
    lda.b   #COLDATA.plane.blue | 20
    sta.w   COLDATA

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
