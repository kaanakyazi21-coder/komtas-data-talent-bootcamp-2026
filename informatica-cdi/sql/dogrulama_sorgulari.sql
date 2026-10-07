-- 1) Kontrol tablosunun son hali
SELECT time_id, table_name, load_status, insert_date, update_date
FROM table_load_status
ORDER BY 1;

-- 2) CDI çıktısının dönem bazında statü dağılımı
SELECT time_id,
       SUM(cnt)                                                    AS total,
       LISTAGG(status || cnt, ' ') WITHIN GROUP (ORDER BY status)  AS note
FROM (
    SELECT time_id, status, COUNT(*) AS cnt
    FROM f_customer_status
    GROUP BY time_id, status
)
GROUP BY time_id
ORDER BY 1;

-- 3) Tekrar çalıştırılabilirlik: mükerrer kayıt yok, INSERT_DATE korunuyor, UPDATE_DATE ilerliyor
SELECT time_id,
       COUNT(*)                                          AS n,
       COUNT(DISTINCT cust_id)                           AS d,
       TO_CHAR(MIN(insert_date), 'DD.MM HH24:MI:SS')     AS min_ins,
       TO_CHAR(MAX(insert_date), 'DD.MM HH24:MI:SS')     AS max_ins,
       TO_CHAR(MAX(update_date), 'DD.MM HH24:MI:SS')     AS max_upd
FROM f_customer_status
GROUP BY time_id
ORDER BY 1;

-- Ortamı sıfırlama
-- TRUNCATE TABLE f_customer_status;
-- TRUNCATE TABLE wrk_run_log;
-- UPDATE table_load_status SET load_status = 'READY', update_date = SYSDATE;
-- COMMIT;
