const { withPage } = require("./common");

const url = process.argv[2];

if (!url) {
  console.error("Usage: node scripts/kaiten-docs/parse-schemas.js <endpoint-url>");
  process.exit(1);
}

(async () => {
  try {
    const schemas = await withPage(url, async page => {
      const results = [];
      const buttons = await page.$$("button.MuiButton-root");
      const schemaButtons = [];

      for (const button of buttons) {
        const text = ((await button.textContent()) || "").trim();
        if (text === "Schema") schemaButtons.push(button);
      }

      for (const button of schemaButtons) {
        const fieldContext = await button.evaluate(el => el.closest("tr")?.textContent || "unknown");
        try {
          await button.click({ timeout: 3000 });
          await page.waitForTimeout(700);
        } catch {
          continue;
        }

        const dialog = await page.$(".MuiDialog-root");
        if (!dialog) continue;

        const schemaText = ((await dialog.textContent()) || "").trim();
        results.push({ field: fieldContext.trim().replace(/\s+/g, " "), schema: schemaText });

        await page.keyboard.press("Escape");
        await page.waitForTimeout(300);
      }

      return results;
    });

    console.log(JSON.stringify(schemas, null, 2));
  } catch (error) {
    console.error(error?.message || error);
    process.exit(1);
  }
})();
