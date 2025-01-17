/* Predictive Feature Analysis for Missing Data */

-- Membuat tabel customer
CREATE TABLE public.customer (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(255),
    address VARCHAR(255)
);
INSERT INTO public.customer (id, name, email, phone, address) VALUES
(1, 'Rizaldy Uto', 'uto@example.com', '1234567890', NULL),
(2, 'Caemila', NULL, NULL, NULL),
(3, NULL, 'caem@example.com', '9876543210', 'Elm Street'),
(4, NULL, NULL, NULL, NULL),
(5, 'Johan Chris', 'jo@example.com', '5555555555', 'Pine Street');

--------------------------------------------------------------------
-- Membuat tabel orders
CREATE TABLE public.orders (
    id INT PRIMARY KEY, 
    customer_id INT, 
    order_date DATE, 
    delivery_date DATE, 
    tracking_number VARCHAR(128), 
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);
INSERT INTO public.orders (id, customer_id, order_date, delivery_date, tracking_number) VALUES
(1, 1, '2025-01-01', '2025-01-03', '123-ABC'),
(2, 1, '2025-01-02', NULL, '456-DEF'),
(3, 2, NULL, NULL, NULL),
(4, 3, '2025-01-03', '2025-01-04', NULL),
(5, 4, NULL, NULL, NULL);


---------------------------------------------------------------------
select *
from public.customer

select * 
from public.orders

---------------------------------------------------------------------

WITH cte_main AS (
    SELECT 
        'customer' AS table_name,
        'name' AS column_name,
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE name IS NULL) AS missing_value
    FROM public.customer
    UNION ALL
    SELECT 
        'customer',
        'address',
        COUNT(*),
        COUNT(*) FILTER (WHERE address IS NULL)
    FROM public.customer
    UNION ALL
    SELECT 
        'customer',
        'phone',
        COUNT(*),
        COUNT(*) FILTER (WHERE phone IS NULL)
    FROM public.customer
    UNION ALL
    SELECT 
        'orders',
        'order_date',
        COUNT(*),
        COUNT(*) FILTER (WHERE order_date IS NULL)
    FROM public.orders
    UNION ALL
    SELECT 
        'orders',
        'delivery_date',
        COUNT(*),
        COUNT(*) FILTER (WHERE delivery_date IS NULL)
    FROM public.orders
    UNION ALL
    SELECT 
        'orders',
        'tracking_number',
        COUNT(*),
        COUNT(*) FILTER (WHERE tracking_number IS NULL)
    FROM public.orders
)
SELECT 
    table_name,
    column_name,
    total_rows,
    missing_value,
    ROUND((missing_value::DECIMAL / total_rows) * 100, 2) || '%' AS missing_percentage
FROM cte_main
ORDER BY missing_percentage DESC;



