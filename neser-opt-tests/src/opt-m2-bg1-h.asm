// Offset-per-tile Mode 2: per-column horizontal offsets on BG1
// (NESER #2881)
//
// BG1 shows vertical colour stripes (tilemap column c = colour
// (c%8)+1). The OPT horizontal row applies offset 8*j to even
// entries (BG1 flag set); odd entries carry the same value WITHOUT
// the flag and must leave their column on the base scroll. The
// leftmost 8px column has no OPT entry and must stay unshifted;
// entry j applies to screen column j+1.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OPT M2 BG1 H"
define VERSION = 0

define OPT_BG1_VSTRIPES

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


// Offset-per-tile table: row 0 = horizontal entries, row 1 =
// vertical entries (all inert).
OptData:
    variable _j = 0
    while _j < 32 {
        if _j % 2 == 0 {
            dw  (8 * _j) | OPT_APPLY_BG1
        } else {
            dw  (8 * _j)
        }
        _j = _j + 1
    }
    _j = 0
    while _j < 32 {
        dw  0
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
