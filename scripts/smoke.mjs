import { spawn } from 'node:child_process';
const port = 18080, child = spawn(process.execPath, ['scripts/serve.mjs'], { env: {...process.env, PORT: String(port)}, stdio: 'ignore' });
try {
  await new Promise(resolve => setTimeout(resolve, 300));
  for (const path of ['/', '/p5js/', '/p5js/style.css', '/p5js/sketch.js', '/p5js/core.mjs', '/p5js/fonts.json', '/p5js/timelines.json', '/node_modules/p5/lib/p5.min.js', '/node_modules/p5/lib/addons/p5.sound.min.js', '/p5js/data/audio/in.wav']) {
    const response = await fetch(`http://localhost:${port}${path}`); if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
  }
} finally { child.kill(); }
