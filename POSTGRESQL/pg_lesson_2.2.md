# Практическая работа №15
## Массивы и SQL-таблицы в PostgreSQL

---

## Задание 1. Поиск товаров по списку идентификаторов

### Подготовка таблицы

```sql
CREATE TABLE products (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    quantity INTEGER NOT NULL
);

INSERT INTO products (name, price, quantity)
VALUES
    ('Ноутбук Lenovo', 65000, 8),
    ('Мышь Logitech', 2500, 25),
    ('Монитор Samsung', 18000, 12),
    ('Клавиатура HyperX', 7500, 10),
    ('Наушники Sony', 12000, 7),
    ('Принтер HP', 22000, 4),
    ('Флешка Kingston', 900, 40),
    ('SSD Samsung', 8500, 15),
    ('Веб-камера Logitech', 5500, 6),
    ('Микрофон Fifine', 4200, 9);
```

### Задание

Объявите массив идентификаторов товаров:

```sql
product_ids INTEGER[] := ARRAY[2, 4, 6, 8];
```

1. Выведите товары, идентификаторы которых присутствуют в массиве.
2. Получите названия найденных товаров в массив через `ARRAY_AGG`.
3. Выведите массив через `RAISE NOTICE`.
4. Найдите среди выбранных товары дороже 5000 рублей.
5. Выведите количество найденных товаров.

Используйте `ANY`, `ARRAY_AGG` и `CARDINALITY`.

---

## Задание 2. Обновление остатков из массивов

### Подготовка таблицы

```sql
CREATE TABLE warehouse (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL
);

INSERT INTO warehouse (product_name, quantity)
VALUES
    ('Ноутбук', 10),
    ('Монитор', 5),
    ('Клавиатура', 30),
    ('Мышь', 50),
    ('Принтер', 3),
    ('Сканер', 7),
    ('Наушники', 20);
```

### Задание

Используйте два массива одинаковой длины:

```sql
product_ids INTEGER[] := ARRAY[1, 3, 5];
new_quantities INTEGER[] := ARRAY[20, 15, 40];
```

1. Пройдите по массивам с помощью цикла `FOR`.
2. Обновите количество товаров в таблице по соответствующим идентификаторам.
3. Выведите сообщение об обновлении каждого товара.
4. Проверьте итоговые значения.
5. Предусмотрите ситуацию, когда идентификатор отсутствует в таблице.

---

## Задание 3. Анализ оценок студентов

### Подготовка таблиц

```sql
CREATE TABLE students (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    group_name VARCHAR(20) NOT NULL
);

CREATE TABLE grades (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES students(id),
    subject VARCHAR(100) NOT NULL,
    grade INTEGER NOT NULL CHECK (grade BETWEEN 2 AND 5)
);

INSERT INTO students (full_name, group_name)
VALUES
    ('Александр Иванов', 'ИС-101'),
    ('Мария Петрова', 'ИС-101'),
    ('Иван Сидоров', 'ИБ-102'),
    ('Анна Смирнова', 'ИБ-102'),
    ('Дмитрий Козлов', 'ИС-101'),
    ('Елена Волкова', 'ИБ-102');

INSERT INTO grades (student_id, subject, grade)
VALUES
    (1, 'PostgreSQL', 5),
    (1, 'Python', 4),
    (1, 'Сети', 5),
    (2, 'PostgreSQL', 4),
    (2, 'Python', 5),
    (2, 'Сети', 4),
    (3, 'PostgreSQL', 3),
    (3, 'Python', 2),
    (3, 'Сети', 4),
    (4, 'PostgreSQL', 5),
    (4, 'Python', 5),
    (4, 'Сети', 5),
    (5, 'PostgreSQL', 3),
    (5, 'Python', 4),
    (5, 'Сети', 2),
    (6, 'PostgreSQL', 4),
    (6, 'Python', 3),
    (6, 'Сети', 4);
```

### Задание

1. Получите массив оценок выбранного студента с помощью `ARRAY_AGG`.
2. Обработайте массив через `FOREACH`.
3. Вычислите среднюю оценку.
4. Подсчитайте количество пятёрок и двоек.
5. Если средняя оценка ниже 3,5, выведите сообщение о необходимости дополнительной подготовки.
6. Получите массив имён студентов, средняя оценка которых выше 4,5.

