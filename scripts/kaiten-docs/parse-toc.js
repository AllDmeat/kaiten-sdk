const { withPage } = require("./common");

const url = process.argv[2] || "https://developers.kaiten.ru";
const HTTP_METHODS = new Set(["GET", "POST", "PATCH", "DELETE", "PUT"]);

(async () => {
  try {
    const groups = await withPage(url, async page => {
      return page.evaluate(() => {
        const allowedMethods = new Set(["GET", "POST", "PATCH", "DELETE", "PUT"]);
        const grouped = new Map();

        for (const anchor of [...document.querySelectorAll("a.link")]) {
          const methodLabel =
            anchor.querySelector("span.css-zdpt2t .MuiChip-label") || anchor.querySelector("span.css-zdpt2t");
          const method = (methodLabel?.textContent || "").trim().toUpperCase();
          if (!allowedMethods.has(method)) continue;

          const titleElement = anchor.querySelector("p.MuiTypography-root");
          const title = (titleElement?.textContent || "")
            .trim()
            .replace(/\s+/g, " ")
            .replace(new RegExp(`${method}$`), "")
            .trim();
          if (!title) continue;

          const sectionContainer = anchor.closest("div.MuiBox-root.css-0");
          const sectionTitle = (
            sectionContainer?.querySelector("li.MuiListSubheader-root, div.css-233int")?.textContent || ""
          )
            .trim()
            .replace(/\s+/g, " ");
          if (!sectionTitle) continue;

          if (!grouped.has(sectionTitle)) grouped.set(sectionTitle, []);
          grouped.get(sectionTitle).push({
            title,
            method,
            href: anchor.href,
          });
        }

        return [...grouped.entries()].map(([section, endpoints]) => ({ section, endpoints }));
      });
    });

    if (!Array.isArray(groups) || groups.length === 0) {
      throw new Error("Sidebar groups were not found");
    }
    for (const group of groups) {
      if (!group.section || !Array.isArray(group.endpoints)) {
        throw new Error("Invalid TOC shape");
      }
      for (const endpoint of group.endpoints) {
        if (!HTTP_METHODS.has(endpoint.method)) {
          throw new Error(`Invalid endpoint method: ${endpoint.method || "<empty>"}`);
        }
      }
    }

    console.log(JSON.stringify(groups, null, 2));
  } catch (error) {
    console.error(error?.message || error);
    process.exit(1);
  }
})();
