# mtdbt2f4dx

Meta-the-Difference-Between-the-Two-Font-* is a Processing audiovisual work that animates an asterisk through a sequence of fonts in response to sound.

## Requirements

- Processing 4 with Java mode
- Minim
- The MidiBus (optional at runtime)
- FFmpeg and SoX for the production scripts

## Run

Place a 16 kHz stereo WAV file at:

```text
processing/mtdbt2f4dx/data/audio/in.wav
```

Then run the sketch from Processing, or from the repository root:

```sh
processing-java --sketch="$PWD/processing/mtdbt2f4dx" --output=/tmp/mtdbt2f4dx --force --run
```

MIDI devices and effect timeline files are optional.

## FX timelines

Effects are synchronized to audio with files in `processing/mtdbt2f4dx/data/tmp`. Each file contains one start time in milliseconds per line:

```text
1200
8450
```

Timeline names include `_fx_spin`, `_fx_spin_reverse`, `_fx_blur`, `_fx_blur_fade`, `_fx_north`, `_fx_south`, `_fx_east`, `_fx_west`, `_fx_scale_in`, `_fx_scale_out`, `_fx_black`, `_fx_img`, `_fx_order3d`, `_fx_shapeshift`, `_fx_cometogether`, and `_fx_parallel_1` through `_fx_parallel_3`.

The `bash/mtdbt2f4dx` production script can generate these timelines from the positions of specially named audio clips. Missing timeline files are ignored.

## MIDI

The sketch uses the first available MIDI input and output. Its control-change mappings are:

- CC 1 — opacity
- CC 3 — audio sensitivity
- CC 4 — playback gain
- CC 5 / 6 — font range
- CC 7 — rotation
- CC 8 — scale

If MIDI initialization fails, the sketch continues without it.

## Controls

- `space` — play/pause
- `tab` — rewind
- `,` / `.` — seek backward/forward
- `f` — toggle FFT response
- `d` — toggle diagnostics
- `r` — start/stop rendering
