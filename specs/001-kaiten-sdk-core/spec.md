# Feature Specification: Kaiten SDK Core

**Feature Branch**: `001-kaiten-sdk-core`
**Created**: 2026-02-14
**Status**: Draft
**Input**: Swift-библиотека для работы с Kaiten API. Получение карточек, досок, полей (assignees, команды, платформы). Будет использоваться как зависимость в MCP-сервере.

## User Scenarios & Testing

### User Story 1 — Получить карточку по ID (Priority: P1)

Разработчик (или MCP-сервер) запрашивает детали карточки по её ID. Получает все поля: название, описание, статус, assignees, custom properties (команда, платформа).

**Why this priority**: Это базовая операция — без неё ничего не работает.

**Independent Test**: Вызвать `client.getCard(id: 123)`, получить структуру `Card` со всеми полями.

**Acceptance Scenarios**:

1. **Given** валидный токен и ID карточки, **When** вызываю `getCard(id:)`, **Then** получаю `Card` со всеми полями включая custom properties
2. **Given** невалидный ID, **When** вызываю `getCard(id:)`, **Then** получаю типизированную ошибку (не крэш)
3. **Given** невалидный токен, **When** вызываю `getCard(id:)`, **Then** получаю ошибку авторизации

---

### User Story 2 — Получить список карточек на доске (Priority: P1)

Разработчик запрашивает все карточки конкретной доски. Получает список с базовыми полями + assignees.

**Why this priority**: Нужно для обзора доски — кто чем занят, что в каком статусе.

**Independent Test**: Вызвать `client.listCards(boardId: 456)`, получить массив `[Card]`.

**Acceptance Scenarios**:

1. **Given** валидный board ID, **When** вызываю `listCards(boardId:)`, **Then** получаю массив карточек с полями
2. **Given** доска без карточек, **When** вызываю `listCards(boardId:)`, **Then** получаю пустой массив
3. **Given** невалидный board ID, **When** вызываю `listCards(boardId:)`, **Then** получаю типизированную ошибку

---

### User Story 3 — Получить members и custom properties карточки (Priority: P1)

Разработчик получает информацию о том, на кого назначена карточка (members), какой команде принадлежит, на какой платформе (через custom properties).

**Why this priority**: Ключевое для планирования — понять загрузку людей и команд.

**Independent Test**: Из полученной `Card` прочитать `members`, `customProperties` и получить типизированные значения.

**Acceptance Scenarios**:

1. **Given** карточка с members, **When** читаю `card.members`, **Then** получаю массив `[Member]` с `userId`, `fullName`, `role`
2. **Given** карточка с custom properties, **When** читаю `card.customProperties`, **Then** получаю словарь с типизированными значениями
3. **Given** карточка без members, **When** читаю `card.members`, **Then** получаю пустой массив

---

### User Story 4 — Получить структуру доски (Priority: P2)

Разработчик запрашивает доску с её колонками и lanes — чтобы понять в каком столбце какая карточка.

**Why this priority**: Нужно для визуализации и понимания flow, но не блокирует основную работу.

**Independent Test**: Вызвать `client.getBoard(id:)`, получить `Board` с `columns` и `lanes`.

**Acceptance Scenarios**:

1. **Given** валидный board ID, **When** вызываю `getBoard(id:)`, **Then** получаю `Board` с массивами `columns` и `lanes`

---

### User Story 5 — Получить список пространств и досок (Priority: P2)

Разработчик запрашивает все пространства и доски — для навигации.

**Why this priority**: Вспомогательная навигация, не критично для первой версии.

**Independent Test**: Вызвать `client.listSpaces()`, затем `client.listBoards(spaceId:)`.

**Acceptance Scenarios**:

1. **Given** валидный токен, **When** вызываю `listSpaces()`, **Then** получаю массив `[Space]`
2. **Given** валидный space ID, **When** вызываю `listBoards(spaceId:)`, **Then** получаю массив `[Board]`

### Edge Cases

- Что происходит при сетевой ошибке (timeout, DNS)? → типизированная ошибка, без крэша
- Что если API вернул неизвестные поля? → игнорируются (forward compatibility)
- Что если API вернул 429 (rate limit)? → автоматический retry с задержкой через `Task.retrying`
- Что если custom property имеет неизвестный тип? → сохраняется как raw value

## Requirements

### Functional Requirements

