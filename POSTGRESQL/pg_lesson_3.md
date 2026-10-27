# Занятие: Функции в PostgreSQL (PL/pgSQL)

**Продолжительность:** 90 минут  
**Формат:** теория, демонстрация преподавателя, совместная практика и самостоятельные задания.  
**Предварительные знания:** SQL, таблицы, переменные, `IF`, `FOR`, `FOREACH`, массивы, блоки `DO`.

## 1. Цель занятия

Научиться создавать пользовательские функции PostgreSQL, передавать параметры, возвращать результаты и использовать функции для работы с SQL-таблицами.

После занятия студенты смогут:

- Создавать функции с `CREATE FUNCTION`.
- Использовать параметры, переменные и `RETURN`.
- Применять `IF` и `ELSIF`.
- Читать данные таблиц через `SELECT ... INTO`.
- Возвращать таблицы с `RETURNS TABLE` и `RETURN QUERY`.
- Возвращать массивы через `ARRAY_AGG`.
- Изменять и удалять функции.

## 2. План занятия

| Время | Этап |
|---|---|
| 0–10 мин | Повторение PL/pgSQL и знакомство с функциями |
| 10–25 мин | `CREATE FUNCTION`, параметры и `RETURN` |
| 25–40 мин | Условия и переменные внутри функций |
| 40–55 мин | Функции, работающие с SQL-таблицами |
| 55–65 мин | Функции, возвращающие таблицы и массивы |
| 65–85 мин | Самостоятельная практика |
| 85–90 мин | Контрольные вопросы |

---

# Часть I. Теоретический материал

## 3. Что такое функция?

**Функция** — именованный блок программного кода, который можно вызывать многократно для выполнения определённой задачи.

В PostgreSQL уже есть встроенные функции:

```sql
SELECT UPPER('postgresql');
SELECT LENGTH('Hello');
SELECT ROUND(15.678, 2);
SELECT NOW();
```

| Функция | Результат |
|---|---|
| `UPPER('postgresql')` | `POSTGRESQL` |
| `LENGTH('Hello')` | `5` |
| `ROUND(15.678, 2)` | `15.68` |
| `NOW()` | Текущие дата и время |

Собственные функции позволяют повторно использовать вычисления и запросы, принимать разные входные значения и организовывать логику внутри базы данных.

## 4. Чем функция отличается от блока DO?

Ранее использовали анонимные блоки:

```sql
DO $$
DECLARE
    number INTEGER := 10;
BEGIN
    RAISE NOTICE 'Число: %', number;
END;
$$;
```

Такой блок выполняется один раз. Функция имеет имя, сохраняется в базе данных и может вызываться повторно:

```sql
CREATE FUNCTION hello()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN 'Hello, PostgreSQL!';
END;
$$;
```

```sql
SELECT hello();
```

Результат: `Hello, PostgreSQL!`.

## 5. Структура функции

```sql
CREATE FUNCTION function_name(parameters)
RETURNS return_type
LANGUAGE plpgsql
AS $$
DECLARE
    -- Локальные переменные (необязательно)
BEGIN
    -- Команды
    RETURN result;
END;
$$;
```

| Элемент | Назначение |
|---|---|
| `CREATE FUNCTION` | Создание функции |
| `function_name` | Имя функции |
| `parameters` | Входные параметры |
| `RETURNS` | Тип результата |
| `LANGUAGE plpgsql` | Язык функции |
| `DECLARE` | Локальные переменные |
| `BEGIN ... END` | Исполняемый блок |
| `RETURN` | Возвращает результат и завершает функцию |

Пример с параметром:

```sql
CREATE FUNCTION square_number(n INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN n * n;
END;
$$;
```

```sql
SELECT square_number(5);
SELECT square_number(10);
```

Результаты: `25` и `100`.

---

# Часть II. Демонстрация преподавателя

## 6. Функция с двумя параметрами

```sql
CREATE FUNCTION add_numbers(a INTEGER, b INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN a + b;
END;
$$;
```

```sql
SELECT add_numbers(10, 20);
SELECT add_numbers(5, 7);
SELECT add_numbers(-5, 10);
```

**Вопрос:** что произойдёт при вызове `add_numbers(10)`? PostgreSQL не найдёт функцию с одним целочисленным аргументом.

## 7. Переменные внутри функции

Создадим функцию для расчёта цены со скидкой:

```sql
CREATE FUNCTION calculate_discount(
    price NUMERIC,
    discount INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    final_price NUMERIC;
BEGIN
    final_price := price - price * discount / 100;
    RETURN final_price;
END;
$$;
```

