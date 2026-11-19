import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createReadStream, mkdtempSync, mkdirSync, statSync, writeFileSync } from 'node:fs';
import http from 'node:http';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(project, 'reports', 'browser');
mkdirSync(output, { recursive: true });
writeFileSync(path.join(project, 'reports', '.gdignore'), '');
const game = path.join(project, 'build', 'web');
const keepServing = process.argv.includes('--serve');
const contentTypes = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css', '.wasm': 'application/wasm', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  const name = new URL(req.url, 'http://localhost').pathname.slice(1) || 'index.html';
  if (name !== path.basename(name)) return res.writeHead(404).end();
  const file = path.join(game, name);
  try {
    const size = statSync(file).size;
    res.writeHead(200, { 'Content-Length': size, 'Content-Type': contentTypes[path.extname(name)] || 'application/octet-stream' });
    createReadStream(file).pipe(res);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise((resolve, reject) => server.once('error', reject).listen(keepServing ? 8774 : 0, '127.0.0.1', resolve));
const url = `http://127.0.0.1:${server.address().port}/`;
const chrome = process.env.KATHAL_CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const browser = spawn(chrome, ['--headless=new', '--remote-debugging-pipe', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--disable-background-networking', '--no-first-run', '--no-default-browser-check', `--user-data-dir=${mkdtempSync(path.join(tmpdir(), 'kathal-browser-'))}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe', 'pipe', 'pipe'], windowsHide: true });
const requests = new Map();
const errors = [];
let browserLog = '';
browser.stderr.on('data', chunk => { browserLog = (browserLog + chunk).slice(-4500); });
let sequence = 0;
let session;
let context;
let buffer = Buffer.alloc(0);
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const call = (method, params = {}, sessionId = session) => new Promise((resolve, reject) => {
  const id = ++sequence;
  requests.set(id, { resolve, reject });
  const message = sessionId ? { id, method, params, sessionId } : { id, method, params };
  browser.stdio[3].write(`${JSON.stringify(message)}\0`);
});
browser.stdio[4].on('data', chunk => {
  buffer = Buffer.concat([buffer, chunk]);
  for (let end = buffer.indexOf(0); end >= 0; end = buffer.indexOf(0)) {
    const message = JSON.parse(buffer.subarray(0, end).toString('utf8'));
    buffer = buffer.subarray(end + 1);
    const request = requests.get(message.id);
    if (request) {
      requests.delete(message.id);
      if (message.error) request.reject(Error(message.error.message));
      else request.resolve(message.result);
    } else if (message.method === 'Runtime.exceptionThrown' || (message.method === 'Runtime.consoleAPICalled' && message.params.type === 'error')) {
      errors.push(message.params.exceptionDetails?.exception?.description || message.params.args?.map(item => item.value || item.description).join(' ') || 'Unknown browser error');
      console.error(errors.at(-1));
    }
  }
});
browser.on('error', error => {
  console.error(error);
  server.close();
  process.exit(1);
});
browser.on('exit', (code, signal) => {
  for (const request of requests.values()) request.reject(Error(`Chromium exited (${code ?? signal}). ${browserLog}`));
});
let failAfter;
const evaluate = async expression => (await call('Runtime.evaluate', { expression, returnByValue: true })).result.value;
const scene = () => evaluate('document.body?.dataset.scene');
const waitFor = async (predicate, label, timeout = 15000) => {
  const end = Date.now() + timeout;
  while (Date.now() < end) {
    if (await predicate()) return;
    await pause(180);
  }
  throw Error(`Timed out waiting for ${label}. Scene: ${await scene()}`);
};
const expect = value => waitFor(async () => (await scene()) === value, value);
const screenshot = async name => writeFileSync(path.join(output, `${name}.png`), Buffer.from((await call('Page.captureScreenshot')).data, 'base64'));

