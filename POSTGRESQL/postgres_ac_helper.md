# Шпаргалка для студентов

## Пользователи, роли и права доступа в PostgreSQL

### 1. Пользователи и роли

**Роль (`ROLE`)** — объект PostgreSQL, которому можно назначать права доступа.

**Пользователь (`USER`)** — роль с возможностью подключения к серверу (`LOGIN`).

| Команда | Назначение |
|---|---|
| `CREATE ROLE` | Создать роль |
| `CREATE USER` | Создать пользователя |
| `ALTER ROLE` | Изменить настройки роли |
| `DROP ROLE` | Удалить роль |
| `GRANT` | Предоставить права |
| `REVOKE` | Отозвать права |

### 2. Создание пользователей

```sql
-- Создать пользователя
CREATE USER gb_manager
WITH PASSWORD 'training_password';

-- Создать роль без права подключения
CREATE ROLE gb_readonly NOLOGIN;

-- Создать роль с правом подключения
CREATE ROLE gb_seller
WITH LOGIN PASSWORD 'training_password';
```

Пароли приведены только для учебного примера.

Просмотр существующих ролей:

```sql
SELECT rolname, rolcanlogin, rolsuper
FROM pg_roles;
```

Изменение параметров:

```sql
-- Изменить пароль
ALTER ROLE gb_manager
WITH PASSWORD 'new_password';

-- Запретить подключение
ALTER ROLE gb_manager NOLOGIN;

-- Разрешить подключение
ALTER ROLE gb_manager LOGIN;
```

### 3. Основные права доступа

| Право | Что разрешает |
|---|---|
| `SELECT` | Просматривать данные |
| `INSERT` | Добавлять записи |
| `UPDATE` | Изменять записи |
| `DELETE` | Удалять записи |
| `TRUNCATE` | Очищать таблицу |
| `ALL PRIVILEGES` | Все доступные привилегии на объект |

### 4. Предоставление прав — GRANT

**Синтаксис:**

```sql
GRANT право ON объект TO пользователь;
```

Примеры для GameBox:

```sql
-- Разрешить доступ к схеме
GRANT USAGE ON SCHEMA gamebox_lab
TO gb_manager;

-- Разрешить просмотр товаров
GRANT SELECT
ON gamebox_lab.products
TO gb_manager;

-- Разрешить добавление и изменение
GRANT INSERT, UPDATE
ON gamebox_lab.products
TO gb_manager;

-- Предоставить все права на таблицу
GRANT ALL PRIVILEGES
ON gamebox_lab.products
TO gb_manager;
```

**Важно:** право `USAGE` на схему и право `SELECT` на таблицу — разные разрешения. Для чтения таблицы обычно необходимы оба.

### 5. Отзыв прав — REVOKE

**Синтаксис:**

```sql
REVOKE право ON объект FROM пользователь;
```

Примеры:

```sql
-- Отозвать право изменения товаров
REVOKE UPDATE
ON gamebox_lab.products
FROM gb_manager;

-- Отозвать право удаления
REVOKE DELETE
ON gamebox_lab.products
FROM gb_manager;

-- Отозвать все напрямую выданные права
REVOKE ALL PRIVILEGES
ON gamebox_lab.products
FROM gb_manager;
```

`REVOKE` отзывает предоставленные привилегии, но пользователь может сохранять доступ через другие роли, `PUBLIC` или право собственности на объект.

### 6. Групповые роли

Групповая роль позволяет назначить одинаковые права нескольким пользователям.

Если роль `gb_readonly` ещё не создана, выполните:

```sql
CREATE ROLE gb_readonly NOLOGIN;
```

Настройка группы:

```sql
-- Разрешить доступ к схеме
GRANT USAGE ON SCHEMA gamebox_lab
TO gb_readonly;

-- Разрешить чтение таблиц
GRANT SELECT
ON gamebox_lab.products, gamebox_lab.sales
TO gb_readonly;

-- Добавить пользователя в группу
GRANT gb_readonly TO gb_analyst;
```

Теперь `gb_analyst` может получать права через `gb_readonly` при стандартных настройках наследования. Предполагается, что пользователь `gb_analyst` уже создан.

Удаление пользователя из группы:

```sql
REVOKE gb_readonly FROM gb_analyst;
```

### 7. Проверка прав пользователя

Для проверки разрешений используется функция `has_table_privilege()`.

```sql
-- Может ли аналитик читать товары?
SELECT has_table_privilege(
    'gb_analyst',
    'gamebox_lab.products',
    'SELECT'
);

-- Может ли менеджер удалять товары?
SELECT has_table_privilege(
    'gb_manager',
    'gamebox_lab.products',
    'DELETE'
);
```

| Результат | Значение |
|---|---|
| `true` | Право имеется |
| `false` | Право отсутствует |

Чтобы узнать, под каким пользователем выполняется запрос:

```sql
SELECT current_user;
```

Для проверки ограничений необходимо подключиться к базе под соответствующим пользователем. В pgAdmin можно создать отдельное подключение с его учётными данными.

### 8. Пример разграничения доступа в GameBox

| Пользователь | Таблица | Разрешённые действия |
|---|---|---|
| `gb_manager` | `products` | `SELECT`, `INSERT`, `UPDATE` |
| `gb_seller` | `products` | `SELECT` |
| `gb_seller` | `sales` | `SELECT`, `INSERT` |
| `gb_analyst` | `products`, `sales` | `SELECT` |

Для назначения прав необходимо использовать `GRANT`, а для отмены ранее выданных разрешений — `REVOKE`.

### 9. Частые ошибки

| Ошибка | Возможная причина |
|---|---|
| `permission denied for table` | Недостаточно прав на таблицу |
| `permission denied for schema` | Нет права `USAGE` на схему |
| `permission denied to create role` | Нет полномочий создавать роли |
| `role already exists` | Роль с таким названием уже существует |
| `role does not exist` | Указана несуществующая роль |
| `permission denied for database` | Нет необходимого права доступа к базе данных |

### 10. Главное, что нужно запомнить

- **`CREATE USER`** — создать пользователя для подключения к PostgreSQL.
- **`GRANT`** — предоставить права на чтение, добавление, изменение или удаление.
- **`REVOKE`** — отозвать ранее предоставленные права.
- **Групповые роли** — управлять одинаковыми правами нескольких пользователей.

**Основной принцип безопасности:** каждый пользователь должен иметь только те права, которые необходимы ему для работы.

*Примечание: команды создания ролей и предоставления привилегий выполняются от имени пользователя с соответствующими административными полномочиями.*
