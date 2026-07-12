# undisbeliever PPU BG / VMAIN test ROMs

Basic background, tile, palette, scroll and VMAIN (VRAM increment /
address remapping) test ROMs by Marcus Rowe (undisbeliever),
built from [undisbeliever/snes-test-roms][r] (zlib license, see
[LICENSE](./LICENSE)).

Upstream publishes no prebuilt release containing these ROMs, so they
are built once locally from the source mirror in
[`../undisbeliever-inidisp/sources/`](../undisbeliever-inidisp/sources/)
and the resulting `.sfc` files are committed here.

## ROMs

From `src/vmain-address-remapping/` (VRAM increment modes and VMAIN
address remapping at each bit depth):

  - `vmain-1bpp-no-remapping.sfc`, `vmain-1bpp-with-remapping.sfc`
  - `vmain-2bpp-no-remapping.sfc`, `vmain-2bpp-with-remapping.sfc`,
    `vmain-2bpp-split-with-remapping.sfc`
  - `vmain-4bpp-no-remapping.sfc`, `vmain-4bpp-with-remapping.sfc`,
    `vmain-4bpp-no-remapping-word.sfc`, `vmain-4bpp-with-remapping-word.sfc`
  - `vmain-8bpp-no-remapping.sfc`, `vmain-8bpp-with-remapping.sfc`

From `src/effects/` (tile decode demos and BG scroll basics):

  - `vmain-1bpp-tiles-0.sfc`, `vmain-1bpp-tiles-1.sfc`
  - `vmain-horizontal-scrolling.sfc`
  - `vmain-vertical-scrolling.sfc`, `vmain-vertical-scrolling-2-rows.sfc`

From `src/examples/` (plain VRAM writes and text tilemap):

  - `vram-writes-without-dma.sfc`
  - `textbuffer-hello-world.sfc`

## Rebuilding

Requires GNU make, Python 3 and a C++ compiler.

```sh
cd ../undisbeliever-inidisp
./update-sources                       # refresh the source mirror
cd sources
git submodule update --init bass-untech
# On clang (macOS): fix an argument-evaluation-order bug in bass first,
# see below.
patch -p1 -d bass-untech < ../../undisbeliever-ppu-bg/bass-untech-arg-eval-order.patch
make -C bass-untech/bass -j4           # build the assembler
make directories
make bin/vmain-address-remapping/vmain-1bpp-no-remapping.sfc  # etc.
# then copy the built bin/**/*.sfc files listed above into this directory
```

### bass-untech clang fix

`bass-untech` (as of commit `9db6088`) contains calls of the form
`setDefine(p(0), {}, p(1), level)` where `p(1)` can grow the underlying
`nall::vector` and reallocate its storage. C++ does not specify function
argument evaluation order: g++ on Linux happens to evaluate `p(1)`
first (works), while clang evaluates `p(0)` first, leaving a dangling
reference and registering defines under a corrupted name. The symptom is
`error "Rom block {id} does not exist"` when assembling any test ROM.
[`bass-untech-arg-eval-order.patch`](./bass-untech-arg-eval-order.patch)
hoists the value arguments into locals before the calls, which is
correct under any evaluation order. The patch does not change the
assembled output.

[r]: https://github.com/undisbeliever/snes-test-roms
