function requirePlaywright() {
  try {
    return require("playwright");
  } catch (error) {
    console.error(
      'Failed to load "playwright". Set NODE_PATH, for example:\n' +
        'export NODE_PATH="$(mise where npm:playwright)/lib/node_modules"'
    );
    throw error;
  }
}

async function withPage(url, action) {
  const { chromium } = requirePlaywright();
  const browser = await chromium.launch({ args: ["--no-sandbox"] });
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForTimeout(3000);
  try {
    return await action(page);
  } finally {
    await browser.close();
  }
}

module.exports = { withPage };
