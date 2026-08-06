import { FX_SPECS, activeAt, audioScale, clamp, combineRecordingStreams, fftScale, lerpRange, nextFont, parseTimeline, recordingFormat, seekSeconds } from './core.mjs';

const FONT_ROOT = 'data/fonts/mtdbt2f4d-3';
const state = {
  fonts: [], timelines: {}, images: [], sound: null, fft: null, amplitude: null,
  font: 0, direction: 1, rangeStart: 0, rangeEnd: 0, glyph: '*',
  opacity: 255, fill: 255, rotation: 0, scale: 1, levelAdjust: 0.75,
  useFFT: false, diagnostics: false, spectrum: false, recording: null,
  started: false, loadError: null
};

window.preload = function () {
  const manifest = loadJSON('fonts.json', data => {
    for (const file of data) state.fonts.push(loadFont(`${FONT_ROOT}/${file}`));
  });
  void manifest;
  state.sound = loadSound('data/audio/in.wav', undefined, error => { state.loadError = error; });
  loadJSON('timelines.json', data => {
    for (const name of Object.keys(FX_SPECS)) state.timelines[name] = parseTimeline((data[name] || []).join('\n'));
  });
};

window.setup = function () {
  const canvas = createCanvas(720, 720);
  canvas.drop(file => {
    if (file.type !== 'audio') return;
    if (state.sound?.isPlaying()) state.sound.stop();
    state.sound = loadSound(file.data, () => {
      state.fft.setInput(state.sound); state.amplitude.setInput(state.sound);
      setStatus(`Loaded ${file.name}. Press space to play.`);
    });
  });
  frameRate(30);
  textAlign(CENTER, BASELINE);
  noStroke();
  state.rangeEnd = Math.max(0, state.fonts.length - 1);
  state.fft = new p5.FFT(0.8, 64);
  state.amplitude = new p5.Amplitude(0.8);
  if (state.sound) { state.fft.setInput(state.sound); state.amplitude.setInput(state.sound); }
  initMIDI();
  setStatus(state.loadError ? 'Audio missing: drop a sound file onto the canvas.' : 'Press space to play.');
};

window.draw = function () {
  background(0, state.opacity);
  const step = nextFont(state.font, state.direction, state.rangeStart, state.rangeEnd);
  state.font = step.index; state.direction = step.direction;
  if (!state.fonts.length) return drawMessage('No fonts loaded');

  push();
  translate(width / 2, height / 2);
  rotate(state.rotation);
  textFont(state.fonts[state.font]);
  textSize(432);
  fill(state.fill, state.opacity);

  const position = state.sound?.currentTime?.() * 1000 || 0;
  const fx = applyFx(position);
  const level = state.amplitude?.getLevel() || 0;
  state.fft?.analyze();
  const energy = state.fft?.getEnergy(20, 20000) || 0;
  const reactiveScale = state.useFFT ? fftScale(energy) : audioScale(level, state.levelAdjust);
  scale(state.scale * reactiveScale);
  if (!fx.suppress) text(state.glyph, 0, textAscent() * 0.67);
  pop();
  if (state.diagnostics) drawDiagnostics(position, energy, level);
};

function applyFx(position) {
  const active = name => (state.timelines[name] || []).filter(start => activeAt(position, start, FX_SPECS[name]));
  let suppress = false;
  state.opacity = active('blur').length || active('blur_fade').length ? 0 : 255;
  state.fill = active('black').length ? 0 : 255;
  for (const start of active('spin')) rotate(lerpRange(position - start, 0, FX_SPECS.spin, 0, -8 * PI));
  for (const start of active('spin_reverse')) rotate(lerpRange(position - start, 0, FX_SPECS.spin_reverse, 0, 8 * PI));
  if (active('north').length) rotate(TWO_PI);
  if (active('south').length) rotate(PI);
  if (active('east').length) rotate(HALF_PI);
  if (active('west').length) rotate(PI * 1.5);
  for (const start of active('scale_in')) scale(lerpRange(position - start, 0, FX_SPECS.scale_in, 0.0001, 1));
  for (const start of active('scale_out')) scale(lerpRange(position - start, 0, FX_SPECS.scale_out, 1, 0.0001));
  for (const start of active('order3d')) {
    const n = lerpRange(position - start, 0, FX_SPECS.order3d, 0, 1), a = textAscent();
    [[.4,.288],[-.4,.288],[.4,.61],[-.4,.61],[0,.12],[0,.77]].forEach(([x,y]) => text('*', a*x*n, a*y*n));
  }
  const lineFx = ['shapeshift', 'parallel_1', 'parallel_2', 'parallel_3', 'cometogether'];
  for (const name of lineFx) for (const start of active(name)) {
    suppress = true; const progress = clamp((position - start) / FX_SPECS[name], 0, 1); drawLineFx(name, progress);
  }
  state.glyph = suppress ? '–' : '*';
  return { suppress };
}

