// Offset-per-tile Mode 6: hires with both offset rows applied to BG1
// (NESER #2881)
//
// Mode 6 (BG1 4bpp hires, 16x8 tiles) with diagonal colour bands
// (tile = ((r+c)%8)+1) so both offset directions are visible. Mode 6
// reads both OPT rows like mode 2: every horizontal entry applies
// offset 8*j and every vertical entry offset 4*j to BG1.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OPT M6 HIRES"
define VERSION = 0

define OPT_BG1_DIAGONAL

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

include "_opt-scene.inc"


// Offset-per-tile table: row 0 = horizontal entries (8*j), row 1 =
// vertical entries (4*j), all applied to BG1.
OptData:
    variable _j = 0
    while _j < 32 {
        dw  (8 * _j) | OPT_APPLY_BG1
        _j = _j + 1
    }
    _j = 0
    while _j < 32 {
        dw  (4 * _j) | OPT_APPLY_BG1
        _j = _j + 1
    }

constant OptData.size = pc() - OptData


// Setup PPU registers and load data to the PPU.
//
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupPpu {
    jsr     SetupOptScene

    lda.b   #BGMODE.mode6
    sta.w   BGMODE

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
