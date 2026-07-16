// Colour-math fixed-colour add test (NESER #2880)
//
// Shared quadrant scene with CGWSEL addend = fixed colour (COLDATA)
// and CGADSUB = add, full, math on BG1 + backdrop. COLDATA is written
// per plane (R=31, G=16, B=8), verifying per-plane latching and the
// fixed-colour add path for every main bar and the backdrop.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER CM FIXED ADD"
define VERSION = 0

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

    // addend = fixed colour
    stz.w   CGWSEL

    // add, full, math on BG1 + backdrop
    lda.b   #%00100001
    sta.w   CGADSUB

    lda.b   #COLDATA.plane.red | 31
    sta.w   COLDATA
    lda.b   #COLDATA.plane.green | 16
    sta.w   COLDATA
    lda.b   #COLDATA.plane.blue | 8
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
