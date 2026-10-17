import { chromium } from 'playwright';

let input = '';
for await (const chunk of process.stdin) input += chunk;

const previews = JSON.parse(input);
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 600, height: 315 },
  deviceScaleFactor: 2
});

try {
  for (const preview of previews) {
    const page = await context.newPage();
    await page.setContent(preview.html, { waitUntil: 'load' });
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
