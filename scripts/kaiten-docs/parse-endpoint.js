const { withPage } = require("./common");

const url = process.argv[2];

if (!url) {
  console.error("Usage: node scripts/kaiten-docs/parse-endpoint.js <endpoint-url>");
  process.exit(1);
}

(async () => {
  try {
    const content = await withPage(url, async page => {
      return page.evaluate(() => {
        const divs = [...document.querySelectorAll("div.MuiBox-root")];
        const candidate = divs
          .map(el => {
            const text = (el.innerText || "").trim();
            let score = 0;
            if (text.includes("Responses")) score += 2;
            if (text.includes("Response Attributes")) score += 2;
            if (text.includes("GET https://") || text.includes("POST https://")) score += 1;
            if (text.includes("Create new space")) score -= 5;
            return { text, score };
          })
          .filter(item => item.score >= 4 && item.text.length < 30000)
          .sort((a, b) => b.score - a.score || a.text.length - b.text.length)[0];
        return candidate ? candidate.text : "";
      });
    });

    if (!content) {
      console.log("NOT FOUND");
      return;
    }

    console.log(content);
  } catch (error) {
    console.error(error?.message || error);
    process.exit(1);
  }
})();
