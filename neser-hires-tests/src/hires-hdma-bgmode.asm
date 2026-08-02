// Mid-frame BGMODE 1 -> 5 switch driven by HDMA (NESER #3034)
//
// An HDMA channel writes BGMODE ($2105) every scanline: mode 1 for the
// top HIRES_SWITCH_LINE lines, mode 5 for the rest. The frame therefore
// begins native and turns true-hires part-way down, which is the case
// #3016 deferred to #3034.
//
// The top half must render as BG1's vertical stripes at native
// resolution, column-doubled into the 512-wide output; the bottom half
// as BG1 and BG2 interleaved per half-pixel. On hardware and in Mesen2
// the whole frame is one 512-column picture -- the rows drawn before
// the switch are re-laid-out when it happens, not left in the narrow
// layout.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER HIRES HDMA BGMODE"
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

include "_hires-scene.inc"


// HDMA table: BGMODE per scanline, native above the switch line and
// true-hires below it. Both values keep the BG tile-size bits clear, so
// the only thing changing mid-frame is the mode itself.
HdmaTable:
    db  HIRES_SWITCH_LINE
    db  BGMODE.mode1

    db  224 - HIRES_SWITCH_LINE
    db  BGMODE.mode5

    db  0

constant HdmaTable.size = pc() - HdmaTable


// Setup PPU registers and load data to the PPU.
//
// REQUIRES: force-blank, PPU registers reset
a8()
i16()
code()
function SetupPpu {
    jsr     SetupHiresScene

    // The HDMA channel overwrites this every scanline; it only decides
    // what the very top of the frame looks like before HDMA first runs.
    lda.b   #BGMODE.mode1
    sta.w   BGMODE

    rts
}


// Arm the BGMODE HDMA channel.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
a8()
i16()
code()
function SetupHdma {
    stz.w   HDMAEN

    lda.b   #DMAP.direction.toPpu | DMAP.addressing.absolute | DMAP.transfer.one
    sta.w   DMAP0

    lda.b   #BGMODE
    sta.w   BBAD0

    ldx.w   #HdmaTable
    stx.w   A1T0

    lda.b   #HdmaTable >> 16
    sta.w   A1B0

    lda.b   #HDMAEN.dma0
    sta.w   HDMAEN

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
    jsr     SetupHdma

    EnableVblankInterrupts()

    jsr     WaitFrame

    lda.b   #0x0f
    sta.w   INIDISP

    MainLoop:
        jsr     WaitFrame
        jmp     MainLoop
}
