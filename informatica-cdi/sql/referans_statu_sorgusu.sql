-- Referans çözüm: CDI akışıyla aynı statü mantığını doğrudan Oracle SQL ile hesaplar.
-- Üç dönem için dönem bazında statü dağılımını döndürür.

WITH p AS (
    SELECT DATE '2022-10-31' AS ref_date FROM dual
    UNION ALL SELECT DATE '2022-11-30' FROM dual
    UNION ALL SELECT DATE '2022-12-31' FROM dual
),
-- Müşteri x satış ayı (tekilleştirilmiş) ve referans aya uzaklık
m AS (
    SELECT DISTINCT
           s.cust_id,
           p.ref_date,
           MONTHS_BETWEEN(TRUNC(p.ref_date, 'MM'), TRUNC(s.time_id, 'MM')) AS diff
    FROM sales s
    JOIN p
      ON s.time_id >= ADD_MONTHS(TRUNC(p.ref_date, 'MM'), -11)
     AND s.time_id <  ADD_MONTHS(TRUNC(p.ref_date, 'MM'), 1)
),
-- Pencere bazında farklı ay sayıları
f AS (
    SELECT cust_id,
           ref_date,
           SUM(CASE WHEN diff BETWEEN 0 AND 2  THEN 1 ELSE 0 END) AS w1,
           SUM(CASE WHEN diff BETWEEN 3 AND 5  THEN 1 ELSE 0 END) AS w2,
           SUM(CASE WHEN diff BETWEEN 6 AND 11 THEN 1 ELSE 0 END) AS w3
    FROM m
    GROUP BY cust_id, ref_date
),
-- Müşteri evreni CUSTOMERS'tan; öncelik sırasına göre statü
r AS (
    SELECT p.ref_date,
           CASE
               WHEN NVL(f.w1, 0) >= 2                                              THEN 'S'
               WHEN NVL(f.w1, 0) >= 1 AND NVL(f.w2, 0) = 0 AND NVL(f.w3, 0) >= 1   THEN 'YA'
               WHEN NVL(f.w1, 0) >= 1                                              THEN 'A'
               WHEN NVL(f.w2, 0) + NVL(f.w3, 0) >= 1                               THEN 'P'
               ELSE 'H'
           END AS status
    FROM p
    CROSS JOIN customers c
    LEFT JOIN f
      ON f.cust_id = c.cust_id
     AND f.ref_date = p.ref_date
)
SELECT ref_date                                                         AS time_id,
       SUM(cnt)                                                         AS total,
       LISTAGG(status || '=' || cnt, ', ') WITHIN GROUP (ORDER BY status) AS note
FROM (
    SELECT ref_date, status, COUNT(*) AS cnt
    FROM r
    GROUP BY ref_date, status
)
GROUP BY ref_date
ORDER BY 1;
