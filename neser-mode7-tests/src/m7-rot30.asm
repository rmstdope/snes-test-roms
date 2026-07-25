// Mode 7 30-degree rotation about the map centre
// (NESER #2881)
//
// Rotation by 30 degrees (A = D = cos30 = 0x00DE, B = sin30 =
// 0x0080, C = -sin30 = 0xFF80) with M7X = M7Y = 512 (map centre)
// and scroll placing the centre cross mid-screen. Corner blocks
// unambiguously identify the rotation direction.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER M7 ROT30"
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

include "_mode7-scene.inc"


// Setup PPU registers and load data to the PPU.
//
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupPpu {
    jsr     SetupMode7Scene

    lda.b   #BGMODE.mode7
    sta.w   BGMODE

    lda.b   #M7SEL.outOfScreen.repeat
    sta.w   M7SEL

    SetMode7Matrix(0x00de, 0x0080, 0xff80, 0x00de, 512, 512, 384, 400)

    lda.b   #TM.bg1
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
