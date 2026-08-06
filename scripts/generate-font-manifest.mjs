import { readFile, readdir, writeFile } from 'node:fs/promises';
const root = new URL('../p5js/data/fonts/mtdbt2f4d-3/', import.meta.url);
const files = (await readdir(root)).filter(name => name.endsWith('.ttf')).sort((a,b) => Number(a.match(/\d+(?=\.ttf)/)[0]) - Number(b.match(/\d+(?=\.ttf)/)[0]));
await writeFile(new URL('../p5js/fonts.json', import.meta.url), `${JSON.stringify(files, null, 2)}\n`);

const fxNames = ['spin','spin_reverse','blur','blur_fade','north','south','east','west','scale_in','scale_out','black','img','order3d','shapeshift','cometogether','parallel_1','parallel_2','parallel_3'];
const timelines = {};
for (const name of fxNames) {
  try { timelines[name] = (await readFile(new URL(`../p5js/data/tmp/_fx_${name}`, import.meta.url), 'utf8')).split(/\r?\n/).filter(Boolean); }
  catch (error) { if (error.code !== 'ENOENT') throw error; timelines[name] = []; }
}
await writeFile(new URL('../p5js/timelines.json', import.meta.url), `${JSON.stringify(timelines, null, 2)}\n`);
