# Практическое занятие: оптимизация базы данных

Для первой части используется база данных:

```text
movies.db
```

Для второй части:

```text
bank.db
```

---

# Часть 1. Оптимизация запросов — `movies.db`

## Задание 1. Исследование большой базы данных

Откройте базу:

```bash
sqlite3 movies.db
```

Посмотрите структуру:

```sql
.schema
```

Посмотрите несколько фильмов:

```sql
SELECT *
FROM movies
LIMIT 5;
```

Посчитайте количество записей:

```sql
SELECT COUNT(*) FROM movies;
SELECT COUNT(*) FROM people;
SELECT COUNT(*) FROM ratings;
SELECT COUNT(*) FROM stars;
```

**Обратите внимание:** база содержит большое количество записей, поэтому на ней хорошо видна разница между обычным сканированием и поиском по индексу.

---

# Задание 2. Измерение времени выполнения запроса

Включите измерение времени:

```sql
.timer on
```

Найдите фильм:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

Запустите запрос несколько раз и обратите внимание на:

```text
Run Time
```

или значение `real`, которое показывает фактическое время выполнения.

### Вопрос

Как SQLite нашёл фильм?

Проверим это в следующем задании.

---

# Задание 3. `EXPLAIN QUERY PLAN`

Выполните:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

Найдите в результате:

```text
SCAN movies
```

### Что означает `SCAN`?

SQLite последовательно просматривает строки таблицы в поисках:

```text
title = 'Cars'
```

На большой таблице такой подход может быть дорогим.

---

# Задание 4. Создание первого индекса

Создайте индекс:

```sql
CREATE INDEX title_index
ON movies(title);
```

Посмотрите схему:

```sql
.schema
```

Индекс теперь является частью структуры базы данных.

Повторите запрос:

```sql
SELECT *
FROM movies
WHERE title = 'Cars';
```

Сравните время выполнения с предыдущим результатом.

---

# Задание 5. `SCAN` против `SEARCH`

Повторите:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

Теперь вместо полного сканирования должен использоваться индекс.

Сравните:

```text
До индекса:

SCAN movies
```

```text
После индекса:

SEARCH movies USING INDEX ...
```

### Вывод

`SCAN` — просмотр большого количества строк.

`SEARCH` — поиск с использованием подходящей структуры доступа, например индекса.

---

# Задание 6. Удаление индекса

Удалите индекс:

```sql
DROP INDEX title_index;
```

Снова выполните:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE title = 'Cars';
```

Посмотрите, изменился ли план обратно на:

```text
SCAN movies
```

Теперь снова создайте индекс, чтобы использовать его далее:

```sql
CREATE INDEX title_index
ON movies(title);
```

---

# Задание 7. Почему `PRIMARY KEY` работает быстро?

Выполните:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE id = 100;
```

Сравните с:

```sql
EXPLAIN QUERY PLAN
SELECT *
FROM movies
WHERE year = 2000;
```

### Обсудите

Почему поиск по `id` не требует созданного нами индекса, а поиск по обычному столбцу может потребовать `SCAN`?

Посмотрите:

```sql
.schema movies
```

и обратите внимание на:

```sql
PRIMARY KEY("id")
```

---

# Задание 8. Сложный запрос через несколько таблиц

Найдём все фильмы, в которых снимался Tom Hanks.

Сначала выполните запрос:

```sql
SELECT title
FROM movies
WHERE id IN (
    SELECT movie_id
    FROM stars
    WHERE person_id = (
        SELECT id
        FROM people
        WHERE name = 'Tom Hanks'
    )
);
```

Включите анализ:

```sql
EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE id IN (
    SELECT movie_id
    FROM stars
    WHERE person_id = (
        SELECT id
        FROM people
        WHERE name = 'Tom Hanks'
    )
);
```

Посмотрите, какие таблицы SQLite вынужден сканировать.

Особенно обратите внимание на:

```text
people
stars
movies
```

---

# Задание 9. Оптимизация запроса через несколько таблиц

Создайте индексы:

```sql
CREATE INDEX name_index
ON people(name);

CREATE INDEX person_index
ON stars(person_id);
```

Повторите:

```sql
EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE id IN (
    SELECT movie_id
    FROM stars
    WHERE person_id = (
        SELECT id
        FROM people
        WHERE name = 'Tom Hanks'
    )
);
```

Сравните новый план с предыдущим.

### Определите

Какие `SCAN` исчезли?

Какие `SEARCH` появились?

---

# Задание 10. Covering Index

Сейчас индекс содержит:

```text
person_id
```

Но запросу также требуется:

```text
movie_id
```

Удалите старый индекс:

```sql
DROP INDEX person_index;
```

Создайте составной индекс:

```sql
CREATE INDEX person_index
ON stars(person_id, movie_id);
```

