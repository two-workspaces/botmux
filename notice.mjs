// Stand-in on $PORT while botmux itself can't start: answers Railway's
// healthcheck and tells whoever opens the domain what is wrong, so a bad
// setting never turns into a crash loop. Usage: node notice.mjs <message file>
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';

const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
let detail = '';
try { detail = readFileSync(process.argv[2], 'utf8').slice(-4000); } catch {}

const page = `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>botmux is not running</title>
<style>body{font:16px/1.5 system-ui,sans-serif;max-width:46rem;margin:3rem auto;padding:0 1rem;color:#222;background:#fff}
pre{background:#f4f4f5;padding:1rem;overflow:auto;white-space:pre-wrap}@media(prefers-color-scheme:dark){body{background:#111;color:#ddd}pre{background:#222}}</style>
<h1>botmux could not start</h1>
<p>The container is up and retries every minute. The last attempt said:</p>
<pre>${esc(detail || '(no output)')}</pre>
<p>Fix it in the service's <b>Variables</b> tab (FEISHU_APP_ID, FEISHU_APP_SECRET, FEISHU_DOMAIN), or open a shell with
<code>railway ssh</code> and run <code>botmux start</code> to see the full error. The deploy logs say the same.</p>`;

createServer((req, res) => {
  if (req.url === '/__health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end('{"ok":true,"botmux":"starting"}');
  }
  res.writeHead(503, { 'content-type': 'text/html; charset=utf-8', 'retry-after': '60' });
  res.end(page);
}).listen(Number(process.env.PORT || 7891), '::');
