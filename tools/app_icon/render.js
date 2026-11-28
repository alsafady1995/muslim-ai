// Renders the Asmi3ni app icon (tools/app_icon/icon.svg) into every iOS and
// Android launcher size. Run from the repo root: node tools/app_icon/render.js
// Needs Playwright (Chromium) and Python 3 with Pillow (to drop the alpha
// channel from iOS icons, which App Store Connect rejects).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const svg = fs.readFileSync(path.join(__dirname, 'icon.svg'), 'utf8');
const defs = svg.match(/<defs>[\s\S]*<\/defs>/)[0];
const bgRect = svg.match(/<rect[^>]*\/>/)[0];
const mark = svg.match(/<g [\s\S]*<\/g>/)[0];

// Full icon: background + mark. Adaptive layers: background only, or the mark
// alone on transparency, shrunk so it sits inside Android's 66dp safe zone.
const full = svg;
const background = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">${defs}${bgRect}</svg>`;
// Adaptive canvas is 108dp; the launcher shows the middle 72dp. Scale the
// mark by 72/108 around the centre so it keeps the same proportion as on iOS.
const s = 72 / 108, o = 512 * (1 - s);
const foreground = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">${defs}<g transform="translate(${o} ${o}) scale(${s})">${mark}</g></svg>`;

const ios = path.join(root, 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset');
const res = path.join(root, 'app/android/app/src/main/res');
const jobs = [];
for (const f of fs.readdirSync(ios).filter((f) => f.endsWith('.png'))) {
  const m = f.match(/Icon-App-([\d.]+)x[\d.]+@(\d)x\.png/);
  jobs.push({ svg: full, px: Math.round(parseFloat(m[1]) * +m[2]), out: path.join(ios, f), opaque: true });
}
const dens = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [d, k] of Object.entries(dens)) {
  const dir = path.join(res, `mipmap-${d}`);
  jobs.push({ svg: full, px: 48 * k, out: path.join(dir, 'ic_launcher.png'), radius: 0.18 });
  jobs.push({ svg: full, px: 48 * k, out: path.join(dir, 'ic_launcher_round.png'), radius: 0.5 });
  jobs.push({ svg: background, px: 108 * k, out: path.join(dir, 'ic_launcher_background.png') });
  jobs.push({ svg: foreground, px: 108 * k, out: path.join(dir, 'ic_launcher_foreground.png'), transparent: true });
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const j of jobs) {
    await page.setViewportSize({ width: j.px, height: j.px });
    const r = j.radius ? `border-radius:${j.radius * 100}%;overflow:hidden;` : '';
    await page.setContent(
      `<style>html,body{margin:0;background:transparent}div{width:${j.px}px;height:${j.px}px;${r}}svg{display:block;width:100%;height:100%}</style><div>${j.svg}</div>`
    );
    await page.screenshot({ path: j.out, omitBackground: !!(j.radius || j.transparent) });
    if (j.opaque) {
      execFileSync('python3', ['-c', 'import sys;from PIL import Image;p=sys.argv[1];Image.open(p).convert("RGB").save(p,optimize=True)', j.out]);
    }
  }
  await browser.close();
  console.log(`Rendered ${jobs.length} icons`);
})();
