import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
const port = Number(process.env.PORT || 8080), root = process.cwd();
const mime = {'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.json':'application/json','.wav':'audio/wav','.ttf':'font/ttf'};
createServer(async (req,res) => {
  if (req.url === '/') { res.writeHead(302, { location: '/p5js/' }).end(); return; }
  const requestPath = decodeURIComponent(req.url.split('?')[0]);
  const url = requestPath === '/p5js/' ? '/p5js/index.html' : requestPath;
  if (url.endsWith('/p5.sound.min.js.map')) { res.writeHead(204).end(); return; }
  const file = normalize(join(root, url));
  if (!file.startsWith(root)) { res.writeHead(403).end(); return; }
  try { await stat(file); res.writeHead(200, {'content-type': mime[extname(file)] || 'application/octet-stream'}); createReadStream(file).pipe(res); }
  catch { console.error(`404 ${url}`); res.writeHead(404).end('Not found'); }
}).listen(port, () => console.log(`mtdbt2f4d* http://localhost:${port}`));
