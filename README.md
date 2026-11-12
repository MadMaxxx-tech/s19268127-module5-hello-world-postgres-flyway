# Go + Postgres + Flyway Example

## Описание

Пример Go-приложения, подключающегося к базе данных Postgres, мигрируемой с помощью Flyway. Postgres поднимается через Docker Compose.

## Структура
- `main.go` — основной код приложения
- `go.mod` — зависимости Go
- `db/migration/` — SQL-миграции для Flyway
- `docker-compose.yml` — запуск Postgres
- `flyway.conf` — конфиг Flyway (используется для параметров подключения к БД при миграциях)
- `.env` — переменные окружения для docker-compose (создайте при необходимости)

## Быстрый старт

### 1. Настройка переменных окружения для БД

Docker Compose использует переменные окружения из файла `.env` в текущей директории. Пример содержимого `.env`:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
POSTGRES_PORT=5432
```

Если файл `.env` не создан, будут использованы значения по умолчанию.

### 2. Запуск Postgres

```bash
docker-compose up -d
```

### 3. Применение миграций Flyway

Flyway использует параметры подключения к базе данных из файла `flyway.conf` в корне проекта. Пример содержимого:

```properties
flyway.url=jdbc:postgresql://localhost:5432/postgres
flyway.user=postgres
flyway.password=postgres
flyway.locations=filesystem:db/migration
```

- [Скачать Flyway CLI](https://flywaydb.org/download/community)
- Применить миграции:

```bash
flyway migrate
```

(или через docker:)

```bash
docker run --rm -v $(pwd)/db/migration:/flyway/sql flyway/flyway -configFiles=flyway.conf migrate
```

### 4. Сборка и запуск Go-приложения

#### Сборка с указанием версии

Вы можете указать версию сборки при компиляции с помощью `-ldflags`:

```bash
go build -ldflags "-X main.buildVersion=4.0.0" -o app_4.0.0
```

Где `4.0.0` — ваша версия.

#### Запуск

```bash
./app_4.0.0
```

## Переменные окружения для подключения к базе данных

- `POSTGRES_HOST` — адрес сервера Postgres (по умолчанию: `localhost`)
- `POSTGRES_PORT` — порт Postgres (по умолчанию: `5432`)
- `POSTGRES_USER` — имя пользователя (по умолчанию: `postgres`)
- `POSTGRES_PASSWORD` — пароль пользователя (по умолчанию: `postgres`)
- `POSTGRES_DB` — имя базы данных (по умолчанию: `postgres`)

Если переменные не заданы, используются значения по умолчанию.

## Проверка
- После отправки формы на главной странице данные сохраняются в базе, а на экране появляется приветствие с введёнными именем, фамилией и временем регистрации. 