# mtdbt2f4dx

Meta-the-Difference-Between-the-Two-Font-* is a p5.js audiovisual work that animates an asterisk through a sequence of fonts in response to sound.

## Requirements

- Node.js 20 or newer
- A modern browser (Web MIDI is optional)
- FFmpeg and SoX for the production scripts

## Run

Install and run:

```sh
npm install
npm start
```

Open `http://localhost:8080`. The default WAV lives at
`p5js/data/audio/in.wav`; you can also drop an audio file onto the canvas.

The Bash production workflow remains available:

```sh
./bash/mtdbt2f4dx --audio path/to/input.wav
```

MIDI devices and effect timeline files are optional.

## FX timelines

Effects are synchronized to audio with files in `p5js/data/tmp`. Each file contains one start time in milliseconds per line:

```text
1200
8450
```

Timeline names include `_fx_spin`, `_fx_spin_reverse`, `_fx_blur`, `_fx_blur_fade`, `_fx_north`, `_fx_south`, `_fx_east`, `_fx_west`, `_fx_scale_in`, `_fx_scale_out`, `_fx_black`, `_fx_img`, `_fx_order3d`, `_fx_shapeshift`, `_fx_cometogether`, and `_fx_parallel_1` through `_fx_parallel_3`.

The `bash/mtdbt2f4dx` production script can generate these timelines from the positions of specially named audio clips. Missing timeline files are ignored.

## MIDI

The sketch listens to available Web MIDI inputs. Its control-change mappings are:

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
- `f` — toggle between volume response (default) and FFT response
- `d` — toggle diagnostics
- `r` — start/stop an MP4 recording with audio (WebM fallback when MP4 encoding is unavailable)

## Tests

```sh
npm test
```

Tests cover timeline parsing, seeking and font traversal, JavaScript syntax,
and a server/asset smoke test.