Снова выполните:

```sql
EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE id IN (
    SELECT movie_id
    FROM stars
    WHERE person_id = (
        SELECT id
        FROM people
        WHERE name = 'Tom Hanks'
    )
);
```

Найдите:

```text
COVERING INDEX
```

### Идея

Если вся необходимая запросу информация уже находится внутри индекса, SQLite может не обращаться дополнительно к самой таблице.

---

# Задание 11. Почему не нужно создавать индекс для каждого столбца?

Посмотрите текущие индексы:

```sql
.indexes
```

Можно также посмотреть индексы конкретной таблицы:

```sql
PRAGMA index_list('movies');
```

Теперь создайте ещё один индекс:

```sql
CREATE INDEX year_index
ON movies(year);
```

Посмотрите список снова:

```sql
.indexes
```

### Обсудите

Индекс ускоряет некоторые операции чтения, но:

- занимает дополнительное место;
- должен обновляться при `INSERT`;
- должен обновляться при `UPDATE`;
- должен обновляться при `DELETE`.

Следовательно, больше индексов — не всегда лучше.

---

# Задание 12. Partial Index

Представим, что приложение особенно часто показывает фильмы определённого года.

Создайте частичный индекс, например для 2023 года:

```sql
CREATE INDEX recent_movies
ON movies(title)
WHERE year = 2023;
```

Проверьте:

```sql
EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE year = 2023;
```

Затем сравните с:

```sql
EXPLAIN QUERY PLAN
SELECT title
FROM movies
WHERE year = 2000;
```

### Обсудите

Partial Index хранит индекс не для всей таблицы, а только для строк, удовлетворяющих условию.

---

# Задание 13. Цена индексов — размер базы данных

Выйдите из SQLite:

```sql
.quit
```

Проверьте размер файла.

### Linux/macOS

```bash
du -b movies.db
```

Запомните размер.

Вернитесь:

```bash
sqlite3 movies.db
```

Посмотрите индексы:

```sql
.indexes
```

Удалите несколько созданных индексов:

```sql
DROP INDEX title_index;
DROP INDEX name_index;
DROP INDEX person_index;
DROP INDEX year_index;
DROP INDEX recent_movies;
```

Снова выйдите:

```sql
.quit
```

Проверьте размер:

```bash
du -b movies.db
```

### Вопрос

Почему после `DROP INDEX` файл базы данных может не уменьшиться сразу?

---

# Задание 14. `VACUUM`

Снова откройте базу:

```bash
sqlite3 movies.db
```

Выполните:

```sql
VACUUM;
```

Выйдите:

```sql
.quit
```

Снова:

```bash
du -b movies.db
```

Сравните:

```text
размер до удаления индексов
        ↓
размер после DROP INDEX
        ↓
размер после VACUUM
```

### Вывод

`VACUUM` перестраивает файл базы данных и позволяет освободить неиспользуемое пространство.

---

# Часть 2. Транзакции — `bank.db`

Откройте:

```bash
sqlite3 bank.db
```

Посмотрите структуру:

```sql
.schema
```

Посмотрите счета:

```sql
SELECT *
FROM accounts;
```

---

# Задание 15. Банковский перевод без транзакции

Представим:

```text
Alice → Bob
10 денежных единиц
```

Сначала увеличим баланс Bob:

```sql
UPDATE accounts
SET balance = balance + 10
WHERE id = 2;
```

Проверьте:

```sql
SELECT * FROM accounts;
```

Но баланс Alice мы ещё не уменьшили.

Только после этого выполняем:

```sql
UPDATE accounts
SET balance = balance - 10
WHERE id = 1;
```

### Проблема

Между двумя запросами база находилась в промежуточном состоянии.

Если приложение завершится после первого `UPDATE`, деньги Bob увеличатся, но деньги Alice ещё не будут списаны.

---

# Задание 16. Банковский перевод как транзакция

Теперь выполним перевод как единую операцию:

```sql
BEGIN TRANSACTION;

UPDATE accounts
SET balance = balance + 10
WHERE id = 2;

UPDATE accounts
SET balance = balance - 10
WHERE id = 1;

COMMIT;
```

Проверьте:

```sql
SELECT * FROM accounts;
```

### Структура

```text
BEGIN
  ↓
UPDATE
  ↓
UPDATE
  ↓
COMMIT
```

Операции рассматриваются как одна логическая транзакция.

---

# Задание 17. Работа с незавершённой транзакцией

Начните:

```sql
BEGIN TRANSACTION;
```

Измените баланс:

```sql
UPDATE accounts
SET balance = balance + 100
WHERE id = 2;
```

Посмотрите результат:

```sql
SELECT * FROM accounts;
```

Но пока **не выполняйте `COMMIT`**.

