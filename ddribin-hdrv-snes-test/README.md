# hdrv-snes-test (SNES HD retro video test)

Display-mode test ROM by Dave Dribin (ddribin), from
[ddribin/hdrv-snes-test][r] (CC0-1.0, see
[hdrv-snes-test/COPYING.TXT](./hdrv-snes-test/COPYING.TXT)).

The ROM presents a joypad-driven menu that switches between the eight
SNES scan/resolution combinations -- 256x224, 256x239, 512x224,
512x239 (hires BG mode 5), non-interlace and interlace (448/478-line)
variants -- plus left/right audio channel checks. It is the only
redistributable deterministic ROM found that exercises the hires
512-wide and interlace scan modes directly from a menu.

## Prebuilt ROM

Upstream ships no prebuilt ROM, so `hdrvtest.sfc` is built once
locally from the source subtree in
[`hdrv-snes-test/`](./hdrv-snes-test/) and committed here (same
build-once-and-commit approach as `../undisbeliever-ppu-bg/`).

Toolchain: WLA-DX (upstream used WLA 65816 v9.5 via `wla.bat`; this
build used the Homebrew `wla-dx` package, WLA W65816 v10.7 /
WLALINK v5.22):

```sh
cd hdrv-snes-test
wla-65816 -o hdrvtest.obj hdrvtest.asm
printf '[objects]\nhdrvtest.obj\n' > temp.prj
wlalink -v -r temp.prj hdrvtest.sfc
# then copy hdrvtest.sfc into this directory
```

## Refreshing the source subtree

Run [`./update-sources`](./update-sources), then rebuild and re-commit
`hdrvtest.sfc` if the sources changed.

[r]: https://github.com/ddribin/hdrv-snes-test
