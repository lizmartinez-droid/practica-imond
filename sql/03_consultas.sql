-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================
-- Cada SELECT de este archivo se muestra en la terminal al ejecutar
-- run_sql.py. Usalo para:
--   * comprobar que las tablas se cargaron bien (cantidad de filas, nulos...)
--   * escribir las consultas clave de los KPIs que pide la consigna
--     (ventas, usuarios activos, ticket promedio, NPS, ventas por provincia,
--     ranking mensual por producto) usando las tablas del modelo estrella.
-- =====================================================================


-- Ejemplo: revisar la dimensión producto
SELECT product_key, name, category, family, list_price
FROM dim_product
ORDER BY product_key;


-- TU TURNO: agregá acá tus consultas.
SELECT 
    SUM(total_amount) AS total_ventas,
    AVG(total_amount) AS ticket_promedio
FROM sales_order
WHERE status IN ('PAID', 'FULFILLED');

SELECT 
    COUNT(DISTINCT customer_id) AS usuarios_registrados_activos,
    COUNT(DISTINCT session_id) AS total_sesiones_web
FROM web_session;

WITH nps_calc AS (
    SELECT 
        CASE 
            WHEN score >= 9 THEN 1 
            WHEN score <= 6 THEN -1 
            ELSE 0 
        END AS nps_category
    FROM nps_response
)
SELECT 
    (SUM(nps_category) * 100.0) / COUNT(*) AS nps_score
FROM nps_calc;

SELECT 
    DATE_TRUNC('month', so.order_date) AS mes,
    pr.name AS producto,
    SUM(oi.line_total) AS total_venta_producto
FROM sales_order_item oi
JOIN sales_order so ON oi.order_id = so.order_id
JOIN product pr ON oi.product_id = pr.product_id
GROUP BY 1, 2
ORDER BY mes DESC, total_venta_producto DESC;