---

## Задание 4. Перенос сотрудников в другую таблицу через массив

### Подготовка таблиц

```sql
CREATE TABLE employees (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL
);

CREATE TABLE high_salary_employees (
    id INTEGER PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL
);

INSERT INTO employees (full_name, department, salary)
VALUES
    ('Александр Иванов', 'IT', 85000),
    ('Мария Петрова', 'HR', 55000),
    ('Иван Сидоров', 'IT', 72000),
    ('Анна Смирнова', 'Finance', 95000),
    ('Дмитрий Козлов', 'IT', 60000),
    ('Елена Волкова', 'HR', 68000),
    ('Сергей Орлов', 'Finance', 78000),
    ('Ольга Морозова', 'IT', 110000),
    ('Павел Фёдоров', 'Sales', 50000),
    ('Наталья Белова', 'Finance', 63000);
```

### Задание

1. Получите массив идентификаторов сотрудников с зарплатой выше 60 000 рублей.
2. Используя `FOREACH`, пройдите по массиву.
3. Получите данные каждого сотрудника из таблицы `employees`.
4. Добавьте сотрудников в `high_salary_employees`.
5. Выведите количество перенесённых сотрудников.
6. Проверьте, что в новую таблицу не попали сотрудники с зарплатой 60 000 рублей или меньше.

---

## Задание 5. Формирование списка заказов

### Подготовка таблиц

```sql
CREATE TABLE customers (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE orders (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO customers (full_name, city)
VALUES
    ('Александр Иванов', 'Москва'),
    ('Мария Петрова', 'Казань'),
    ('Иван Сидоров', 'Самара'),
    ('Анна Смирнова', 'Москва'),
    ('Дмитрий Козлов', 'Казань');

INSERT INTO orders (customer_id, order_date, status)
VALUES
    (1, '2026-09-01', 'completed'),
    (1, '2026-09-05', 'pending'),
    (2, '2026-09-02', 'completed'),
    (2, '2026-09-07', 'cancelled'),
    (3, '2026-09-03', 'pending'),
    (3, '2026-09-08', 'completed'),
    (4, '2026-09-04', 'completed'),
    (1, '2026-09-10', 'completed'),
    (2, '2026-09-12', 'pending'),
    (3, '2026-09-15', 'completed');
```

### Задание

1. Получите массив идентификаторов заказов со статусом `completed`.
2. Получите массив идентификаторов клиентов, оформивших эти заказы.
3. Удалите повторяющиеся идентификаторы клиентов.
4. Выведите имена клиентов, используя полученный массив.
5. Подсчитайте количество уникальных клиентов.
6. Найдите клиентов, у которых нет завершённых заказов.

---

## Задание 6. Архивирование товаров по списку

Используйте таблицу `products` из задания 1.

### Подготовка таблицы архива

```sql
CREATE TABLE archived_products (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Задание

Используйте массив идентификаторов:

```sql
product_ids INTEGER[] := ARRAY[3, 6, 9];
```

1. Выведите товары, идентификаторы которых находятся в массиве.
2. Проверьте, какие из указанных товаров существуют.
3. Перенесите найденные товары в `archived_products`.
4. Удалите перенесённые товары из `products`.
5. Выведите количество перенесённых записей.
6. Проверьте, что товары сохранились в архиве.

Перенос и удаление рекомендуется выполнять в одной транзакции, чтобы при ошибке можно было отменить изменения.

---

## Задание 7. Сравнение списка студентов с таблицей

Используйте таблицу `students` из задания 3.

### Задание

Объявите массив имён:

```sql
student_names TEXT[] := ARRAY[
    'Анна Смирнова',
    'Иван Сидоров',
    'Мария Петрова',
    'Николай Васильев'
];
```

1. Найдите студентов из массива, которые существуют в таблице.
2. Определите имена, которых нет в таблице.
3. Получите массив идентификаторов найденных студентов через `ARRAY_AGG`.
4. Используя `FOREACH`, выведите информацию о каждом найденном студенте.
5. Подсчитайте количество найденных и отсутствующих студентов.

