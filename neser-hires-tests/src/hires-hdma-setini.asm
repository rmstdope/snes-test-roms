// Mid-frame pseudo-hires (SETINI bit 3) switch driven by HDMA (NESER #3034)
//
// The twin of hires-hdma-bgmode.sfc, reaching the same transition
// through the other register: BGMODE stays at mode 1 all frame and an
// HDMA channel writes SETINI ($2133) every scanline, clear for the top
// HIRES_SWITCH_LINE lines and pseudo-hires for the rest.
//
// Pseudo-hires does not double the BG fetch; it interleaves the main
// and sub screens per half-pixel. So the top half shows BG1's vertical
// stripes alone and the bottom half shows BG1 and BG2 interleaved,
// while the frame as a whole is one 512-column picture.
//
// Skeleton derived from undisbeliever's test ROM framework.
//
// SPDX-FileCopyrightText: © 2026 Henrik Kurelid
// SPDX-License-Identifier: Zlib

define MEMORY_MAP = LOROM
define ROM_SIZE = 1
define ROM_SPEED = fast
define REGION = Japan
define ROM_NAME = "NESER HIRES HDMA SETINI"
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


// HDMA table: SETINI per scanline. Every other SETINI bit stays clear,
// so pseudo-hires is the only thing changing mid-frame (in particular
// neither overscan nor screen interlace is touched).
HdmaTable:
    db  HIRES_SWITCH_LINE
    db  0

    db  224 - HIRES_SWITCH_LINE
    db  SETINI.psuedoHires

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

    lda.b   #BGMODE.mode1
    sta.w   BGMODE

    rts
}


// Arm the SETINI HDMA channel.
//
// REQUIRES: 8 bit A, 16 bit Index, DB = 0x80, DP = 0
a8()
i16()
code()
function SetupHdma {
    stz.w   HDMAEN

    lda.b   #DMAP.direction.toPpu | DMAP.addressing.absolute | DMAP.transfer.one
    sta.w   DMAP0

    lda.b   #SETINI
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
