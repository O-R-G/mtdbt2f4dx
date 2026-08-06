export const FX_SPECS = Object.freeze({
  spin: 1675, spin_reverse: 1675, blur: 15830, blur_fade: 800,
  north: 200, south: 200, east: 200, west: 200,
  scale_in: 700, scale_out: 1050, black: 4000, img: 100000,
  order3d: 3833, shapeshift: 27000, cometogether: 5000,
  parallel_1: 5000, parallel_2: 5000, parallel_3: 5000
});

export const clamp = (value, low, high) => Math.max(low, Math.min(high, value));
export const lerpRange = (value, inLow, inHigh, outLow, outHigh) =>
  outLow + ((value - inLow) / (inHigh - inLow)) * (outHigh - outLow);
export const activeAt = (position, start, duration) => position >= start && position <= start + duration;
export const parseTimeline = text => text.split(/\r?\n/).map(line => line.trim()).filter(Boolean).map(Number).filter(Number.isFinite);
export const seekSeconds = (current, deltaMs, duration) => clamp(current + deltaMs / 1000, 0, duration || 0);
export const audioScale = (level, levelAdjust = 0.75) => lerpRange(Math.abs(level) * levelAdjust, 0, 1, 1, 5);
export const fftScale = energy => lerpRange(energy, 0, 255, 1, 5);
export function recordingFormat(isSupported) {
  const formats = [
    { mimeType: 'video/mp4;codecs=avc1.42E01E', extension: 'mp4' },
    { mimeType: 'video/mp4', extension: 'mp4' },
    { mimeType: 'video/webm;codecs=vp9', extension: 'webm' },
    { mimeType: 'video/webm', extension: 'webm' }
  ];
  return formats.find(format => isSupported(format.mimeType)) || { mimeType: '', extension: 'webm' };
}

export function combineRecordingStreams(canvasStream, audioStream, MediaStreamClass = MediaStream) {
  return new MediaStreamClass([
    ...canvasStream.getVideoTracks(),
    ...audioStream.getAudioTracks()
  ]);
}

export function nextFont(index, direction, start, end) {
  const candidate = index + direction;
  return candidate >= start && candidate <= end
    ? { index: candidate, direction }
    : { index: index - direction, direction: -direction };
}