async function mouse(x, y) {
  await call('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await call('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}

async function key(key, code, windowsVirtualKeyCode, held = 70) {
  const info = { key, code, windowsVirtualKeyCode };
  await call('Input.dispatchKeyEvent', { type: 'keyDown', ...info });
  await pause(held);
  await call('Input.dispatchKeyEvent', { type: 'keyUp', ...info });
}

async function touch(points, type = 'touchStart') {
  await call('Input.dispatchTouchEvent', { type, touchPoints: points });
}

async function tap(x, y) {
  await touch([{ x, y, id: 0 }]);
  await pause(80);
  await touch([], 'touchEnd');
}

async function size(width, height, mobile) {
  await call('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile });
  await call('Emulation.setTouchEmulationEnabled', { enabled: mobile, maxTouchPoints: 4 });
}

function worldPoint(width, height, x, y) {
  const scale = Math.min(width / 1100, height / 700);
  const view = { x: width / scale, y: height / scale };
  const portrait = view.y > view.x;
  const top = portrait ? 105 : 76;
  const availableX = view.x - 36;
  const availableY = view.y - top - (portrait ? 164 : 122);
  const fit = Math.min(availableX / 1000, availableY / 420);
  return [Math.round((18 + (availableX - 1000 * fit) / 2 + x * fit) * scale), Math.round((top + (availableY - 420 * fit) / 2 + (151 + y * 0.64) * fit) * scale)];
}

async function open(width, height, mobile) {
  session = undefined;
  const { browserContextId } = await call('Target.createBrowserContext');
  context = browserContextId;
  const { targetId } = await call('Target.createTarget', { url: 'about:blank', browserContextId });
  ({ sessionId: session } = await call('Target.attachToTarget', { targetId, flatten: true }));
  await call('Page.enable');
  await call('Runtime.enable');
  await size(width, height, mobile);
  await call('Page.navigate', { url });
  await start();
}

async function start() {
  await waitFor(() => evaluate('!!document.querySelector("#start:not([hidden])")'), 'browser Play button');
  const rect = await evaluate('document.querySelector("#start").getBoundingClientRect().toJSON()');
  await mouse(rect.x + rect.width / 2, rect.y + rect.height / 2);
  await waitFor(async () => (await scene()) === 'title', 'title', 42000);
  await pause(450);
}

failAfter = setTimeout(() => {
	console.error('Browser verification exceeded its time budget.', browserLog);
  browser.kill();
  server.close();
  process.exit(2);
}, 160000);

try {
  await open(1100, 700, false);
  await screenshot('desktop-title');
  await key('Enter', 'Enter', 13);
  await expect('exploring');
  await key('d', 'KeyD', 68, 450);
  await key('j', 'KeyJ', 74);
  await expect('player_panel');
  await key('Escape', 'Escape', 27);
  await expect('paused');
  await key('Escape', 'Escape', 27);
  await expect('exploring');
  const marker = worldPoint(1100, 700, 852, 173);
  await mouse(...marker);
  await pause(6200);
  await screenshot('desktop-interaction');
  await key('e', 'KeyE', 69);
  await expect('intro');
  await key('Enter', 'Enter', 13);
  await expect('playing');
  await key('Escape', 'Escape', 27);
  await expect('paused');
  await pause(2200);
  await call('Page.reload');
  await start();
  await key('Enter', 'Enter', 13);
  await expect('intro');
  console.log('PASS desktop keyboard, mouse pathfinding, pause panels, and saved checkpoint');

  await call('Target.disposeBrowserContext', { browserContextId: context }, null);
  await open(440, 900, true);
  await key('Enter', 'Enter', 13);
  await expect('exploring');
  await screenshot('phone-portrait');
  await touch([{ x: 67, y: 854, id: 1 }]);
  await pause(250);
  await touch([{ x: 67, y: 854, id: 1 }, { x: 407, y: 848, id: 2 }]);
  await pause(450);
  await screenshot('phone-joystick');
  await touch([], 'touchEnd');
  await pause(300);
  const portraitMarker = worldPoint(440, 900, 852, 173);
  await tap(...portraitMarker);
  await pause(6700);
  await screenshot('phone-touch-interaction');
  await tap(...portraitMarker);
  await expect('intro');
  await size(900, 440, true);
  await pause(1000);
  await screenshot('phone-landscape');
  await key('Enter', 'Enter', 13);
  await expect('playing');
  await screenshot('phone-landscape-action');
  assert.deepEqual(errors, []);
  console.log('PASS touch joystick, simultaneous touch, tap-to-walk, and phone orientation change');
} catch (error) {
  if (session) await screenshot('last-screen').catch(() => {});
  console.error(error);
  process.exitCode = 1;
} finally {
  clearTimeout(failAfter);
  browser.kill();
  if (process.exitCode || !keepServing) server.close();
  else console.log(`Kathal Kayanam preview is serving at ${url}`);
}