function drawLineFx(name, progress) {
  const y = textAscent() * .33;
  push(); rotate(HALF_PI);
  if (name === 'shapeshift') {
    pop(); const turn = (1 - progress) * TWO_PI * 12;
    [turn, -turn, turn * .5, -turn * .25].forEach(angle => { push(); rotate(angle); text('–', 0, y); pop(); }); return;
  }
  if (name === 'parallel_1') text('–', 0, y);
  if (name === 'parallel_2' || name === 'parallel_3') {
    const gap = progress * (name === 'parallel_2' ? width / 12 : width / 6);
    if (name === 'parallel_3') text('–', 0, y); text('–', 0, y + gap); text('–', 0, y - gap);
  }
  if (name === 'cometogether') for (const angle of [progress*TWO_PI/3, -progress*TWO_PI/3, progress*TWO_PI/9]) {
    push(); rotate(angle); text('–', 0, y); pop();
  }
  pop();
}

window.keyPressed = function () {
  if (!state.sound) return false;
  if (key === ' ') toggleAudio();
  else if (keyCode === TAB) { state.sound.stop(); state.sound.play(); state.started = true; }
  else if (key === ',' || key === '<') seek(key === '<' ? -5000 : -1000);
  else if (key === '.' || key === '>') seek(key === '>' ? 5000 : 1000);
  else if (key === 'f') state.useFFT = !state.useFFT;
  else if (key === 'd') state.diagnostics = !state.diagnostics;
  else if (key === 's' && state.diagnostics) state.spectrum = !state.spectrum;
  else if (key === 'r') toggleRecording();
  else if (key.length === 1) state.glyph = key;
  return false;
};

window.mousePressed = function () { if (!state.started) toggleAudio(); };
function toggleAudio() {
  userStartAudio();
  if (state.sound.isPlaying()) state.sound.pause(); else state.sound.play();
  state.started = true; setStatus(state.sound.isPlaying() ? 'Playing' : 'Paused');
}
function seek(delta) { state.sound.jump(seekSeconds(state.sound.currentTime(), delta, state.sound.duration())); }

function drawDiagnostics(position, energy, level) {
  push(); resetMatrix(); fill(255, 0, 0); textFont('monospace'); textSize(10); textAlign(LEFT, TOP);
  text(`${frameRate().toFixed(0)} fps > ${state.font}.ttf / ${position.toFixed(0)} ms\nlevel ${level.toFixed(3)} / fft ${energy.toFixed(0)} / ${state.useFFT ? 'FFT' : 'volume'}`, 10, 10);
  if (state.spectrum) { const spectrum = state.fft.analyze(); stroke(255,0,0); spectrum.forEach((v,i) => line(i*width/spectrum.length, 90, i*width/spectrum.length, 90-v/3)); }
  pop();
}
function drawMessage(message) { fill(255); textAlign(CENTER); text(message, width/2, height/2); }
function setStatus(message) { document.querySelector('#status').textContent = message; }

function toggleRecording() {
  if (state.recording) { state.recording.recorder.stop(); return; }
  const canvasStream = document.querySelector('canvas').captureStream(30), chunks = [];
  const audioDestination = getAudioContext().createMediaStreamDestination();
  p5.soundOut.output.connect(audioDestination);
  const stream = combineRecordingStreams(canvasStream, audioDestination.stream);
  const format = recordingFormat(type => MediaRecorder.isTypeSupported(type));
  const options = format.mimeType ? { mimeType: format.mimeType } : undefined;
  const recorder = new MediaRecorder(stream, options);
  state.recording = { recorder, audioDestination, stream };
  recorder.ondataavailable = event => chunks.push(event.data);
  recorder.onstop = () => {
    p5.soundOut.output.disconnect(audioDestination);
    stream.getTracks().forEach(track => track.stop());
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob(chunks, {type: format.mimeType || recorder.mimeType}));
    a.download = `mtdbt2f4d.${format.extension}`;
    a.click(); state.recording = null; setStatus(`Recording saved as ${format.extension.toUpperCase()} with audio.`);
  };
  recorder.start(); setStatus(`Recording ${format.extension.toUpperCase()}; press r to save.`);
}

async function initMIDI() {
  if (!navigator.requestMIDIAccess) return;
  try { const access = await navigator.requestMIDIAccess(); for (const input of access.inputs.values()) input.onmidimessage = onMIDI; } catch (_) { /* optional */ }
}
function onMIDI({ data: [status, cc, value] }) {
  if ((status & 0xf0) !== 0xb0) return;
  if (cc === 1) state.opacity = lerpRange(value,0,127,255,0);
  if (cc === 3) state.levelAdjust = lerpRange(value,0,127,.25,4);
  if (cc === 4 && state.sound) state.sound.setVolume(lerpRange(value,0,127,0,1));
  if (cc === 5) state.rangeStart = clamp(value,0,state.rangeEnd);
  if (cc === 6) state.rangeEnd = clamp(value + 128,state.rangeStart,state.fonts.length-1);
  if (cc === 7) state.rotation = lerpRange(value,0,127,0,TWO_PI);
  if (cc === 8) state.scale = lerpRange(value,0,127,.25,4);
}
