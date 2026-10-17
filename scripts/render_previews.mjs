import { chromium } from 'playwright';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';

let input = '';
for await (const chunk of process.stdin) input += chunk;

const previews = JSON.parse(input);

const mimeTypes = {
  '.avif': 'image/avif',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.ttf': 'font/ttf'
};

async function toDataUrl(path) {
  const mimeType = mimeTypes[extname(path).toLowerCase()];
  if (!mimeType) throw new Error(`Format de fichier non pris en charge : ${path}`);

  const content = await readFile(path);
  return `data:${mimeType};base64,${content.toString('base64')}`;
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 600, height: 315 },
  deviceScaleFactor: 2
});

try {
  for (const preview of previews) {
    const [fontSrc, imageSrc] = await Promise.all([
      toDataUrl(preview.font_path),
      toDataUrl(preview.image_path)
    ]);
    const page = await context.newPage();
    const html = preview.html
      .replaceAll('__FONT_SRC__', fontSrc)
      .replaceAll('__IMAGE_SRC__', imageSrc);
    await page.setContent(html, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await page.screenshot({
      path: preview.path,
      type: 'png',
      clip: { x: 0, y: 0, width: 600, height: 315 }
    });
    await page.close();
  }
} finally {
  await context.close();
  await browser.close();
}
