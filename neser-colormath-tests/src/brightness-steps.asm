// INIDISP brightness steps test (NESER #2880)
//
// Shared quadrant scene with both bar layers on the main screen
// (TM = BG1 + BG2, no colour math). The VBlank handler drives
// INIDISP from the frame counter:
//   - frames 0-1023: brightness = frame / 64 (levels 0-15, 64
//     frames per level),
//   - frames 1024-1151: hold full brightness,
//   - frames 1152+: force-blank.
// Sampling the screen mid-plateau (frame 64 * N + 32) verifies the
// brightness multiplier at every level, then the force-blank cut.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER BRIGHTNESS STEP"
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

    jsr     UpdateBrightness
}

include "../vblank_interrupts.inc"

include "_colormath-scene.inc"


// Set INIDISP from the 32 bit frame counter.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
// RETURNS: 8 bit A, 16 bit Index
a8()
i16()
code()
function UpdateBrightness {
    rep     #$30
a16()
    lda.w   frameCounter
    cmp.w   #1152
    bcs     ForceBlank
    cmp.w   #1024
    bcs     FullBrightness

    // brightness = frame / 64
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    sep     #$20
a8()
    sta.w   INIDISP
    rts

FullBrightness:
    sep     #$20
a8()
    lda.b   #0x0f
    sta.w   INIDISP
    rts

ForceBlank:
    sep     #$20
a8()
    lda.b   #INIDISP.force
    sta.w   INIDISP
    rts
}


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

    // release force-blank at level 0; the VBlank handler owns
    // INIDISP from here on
    stz.w   INIDISP

    MainLoop:
        jsr     WaitFrame
        jmp     MainLoop
}
