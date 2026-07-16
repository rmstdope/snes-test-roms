// Layer window mask test (NESER #2880)
//
// Shared quadrant scene with BOTH bars on the main screen (TM = BG1
// + BG2, no colour math, no sub screen). Window 1 (x = 64-191) and
// window 2 (x = 32-127) mask the main-screen layers via TMW:
//   - BG1: window 1, not inverted -> BG1 hidden for x = 64-191.
//   - BG2: window 1 inverted AND window 2 -> BG2 hidden only where
//     both agree (x = 32-63), verifying per-layer invert bits and
//     the WBGLOG AND operator.
// Expected: BG1 vertical bars outside the window-1 span, BG2
// horizontal bars showing through inside it, backdrop where both
// are masked or transparent.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER WIN LAYER MASKS"
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

    // both bar layers on the main screen, nothing on the sub screen
    lda.b   #TM.bg1 | TM.bg2
    sta.w   TM
    stz.w   TS

    // window 1: x = 64-191, window 2: x = 32-127
    lda.b   #64
    sta.w   WH0
    lda.b   #191
    sta.w   WH1
    lda.b   #32
    sta.w   WH2
    lda.b   #127
    sta.w   WH3

    // BG1: window 1 normal; BG2: window 1 inverted + window 2 normal
    lda.b   #((WSEL.win1.enable | WSEL.win1.inside) << W12SEL.bg1.shift) | ((WSEL.win1.enable | WSEL.win1.outside | WSEL.win2.enable | WSEL.win2.inside) << W12SEL.bg2.shift)
    sta.w   W12SEL

    // BG2 combines its two windows with AND
    lda.b   #WBGLOG.logic.and << WBGLOG.bg2.shift
    sta.w   WBGLOG

    // apply window masking to BG1 + BG2 on the main screen
    lda.b   #TMW.bg1 | TMW.bg2
    sta.w   TMW

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
