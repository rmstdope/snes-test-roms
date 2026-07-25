// Offset-per-tile Mode 2: per-layer BG1/BG2 apply flags
// (NESER #2881)
//
// BG1 shows horizontal bands with transparent odd tile columns
// (palette 0); BG2 shows solid horizontal bands (palette 1) behind
// them. The OPT vertical row cycles through entries that apply only
// to BG2 (j%3 == 0), only to BG1 (j%3 == 1), and to both layers
// (j%3 == 2), so each column reveals which layers honoured its
// offset: BG1 shifts are visible in the even (opaque) 8px columns,
// BG2 shifts in the odd (transparent) ones.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OPT M2 BG2SEL"
define VERSION = 0

define OPT_BG1_HSTRIPES
define OPT_BG1_GAPS
define OPT_BG2_HSTRIPES

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


// Offset-per-tile table: row 0 = horizontal entries (all inert),
// row 1 = vertical entries with cycling layer flags.
OptData:
    variable _j = 0
    while _j < 32 {
        dw  0
        _j = _j + 1
    }
    _j = 0
    while _j < 32 {
        if _j % 3 == 0 {
            dw  (8 * (_j % 16)) | OPT_APPLY_BG2
        }
        if _j % 3 == 1 {
            dw  (8 * (_j % 16)) | OPT_APPLY_BG1
        }
        if _j % 3 == 2 {
            dw  (8 * (_j % 16)) | OPT_APPLY_BG1 | OPT_APPLY_BG2
        }
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

    lda.b   #BGMODE.mode2
    sta.w   BGMODE

    lda.b   #TM.bg1 | TM.bg2
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