- **FR-001**: SDK MUST генерировать клиентский код из OpenAPI-спеки через `swift-openapi-generator`
- **FR-002**: SDK MUST поддерживать авторизацию через Bearer token
- **FR-003**: SDK MUST предоставлять типизированные модели для Card, Board, Column, Lane, Space, Member, CustomProperty
- **FR-004**: SDK MUST возвращать типизированные ошибки для всех failure cases (network, auth, not found, rate limit). Все публичные методы MUST использовать typed throws (`throws(KaitenError)`) вместо untyped `throws`.
- **FR-005**: SDK MUST принимать `baseURL` и `token` как
  явные параметры инициализации. SDK не читает конфигурацию
  самостоятельно — это ответственность вызывающего кода.
- **FR-006**: SDK MUST выбрасывать ошибку при инициализации
  (fail fast) если `baseURL` невалиден.
- **FR-007**: SDK MUST компилироваться на macOS (ARM) и Linux (x86-64 и ARM)
- **FR-008**: SDK MUST поддерживать async/await
- **FR-009**: SDK MUST использовать `swift-tools-version: 6.2` с `.swiftLanguageMode(.v6)` на каждом таргете
- **FR-010**: SDK MUST автоматически ретраить запросы при 429 (rate limit) с задержкой (configurable max retries и delay). Реализация через `ClientMiddleware`.
- **FR-012**: GitHub Actions workflows MUST иметь явные имена, описывающие что они делают (например `build-and-test.yml`, не `ci.yml`)
- **FR-013**: CI MUST кешировать SPM-зависимости между запусками для ускорения сборки
- **FR-014**: Код НЕ ДОЛЖЕН использовать `nonisolated(unsafe)`. Для мутабельного состояния в Sendable контексте использовать `Mutex` из `import Synchronization`
- **FR-015**: OpenAPI-спека MUST содержать только эндпоинты (`paths`), которые реально используются в SDK. Секция `components/schemas` MUST содержать все модели данных, необходимые для полного описания ответов этих эндпоинтов — включая вложенные объекты (User, Checklist, SLA и т.д.), даже если SDK не имеет специальной бизнес-логики для них. Пока у Kaiten нет официальной OpenAPI-спеки, мы поддерживаем минимальную hand-crafted спеку — только используемые эндпоинты + полные модели их ответов. Когда Kaiten предоставит официальную спеку, можно перейти на неё целиком.
- **FR-016**: OpenAPI-спека собирается **вручную** — у Kaiten нет публичной OpenAPI-спецификации. Спека MUST точно отражать реальное поведение API:
  - **Документация Kaiten — отправная точка**, но не абсолютная истина. Доки могут расходиться с реальным API.
  - **При расхождении доки vs API — приоритет у реального API.** Проверять поля, типы, nullable/required через реальные запросы. Пример: доки показывают полный Board для Card.board, но API возвращает только 6 полей → в спеке отдельная схема CardBoardSummary.
  - **Расхождения MUST быть задокументированы** комментарием в YAML прямо над полем/схемой (например `# NOTE: Kaiten docs show X, but API returns Y`).
  - **Разные ответы = разные схемы** — если два эндпоинта возвращают похожие, но не идентичные данные, в спеке MUST быть отдельные схемы (Board vs BoardInSpace vs CardBoardSummary).
  - **Nullable и required строго по реальному API** — проверять через запросы, а не только по докам.
  - **Перепроверка обязательна** — при любом изменении спеки сверяться с документацией + проверять реальный API. Гайд по парсингу документации: [docs/kaiten-docs-parsing.md](../../docs/kaiten-docs-parsing.md).

### Key Entities

- **Card**: id, title, description, state, column, members, customProperties, tags, created, updated
- **Board**: id, title, columns, lanes
- **Column**: id, title, sortOrder, subcolumns
- **Lane**: id, title, sortOrder
- **Space**: id, title (boards fetched separately via `listBoards(spaceId:)`)
- **Member**: id, userId, fullName, role
- **CustomProperty**: id, name, type, value (typed: string, number, select, multiselect, date, user)

## Success Criteria

### Measurable Outcomes

- **SC-001**: MCP-сервер может получить все карточки доски с assignees и custom properties одним вызовом SDK
- **SC-002**: SDK компилируется без ошибок на macOS (ARM) и Linux (x86-64 и ARM) в CI
- **SC-003**: Все P1 user stories покрыты тестами
- **SC-004**: Добавление нового эндпоинта = добавление в OpenAPI-спеку (код перегенерируется автоматически)
