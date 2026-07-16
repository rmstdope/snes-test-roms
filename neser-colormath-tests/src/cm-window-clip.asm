// Colour-window clip / prevent test (NESER #2880)
//
// Shared quadrant scene with the colour window (window 1, x = 64-191)
// driving CGWSEL: clip main-to-black INSIDE the window, prevent
// colour math OUTSIDE it. CGADSUB = add + half on BG1 + backdrop.
// Expected: outside the window the raw main bars show with no math;
// inside, the main pixel is clipped to black and the sub colour is
// added at FULL strength (hardware disables halving when the main
// pixel was clipped to black).
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER CM WINDOW CLIP"
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

    // window 1: x = 64-191
    lda.b   #64
    sta.w   WH0
    lda.b   #191
    sta.w   WH1

    // colour window: window 1 enabled, not inverted
    lda.b   #(WSEL.win1.enable | WSEL.win1.inside) << WOBJSEL.color.shift
    sta.w   WOBJSEL

    lda.b   #CGWSEL.clip.inside | CGWSEL.prevent.outside | CGWSEL.addSubscreen
    sta.w   CGWSEL

    // add, half, math on BG1 + backdrop
    lda.b   #%01100001
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
