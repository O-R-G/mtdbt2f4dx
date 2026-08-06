# mtdbt2f4dx

Meta-the-Difference-Between-the-Two-Font-* is a p5.js audiovisual work. It moves an asterisk through a sequence of fonts and scales it in response to sound.

## Requirements

- Node.js 20 or newer
- A modern browser
- FFmpeg and SoX for the optional Bash production workflow

## Run

```sh
npm install
npm start
```

Open `http://localhost:8080`. Press space to play. The default audio file is
`p5js/data/audio/in.wav`; another audio file can be dropped onto the canvas.

## Structure

```text
p5js/
  index.html          browser entry point
  sketch.js           drawing, audio, MIDI, effects, and recording
  core.mjs            testable animation and recording helpers
  fonts.json          generated font manifest
  timelines.json      generated optional FX timelines
  data/
    audio/in.wav
    fonts/
bash/mtdbt2f4dx       speech, audio, and timeline production script
scripts/              manifest generation, server, and smoke test
test/                 unit tests
```

`npm start` regenerates the font and timeline manifests before starting the
local server.

## Audio response

Volume response is enabled by default. The audio level maps the asterisk from
1× to 5× scale. Press `f` to use FFT response instead.

## Recording

Press `r` to start and stop recording. The download includes canvas video and
the audible p5.js output. MP4/H.264 is preferred; browsers without MP4
`MediaRecorder` support fall back to WebM.

## Bash workflow

Use an existing audio file:

```sh
./bash/mtdbt2f4dx --audio path/to/input.wav
```

Or generate speech from a text file:

```sh
./bash/mtdbt2f4dx --file path/to/input.txt
```

The script writes the resulting audio to `p5js/data/audio/in.wav`, generates
timelines for any specially referenced effect clips, then starts the server and
opens the sketch. MIDI devices and effect timelines are optional.

## FX timelines

Effects are synchronized to audio with files in `p5js/data/tmp`. Each file contains one start time in milliseconds per line:

```text
1200
8450
```

Timeline names include `_fx_spin`, `_fx_spin_reverse`, `_fx_blur`, `_fx_blur_fade`, `_fx_north`, `_fx_south`, `_fx_east`, `_fx_west`, `_fx_scale_in`, `_fx_scale_out`, `_fx_black`, `_fx_img`, `_fx_order3d`, `_fx_shapeshift`, `_fx_cometogether`, and `_fx_parallel_1` through `_fx_parallel_3`.

The Bash script generates these timelines from specially named audio clips.
`npm start` collects them into `p5js/timelines.json`; missing files are ignored.

## MIDI

The sketch listens to available Web MIDI inputs. Browser permission may be
required. Control-change mappings are:

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
- `<` / `>` — seek backward/forward five seconds
- `f` — toggle between volume response (default) and FFT response
- `d` — toggle diagnostics
- `s` — toggle the spectrum while diagnostics are visible
- `r` — start/stop an MP4 recording with audio (WebM fallback when MP4 encoding is unavailable)

## Tests

```sh
npm test
```

Tests cover audio scaling, timeline parsing, seeking, font traversal, recording
format and tracks, JavaScript syntax, server routes, and required assets.