```sql
SELECT calculate_discount(5000, 10);
```

Результат: `4500`.

```sql
SELECT
    calculate_discount(5000, 10) AS first_product,
    calculate_discount(8000, 20) AS second_product;
```

## 8. Условия IF внутри функции

```sql
CREATE FUNCTION check_exam(grade INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF grade >= 3 THEN
        RETURN 'Экзамен сдан';
    ELSE
        RETURN 'Экзамен не сдан';
    END IF;
END;
$$;
```

```sql
SELECT check_exam(5);
SELECT check_exam(3);
SELECT check_exam(2);
```

| Оценка | Результат |
|---|---|
| 5 | Экзамен сдан |
| 3 | Экзамен сдан |
| 2 | Экзамен не сдан |

Пример с несколькими условиями:

```sql
CREATE FUNCTION grade_description(grade INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF grade = 5 THEN
        RETURN 'Отлично';
    ELSIF grade = 4 THEN
        RETURN 'Хорошо';
    ELSIF grade = 3 THEN
        RETURN 'Удовлетворительно';
    ELSIF grade = 2 THEN
        RETURN 'Неудовлетворительно';
    ELSE
        RETURN 'Некорректная оценка';
    END IF;
END;
$$;
```

```sql
SELECT grade_description(4);
```

Результат: `Хорошо`. В PL/pgSQL для следующей ветки условия используется `ELSIF`.

---

# Часть III. Функции и SQL-таблицы

## 9. Подготовка таблицы товаров

```sql
CREATE TABLE products (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    quantity INTEGER NOT NULL
);

INSERT INTO products (name, price, quantity)
VALUES
    ('Ноутбук', 65000, 5),
    ('Мышь', 2500, 20),
    ('Клавиатура', 4500, 15),
    ('Монитор', 18000, 8),
    ('Наушники', 7000, 12),
    ('Принтер', 22000, 3);
```

## 10. Функция, читающая данные из таблицы

```sql
CREATE FUNCTION get_product_price(product_id INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    result_price NUMERIC;
BEGIN
    SELECT price
    INTO result_price
    FROM products
    WHERE id = product_id;

    RETURN result_price;
END;
$$;
```

```sql
SELECT get_product_price(1);
```

Результат: `65000`. Если товара нет, результатом будет `NULL`.

Функцию можно вызвать для каждой строки запроса:

```sql
SELECT
    name,
    price,
    get_product_price(id) AS function_price
FROM products;
```

## 11. Проверка наличия товара

```sql
CREATE FUNCTION is_product_available(product_id INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    product_quantity INTEGER;
BEGIN
    SELECT quantity
    INTO product_quantity
    FROM products
    WHERE id = product_id;

    IF product_quantity > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;
```

```sql
SELECT is_product_available(1);

SELECT
    name,
    quantity,
    is_product_available(id) AS available
FROM products;
```

**Вопрос студентам:** почему полезно вынести проверку в отдельную функцию?

## 12. Расчёт стоимости запасов

```sql
CREATE FUNCTION product_stock_value(product_id INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT price * quantity
    INTO total
    FROM products
    WHERE id = product_id;

    RETURN total;
END;
$$;
```

```sql
SELECT product_stock_value(1);
```

Результат: `325000`.

```sql
SELECT
    name,
    product_stock_value(id) AS stock_value
FROM products;
```

---

# Часть IV. Функции, возвращающие несколько строк

## 13. Что такое RETURNS TABLE?

Ранее функции возвращали одно значение (`INTEGER`, `NUMERIC`, `TEXT`, `BOOLEAN`). Функция может возвращать набор строк:

```sql
RETURNS TABLE (
    column_name data_type
)
```

В PL/pgSQL для возврата строк запроса используется `RETURN QUERY`.

## 14. Пример: дорогие товары

```sql
CREATE FUNCTION get_expensive_products(min_price NUMERIC)
RETURNS TABLE (
    product_name VARCHAR(100),
    product_price NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.name, p.price
    FROM products AS p
    WHERE p.price > min_price;
END;
$$;
```

```sql
SELECT * FROM get_expensive_products(10000);
```

| product_name | product_price |
|---|---:|
| Ноутбук | 65000 |
| Монитор | 18000 |
| Принтер | 22000 |

При `RETURNS TABLE` имена выходных столбцов также являются переменными PL/pgSQL. Псевдоним `p` помогает избежать неоднозначности имён.

## 15. Функция, возвращающая массив

