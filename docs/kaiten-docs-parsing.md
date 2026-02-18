# Parsing Kaiten API Documentation

## Problem
The Kaiten documentation (https://developers.kaiten.ru) is a JavaScript SPA. `web_fetch` does not work (returns an empty page). A real browser is needed.

## How to Parse

### 1. Use Playwright (Node.js — preferred)

The key insight: **do NOT use `document.body.innerText`** — it mixes the sidebar navigation with the API content. Instead, find the specific `MuiBox-root` div that contains just the endpoint documentation.

```javascript
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ args: ['--no-sandbox'] });
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(3000); // SPA needs time to render

    // Extract ONLY the endpoint content (not sidebar nav)
    const content = await page.evaluate(() => {
        const divs = [...document.querySelectorAll('div.MuiBox-root')];
        // Find the smallest div that contains the endpoint content
        const endpointDiv = divs.find(el => {
            const t = el.innerText.trim();
            return t.includes('Path parameters') && t.length < 5000
                && !t.includes('Create new space'); // exclude sidebar
        });
        return endpointDiv ? endpointDiv.innerText : document.body.innerText;
    });

    console.log(content);
    await browser.close();
})();
```

### 2. URL Structure
```
https://developers.kaiten.ru/{section}/{action}
```

#### Finding Available Endpoints

To discover all endpoints for a section, extract sidebar links:

```javascript
const links = await page.evaluate(() => {
    return [...document.querySelectorAll('a')]
        .map(a => ({ text: a.textContent.trim(), href: a.href }))
        .filter(l => l.href.includes('developers.kaiten.ru')
            && l.text.match(/comment|checklist|card/i)); // adjust filter
});
```

#### Known URL Examples
- `https://developers.kaiten.ru/cards/retrieve-card-list`
- `https://developers.kaiten.ru/cards/retrieve-card`
- `https://developers.kaiten.ru/card-comments/add-comment`
- `https://developers.kaiten.ru/card-comments/update-comment`
- `https://developers.kaiten.ru/card-checklists/add-checklist-to-card`
- `https://developers.kaiten.ru/card-checklist-items/add-item-to-checklist`
- `https://developers.kaiten.ru/columns/get-list-of-columns`
- `https://developers.kaiten.ru/lanes/get-list-of-lanes`
- `https://developers.kaiten.ru/spaces/retrieve-list-of-spaces`
- `https://developers.kaiten.ru/custom-properties/get-list-of-properties`

### 3. Page Content Structure

The extracted content has this structure (tab-separated table rows):

```
[Endpoint name]
[METHOD]
[URL template]
Path parameters
Name    Type    Reference
field_name    type    Description
...
Headers
...
Attributes (body params)
Name    Type    Constraints    Description
field_name    type    minLength: N, maxLength: M    Description
...
Responses
200  400  401  403  404
Response Attributes
Name    Type    Description
field_name    type    Description
...
Examples
[curl/node/php examples]
```

### 4. Batch Parsing Multiple Endpoints

Reuse one browser instance:

```javascript
const { chromium } = require('playwright');

const urls = [
    ['update-comment', 'https://developers.kaiten.ru/card-comments/update-comment'],
    ['add-checklist', 'https://developers.kaiten.ru/card-checklists/add-checklist-to-card'],
    // ...
];

(async () => {
    const browser = await chromium.launch({ args: ['--no-sandbox'] });
    const page = await browser.newPage();

    for (const [name, url] of urls) {
        await page.goto(url, { waitUntil: 'networkidle' });
        await page.waitForTimeout(2000);

        const content = await page.evaluate(() => {
            const divs = [...document.querySelectorAll('div.MuiBox-root')];
            const endpointDiv = divs.find(el => {
                const t = el.innerText.trim();
                return t.includes('Path parameters') && t.length < 5000
                    && !t.includes('Create new space');
            });
            return endpointDiv ? endpointDiv.innerText : 'NOT FOUND';
        });

        console.log(`\n${'='.repeat(60)}`);
        console.log(`ENDPOINT: ${name}`);
        console.log('='.repeat(60));
        console.log(content);
    }

    await browser.close();
})();
```

### 5. How to Determine Pagination Support
Look in the Query parameters section:
- `offset` + `limit` — classic Kaiten pagination
- If absent — the endpoint returns everything in a single request

### 6. How to Determine Field Requiredness
In Response Attributes, the field type indicates nullability:
- `string`, `integer`, `boolean` — **required** (non-null)
- `null | string`, `null | integer`, `null | array`, `null | object` — **optional** (nullable)
- `enum` — required, values are described in Description (e.g. `1-queued, 2-inProgress, 3-done`)

In Path parameters, a field is marked `required` explicitly.
In Query/Body parameters, `required` is indicated as a constraint; if not indicated — optional.

### 7. Expanding Nested Schemas (Schema Buttons)

Fields with type `object Schema` or `array Schema` have a **Schema** button (MUI Button) that opens a **modal dialog** with nested field descriptions. The content extractor above does **NOT** include schema dialog contents — you need to click the button.

```javascript
// Find all Schema buttons
const buttons = await page.$$('button.MuiButton-root');
const schemaButtons = [];
for (const btn of buttons) {
    const text = await btn.textContent();
    if (text.trim() === 'Schema') schemaButtons.push(btn);
}

for (const btn of schemaButtons) {
    // Get field name from the table row
    const fieldInfo = await btn.evaluate(
        el => el.closest('tr')?.textContent || 'unknown'
    );

    await btn.click({ timeout: 3000 });
    await page.waitForTimeout(1000);

    // Read the dialog contents
    const dialog = await page.$('.MuiDialog-root');
    if (dialog) {
        const schemaText = await dialog.textContent();
        console.log(`${fieldInfo}: ${schemaText}`);

        // Close dialog before next click
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
    }
}
```

#### Nested Schemas Inside the Dialog (MuiLink)

Inside an opened dialog, fields with type `array` or `object` may be **clickable links** (`button.MuiLink-root`). Clicking them replaces the dialog content with the nested schema.

```javascript
// After opening the main Schema dialog:
const dialog = await page.$('.MuiDialog-root');
if (dialog) {
    const linkButtons = await dialog.$$('button.MuiLink-root');
    for (const lb of linkButtons) {
        const text = await lb.textContent();
        await lb.click({ timeout: 3000 });
        await page.waitForTimeout(1000);

        const updatedDialog = await page.$('.MuiDialog-root');
        const nestedText = await updatedDialog.textContent();
        console.log(nestedText);

        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
    }
}
```

### 8. Verifying Against Real API

After parsing docs, **always verify with a real API request**:

```bash
URL=$(jq -r .url ~/.config/kaiten/config.json)
TOKEN=$(jq -r .token ~/.config/kaiten/config.json)

curl -s -H "Authorization: Bearer $TOKEN" \
    "$URL/cards/47271507/checklists/12345" | python3 -m json.tool
```

The real API response is the source of truth. Docs may be incomplete or outdated — the API response shows the actual field names, types, and nullability.

### 9. Important Notes
- **Node.js preferred** — Playwright JS is already installed (`require('playwright')`)
- **One browser, many pages** — don't create a new browser for each URL
- **wait_for_timeout(2000-3000)** — needed after networkidle for SPA rendering
- **`--no-sandbox`** — required (running as root)
- **Never use `document.body.innerText`** — it mixes sidebar nav with content
- **Selector: `div.MuiBox-root`** — filter by content to find the endpoint div
- **Exclude sidebar**: check that the div does NOT contain `Create new space` (sidebar marker)
