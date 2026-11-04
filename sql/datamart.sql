-- 1. Resumen de Ventas y Ticket Promedio (Serie temporal por Canal y Mes)
CREATE TABLE dm_ventas_resumen AS
SELECT 
    d.year,
    d.month,
    CONCAT(d.year, '-', LPAD(CAST(d.month AS VARCHAR), 2, '0')) AS periodo_str,
    c.name AS channel_name,
    SUM(f.total_amount) AS total_ventas,
    COUNT(f.order_id) AS total_pedidos,
    CASE 
        WHEN COUNT(f.order_id) > 0 THEN SUM(f.total_amount) / COUNT(f.order_id) 
        ELSE 0 
    END AS ticket_promedio
FROM fact_sales f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_channel c ON f.channel_id = c.channel_id
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY d.year, d.month, periodo_str, c.name;

COPY dm_ventas_resumen TO 'dw/dm_ventas_resumen.csv' (FORMAT CSV, HEADER);


-- 2. Usuarios Activos (Por mes y fuente de tráfico)
CREATE TABLE dm_usuarios_activos AS
SELECT 
    d.year,
    d.month,
    CONCAT(d.year, '-', LPAD(CAST(d.month AS VARCHAR), 2, '0')) AS periodo_str,
    COALESCE(s.source, 'direct') AS traffic_source,
    COUNT(DISTINCT ws.customer_id) AS usuarios_activos
FROM fact_web_session ws
JOIN dim_date d ON ws.date_id = d.date_id
LEFT JOIN dim_traffic_source s ON ws.traffic_source_key = s.traffic_source_key
GROUP BY d.year, d.month, periodo_str, traffic_source;

COPY dm_usuarios_activos TO 'dw/dm_usuarios_activos.csv' (FORMAT CSV, HEADER);


-- 3. NPS Mensual por Canal
CREATE TABLE dm_nps_mensual AS
WITH nps_calc AS (
    SELECT 
        d.year,
        d.month,
        CONCAT(d.year, '-', LPAD(CAST(d.month AS VARCHAR), 2, '0')) AS periodo_str,
        c.name AS channel_name,
        CASE WHEN n.score >= 9 THEN 1 ELSE 0 END AS promoter,
        CASE WHEN n.score <= 6 THEN 1 ELSE 0 END AS detractor
    FROM fact_nps n
    JOIN dim_date d ON n.date_id = d.date_id
    JOIN dim_channel c ON n.channel_id = c.channel_id
)
SELECT 
    year,
    month,
    periodo_str,
    channel_name,
    ROUND(
        (SUM(promoter::FLOAT) / COUNT(*) - SUM(detractor::FLOAT) / COUNT(*)) * 100, 
        2
    ) AS nps_score
FROM nps_calc
GROUP BY year, month, periodo_str, channel_name;

COPY dm_nps_mensual TO 'dw/dm_nps_mensual.csv' (FORMAT CSV, HEADER);


-- 4. Ventas por Provincia
CREATE TABLE dm_ventas_provincia AS
SELECT 
    l.province_name,
    SUM(f.total_amount) AS total_ventas
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY l.province_name;

COPY dm_ventas_provincia TO 'dw/dm_ventas_provincia.csv' (FORMAT CSV, HEADER);


-- 5. Ranking Mensual de Ventas por Producto
CREATE TABLE dm_ranking_productos AS
SELECT 
    d.year,
    d.month,
    CONCAT(d.year, '-', LPAD(CAST(d.month AS VARCHAR), 2, '0')) AS periodo_str,
    p.name AS product_name,
    SUM(i.line_total) AS total_ingresos
FROM fact_sales_item i
JOIN fact_sales f ON i.order_id = f.order_id
JOIN dim_product p ON i.product_key = p.product_key
JOIN dim_date d ON f.date_id = d.date_id
WHERE f.status IN ('PAID', 'FULFILLED')
GROUP BY d.year, d.month, periodo_str, p.name;

COPY dm_ranking_productos TO 'dw/dm_ranking_productos.csv' (FORMAT CSV, HEADER);