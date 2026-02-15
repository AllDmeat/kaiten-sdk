# SDK Review & Improvement Plan

Issue #41. Полный ревью кодовой базы KaitenSDK.

---

## P1 — API Design

### 1. MockTransport: NSLock → Mutex
`MockClientTransport` помечен `@unchecked Sendable` с `NSLock`. По правилу FR-014 — нужен `Mutex` из `Synchronization`.

### 2. Write-операции отсутствуют
В OpenAPI-спеке есть, но не реализованы в SDK:
- `create_card` — создание карточки
- `update_card` — обновление карточки
- `delete_card` — удаление карточки
- `add_comment` — добавление комментария
- `retrieve_card_comments` — чтение комментариев
- `add_member_to_card` — добавление участника
- `update_member_role` — обновление роли участника
- `remove_member_from_card` — удаление участника

Для MCP write-tools это блокер.

### 3. Недостающие read-операции
Есть в спеке, не реализованы:
- `retrieve_space` — получить пространство по id
- `retrieve_card_comments` — комментарии карточки
- `retrieve_card_checklist` — чеклист карточки
- `rertrieve_list_of_tags` — теги карточки
- `retrieve_list_of_tags` — все теги
- `get_list_of_subcolumns` — подколонки

### 4. KaitenConfiguration — сделать public
Сейчас конфиг резолвится только через env. Для гибкости — дать возможность передавать конфиг явно (internal init уже есть, нужен public).

---

## P2 — Error Handling

### 5. Унифицировать обработку ответов через fromHTTPStatus
`KaitenError.fromHTTPStatus()` — хороший хелпер, но в `KaitenClient` каждый метод вручную матчит response cases. Можно унифицировать, уменьшив дублирование.

### 6. Добавить KaitenError.forbidden
403 маппится в `unexpectedResponse(statusCode: 403)` в нескольких методах. Стоит добавить отдельный case `.forbidden`.

---

## P3 — Test Coverage

### 7. RetryMiddleware: тест на парсинг Retry-After
Тест проверяет что retry происходит, но не проверяет что `Retry-After` header реально парсится.

### 8. Тесты на fromHTTPStatus
Утилитный метод без тестов.

### 9. Edge case тесты
- Пустой JSON-ответ
- Невалидный JSON
- Пустой массив (listCards с пустой доской)

---

## P4 — Documentation & Ergonomics

### 10. README: примеры кода
Нет Swift code snippet с `import KaitenSDK` и вызовом метода.

### 11. DocC documentation target
Публичные методы имеют doc-comments, но нет DocC каталога.

---

## P5 — Performance

### 12. Exponential backoff в RetryMiddleware
Дефолт 1 секунда ок, но стоит добавить exponential backoff для последовательных retry.

---

## Summary

| # | Приоритет | Предложение | Effort |
|---|-----------|-------------|--------|
| 1 | P1 | NSLock → Mutex | S |
| 2 | P1 | Write-операции (CRUD cards, comments, members) | L |
| 3 | P1 | Недостающие read-операции | M |
| 4 | P1 | Public config init | S |
| 5 | P2 | Унифицировать error handling через fromHTTPStatus | M |
| 6 | P2 | Добавить KaitenError.forbidden | S |
| 7 | P3 | Тест retry с Retry-After | S |
| 8 | P3 | Тесты fromHTTPStatus | S |
| 9 | P3 | Edge case тесты | M |
| 10 | P4 | README code examples | S |
| 11 | P4 | DocC target | M |
| 12 | P5 | Exponential backoff | S |

Жду одобрения — одобренные пункты заведу отдельными issues/задачами.