Теперь вместо сохранения выполните:

```sql
ROLLBACK;
```

Снова:

```sql
SELECT * FROM accounts;
```

### Вопрос

Остались ли дополнительные `100` на счёте?

---

# Задание 18. Ошибка внутри банковского перевода

Посмотрите баланс Alice:

```sql
SELECT *
FROM accounts
WHERE id = 1;
```

Попробуйте выполнить перевод, при котором баланс Alice станет отрицательным:

```sql
BEGIN TRANSACTION;

UPDATE accounts
SET balance = balance + 100000
WHERE id = 2;

UPDATE accounts
SET balance = balance - 100000
WHERE id = 1;
```

Второй запрос должен нарушить:

```sql
CHECK(balance >= 0)
```

После ошибки выполните:

```sql
ROLLBACK;
```

Проверьте:

```sql
SELECT * FROM accounts;
```

Изменения транзакции должны быть отменены.

---

# Задание 19. ACID на примере банка

На выполненном переводе определите значение каждого свойства:

```text
A — Atomicity
C — Consistency
I — Isolation
D — Durability
```

Свяжите каждое свойство с конкретной ситуацией:

```text
Перевод должен выполниться полностью или не выполниться вообще.

Баланс не должен нарушать CHECK(balance >= 0).

Два клиента не должны мешать операциям друг друга.

После COMMIT сохранённый перевод не должен просто исчезнуть.
```

---

# Часть 3. Конкурентность

Для следующих заданий нужны **два терминала**.

Оба терминала должны открыть один и тот же файл:

```bash
sqlite3 bank.db
```

Получим:

```text
Терминал №1 ──┐
              ├── bank.db
Терминал №2 ──┘
```

---

# Задание 20. Два клиента одновременно

### Терминал №1

```sql
SELECT * FROM accounts;
```

### Терминал №2

```sql
SELECT * FROM accounts;
```

Оба клиента могут читать базу данных.

Теперь в первом терминале начните транзакцию:

```sql
BEGIN TRANSACTION;
```

Измените баланс:

```sql
UPDATE accounts
SET balance = balance + 10
WHERE id = 1;
```

**Не выполняйте `COMMIT`.**

Во втором терминале попробуйте выполнить изменение:

```sql
UPDATE accounts
SET balance = balance + 20
WHERE id = 2;
```

Посмотрите на поведение SQLite.

---

# Задание 21. Завершение блокировки

Вернитесь в первый терминал.

Выполните:

```sql
COMMIT;
```

После этого снова попробуйте во втором терминале:

```sql
UPDATE accounts
SET balance = balance + 20
WHERE id = 2;
```

### Обсудите

Почему операция стала возможной после завершения первой транзакции?

---

# Задание 22. `BEGIN EXCLUSIVE TRANSACTION`

В первом терминале:

```sql
BEGIN EXCLUSIVE TRANSACTION;
```

Оставьте транзакцию открытой.

Теперь во втором терминале попробуйте:

```sql
SELECT *
FROM accounts;
```

или выполнить изменение:

```sql
UPDATE accounts
SET balance = balance + 1
WHERE id = 2;
```

Можно получить:

```text
database is locked
```

Вернитесь в первый терминал:

```sql
COMMIT;
```

Повторите запрос во втором терминале.

---

# Задание 23. Race Condition — обсуждение

Представьте ситуацию:

```text
Баланс Alice = 100
```

Два клиента почти одновременно хотят выполнить:

```text
Клиент №1: снять 80
Клиент №2: снять 80
```

Оба сначала проверяют:

```sql
SELECT balance
FROM accounts
WHERE id = 1;
```

Оба получают:

```text
100
```

И оба решают:

```text
80 <= 100
```

следовательно, денег достаточно.

### Вопрос

Что может произойти, если проверка баланса и его изменение выполняются как независимые операции без правильной организации транзакций?

Это пример проблемы конкурентного доступа — **Race Condition**.

---

# Итоговый эксперимент

Вернитесь к `movies.db` и ответьте:

1. Чем `SCAN` отличается от `SEARCH`?
2. Для чего используется `EXPLAIN QUERY PLAN`?
3. Зачем нужен `CREATE INDEX`?
4. Что такое `COVERING INDEX`?
5. Почему нельзя бездумно индексировать каждый столбец?
6. Что такое `PARTIAL INDEX`?
7. Для чего используется `VACUUM`?

Затем по `bank.db`:

8. Для чего нужен `BEGIN TRANSACTION`?
9. Чем `COMMIT` отличается от `ROLLBACK`?
10. Что означает атомарность транзакции?
11. Что такое Race Condition?
12. Зачем СУБД нужны блокировки?
13. Что произойдёт, если оставить `EXCLUSIVE`-транзакцию незавершённой?