```sql
CREATE FUNCTION get_product_names(min_price NUMERIC)
RETURNS TEXT[]
LANGUAGE plpgsql
AS $$
DECLARE
    names TEXT[];
BEGIN
    SELECT ARRAY_AGG(name ORDER BY name)
    INTO names
    FROM products
    WHERE price > min_price;

    RETURN COALESCE(names, ARRAY[]::TEXT[]);
END;
$$;
```

```sql
SELECT get_product_names(10000);
```

Результат: `{Монитор,Ноутбук,Принтер}`.

Здесь объединяются предыдущая тема о массивах и новая тема о функциях.

---

# Часть V. Управление функциями

## 16. Изменение функции

`CREATE OR REPLACE FUNCTION` позволяет заменить тело существующей функции при сохранении совместимых параметров и типа результата.

```sql
CREATE OR REPLACE FUNCTION check_exam(grade INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF grade < 2 OR grade > 5 THEN
        RETURN 'Некорректная оценка';
    ELSIF grade >= 3 THEN
        RETURN 'Экзамен сдан';
    ELSE
        RETURN 'Экзамен не сдан';
    END IF;
END;
$$;
```

## 17. Удаление и перегрузка функций

```sql
DROP FUNCTION check_exam(INTEGER);
```

Типы параметров указывают, какую именно функцию удалить. PostgreSQL поддерживает функции с одинаковыми именами и разными типами аргументов:

```sql
CREATE FUNCTION double_value(n INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN n * 2;
END;
$$;
```

```sql
CREATE FUNCTION double_value(n NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN n * 2;
END;
$$;
```

Это называется **перегрузкой функций**.

---

# Часть VI. Самостоятельная практическая работа

**Время:** 20 минут. Используйте таблицу `products`, созданную в разделе 9.

## Задание 1. Проверка возраста

Создайте функцию `is_adult(age INTEGER)`, которая возвращает `TRUE` для возраста 18 лет и старше и `FALSE` для возраста младше 18 лет. Проверьте несколько значений.

## Задание 2. Расчёт скидки

Создайте функцию `discount_price(price NUMERIC, discount INTEGER)`, которая:

1. Принимает цену и процент скидки.
2. Проверяет, что скидка от 0 до 100.
3. Возвращает итоговую цену.
4. Для некорректной скидки возвращает `NULL`.

## Задание 3. Поиск товара

Создайте функцию `get_product_name(product_id INTEGER)`. Она должна возвращать название товара из `products`, а если товар не найден — текст `Товар не найден`.

## Задание 4. Проверка складских остатков

Создайте функцию `check_stock(product_id INTEGER)`:

| Количество | Результат |
|---|---|
| 0 | Нет в наличии |
| 1–5 | Мало товара |
| Больше 5 | Достаточно товара |

Если товар не найден, верните `Товар не найден`.

## Задание 5. Общая стоимость склада

Создайте функцию `get_total_stock_value()` без параметров. Она должна возвращать общую стоимость всех товаров:

`SUM(price * quantity)`

Тип результата — `NUMERIC`.

## Задание 6. Список товаров

Создайте функцию `find_products(max_price NUMERIC)`, возвращающую таблицу с названиями и ценами товаров, стоимость которых не превышает заданную. Используйте `RETURNS TABLE` и `RETURN QUERY`.

## Задание 7. Функция с массивом

Создайте функцию `get_low_stock_products(limit_quantity INTEGER)`:

1. Найдите товары, остаток которых меньше заданного.
2. Соберите их названия в массив через `ARRAY_AGG`.
3. Верните массив `TEXT[]`.
4. Если подходящих товаров нет, верните пустой массив.

---

# Часть VII. Контрольные вопросы

1. Что такое пользовательская функция PostgreSQL?
2. Чем функция отличается от блока `DO`?
3. Для чего используется `CREATE FUNCTION`?
4. Какую роль играет `RETURNS`?
5. Для чего нужен `RETURN`?
6. Как передать несколько параметров в функцию?
7. Как получить данные из таблицы в переменную функции?
8. Чем отличаются `RETURN` и `RETURN QUERY`?
9. Можно ли вызвать пользовательскую функцию внутри `SELECT`?
10. Как изменить или удалить функцию?

## 18. Итоги занятия

Студенты научились создавать функции PostgreSQL, передавать параметры, использовать переменные и условия, читать данные из таблиц, возвращать отдельные значения, таблицы и массивы.

**Главная мысль:** функция превращает повторяющуюся SQL-логику в именованный инструмент, доступный из разных запросов.

**Следующая тема:** процедуры PostgreSQL (`CREATE PROCEDURE`, `CALL`), затем триггеры.
