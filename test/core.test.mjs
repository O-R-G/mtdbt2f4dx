import test from 'node:test';
import assert from 'node:assert/strict';
import { activeAt, audioScale, combineRecordingStreams, fftScale, nextFont, parseTimeline, recordingFormat, seekSeconds } from '../p5js/core.mjs';
test('timelines accept numeric lines and ignore blanks', () => assert.deepEqual(parseTimeline('1200\n\n8450\n'), [1200, 8450]));
test('effects include their boundaries', () => { assert.equal(activeAt(100,100,20), true); assert.equal(activeAt(121,100,20), false); });
test('font traversal reverses at range ends', () => assert.deepEqual(nextFont(3,1,0,3), {index:2,direction:-1}));
test('seeking is clamped to the sound duration', () => { assert.equal(seekSeconds(.5,-1000,10),0); assert.equal(seekSeconds(9,5000,10),10); });
test('volume drives the original 1x to 5x scale range', () => {
  assert.equal(audioScale(0, 1), 1);
  assert.equal(audioScale(0.5, 1), 3);
  assert.equal(audioScale(1, 1), 5);
  assert.equal(audioScale(-0.5, 1), 3);
});
test('FFT energy maps its full range to 1x through 5x', () => {
  assert.equal(fftScale(0), 1);
  assert.equal(fftScale(255), 5);
});
test('recording prefers MP4 and falls back to WebM when required', () => {
  assert.equal(recordingFormat(type => type.startsWith('video/mp4')).extension, 'mp4');
  assert.equal(recordingFormat(type => type === 'video/webm').extension, 'webm');
});
test('recording stream combines canvas video with sound audio', () => {
  class MockMediaStream {
    constructor(tracks) { this.tracks = tracks; }
    getVideoTracks() { return this.tracks.filter(track => track.kind === 'video'); }
    getAudioTracks() { return this.tracks.filter(track => track.kind === 'audio'); }
  }
  const canvas = new MockMediaStream([{ kind: 'video', id: 'canvas' }]);
  const sound = new MockMediaStream([{ kind: 'audio', id: 'sound' }]);
  const combined = combineRecordingStreams(canvas, sound, MockMediaStream);
  assert.deepEqual(combined.tracks.map(track => track.kind), ['video', 'audio']);
});
