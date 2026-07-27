// Offset-per-tile Mode 4: single offset row with per-entry H/V select
// (NESER #2881)
//
// Mode 4 (BG1 8bpp) with diagonal colour bands (tile = ((r+c)%8)+1)
// so both offset directions are visible. Mode 4 reads only ONE row
// of OPT entries; bit 15 of each entry selects its direction. Even
// entries apply a horizontal offset 8*j, odd entries a vertical
// offset 4*j (both with the BG1 flag). The second tilemap row holds
// conspicuous values WITHOUT apply flags: they must never be applied
// (mode 4 does not read a vertical row).
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER OPT M4 HV"
define VERSION = 0

define OPT_MODE4
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


// Offset-per-tile table: row 0 = the single mode-4 offset row with
// alternating H/V entries; row 1 = flag-less filler that must stay
// unread in mode 4.
OptData:
    variable _j = 0
    while _j < 32 {
        if _j % 2 == 0 {
            dw  (8 * _j) | OPT_APPLY_BG1
        } else {
            dw  (4 * _j) | OPT_APPLY_BG1 | OPT_VERTICAL
        }
        _j = _j + 1
    }
    _j = 0
    while _j < 32 {
        dw  0x03ff
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

    lda.b   #BGMODE.mode4
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
