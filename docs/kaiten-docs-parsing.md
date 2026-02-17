# Парсинг документации Kaiten API

## Проблема
Документация Kaiten (https://developers.kaiten.ru) — SPA на JavaScript. `web_fetch` не работает (возвращает пустую страницу). Нужен реальный браузер.

## Как парсить

### 1. Используй Playwright (Python)
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
    page = browser.new_page()
    page.goto(url, wait_until='networkidle', timeout=30000)
    page.wait_for_timeout(3000)  # SPA нужно время на рендер
    content = page.text_content('body')
    browser.close()
```

### 2. Структура URL
```
https://developers.kaiten.ru/{section}/{action}
```
Примеры:
- `https://developers.kaiten.ru/columns/get-list-of-columns`
- `https://developers.kaiten.ru/lanes/get-list-of-lanes`
- `https://developers.kaiten.ru/space-boards/get-list-of-boards`
- `https://developers.kaiten.ru/custom-properties/get-list-of-properties`
- `https://developers.kaiten.ru/cards/retrieve-card-list`
- `https://developers.kaiten.ru/cards/retrieve-card`
- `https://developers.kaiten.ru/spaces/retrieve-list-of-spaces`

### 3. Структура контента на странице (text_content)
Страница возвращает **сплошной текст** без разделителей. Структура:
```
[Навигация (сайдбар)]...[Название эндпоинта]GET|POST|...[URL шаблон]
Path parameters → Name | Type | Reference | Description
Query → Name | Type | Constraints | Description
Responses → 200 | 401 | 403 | 404
Response Attributes → Name | Type | Description
[Примеры curl/node/php]
[Футер]
```

### 4. Как находить нужную секцию
```python
# Найти начало описания эндпоинта
idx = content.find('Path parameters')
# или
idx = content.find('Query')  # для query params
# или
idx = content.find('Response Attributes')  # для полей ответа

# Вырезать кусок вокруг
section = content[max(0, idx-100) : idx+2000]
```

### 5. Как определить наличие пагинации
Искать в Query parameters секции:
- `offset` + `limit` — классическая пагинация Kaiten
- Если их нет — эндпоинт возвращает всё одним запросом

### 6. Как определить обязательность полей
В Response Attributes тип поля указывает на nullable:
- `string`, `integer`, `boolean` — **обязательное** (non-null)
- `null | string`, `null | integer`, `null | array`, `null | object` — **опциональное** (nullable)
- `enum` — обязательное, значения описаны в Description (например `1-queued, 2-inProgress, 3-done`)

Примеры из GET /cards:
- `id` → `integer` → обязательное
- `title` → `string` → обязательное
- `description` → `null | string` → опциональное
- `due_date` → `null | string` → опциональное
- `archived` → `boolean` → обязательное
- `properties` → `null | object` → опциональное
- `parents_ids` → `null | array` → опциональное

В Path parameters поле помечено `required` явно (например `board_id required integer`).
В Query parameters `required` указан как constraint, если не указан — параметр опциональный.

### 7. Batch-парсинг нескольких эндпоинтов
```python
urls = {
    'columns': 'https://developers.kaiten.ru/columns/get-list-of-columns',
    'lanes': 'https://developers.kaiten.ru/lanes/get-list-of-lanes',
    # ...
}

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, args=['--no-sandbox'])
    page = browser.new_page()
    for name, url in urls.items():
        page.goto(url, wait_until='networkidle', timeout=30000)
        content = page.text_content('body')
        # парсим нужные секции
    browser.close()
```

### 8. Важные нюансы
- **Один браузер, много page.goto()** — не создавай новый браузер на каждый URL
- **wait_for_timeout(3000)** — иногда нужен после networkidle для полного рендера
- **text_content('body')** — возвращает весь текст без HTML тегов
- Chromium установлен через `playwright install chromium`
- Запуск обязательно с `args=['--no-sandbox']` (мы под root)
- Playwright установлен: `pip install --break-system-packages playwright && playwright install chromium`
