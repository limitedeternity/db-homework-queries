CREATE OR REPLACE FUNCTION fmt_percent(
    num double precision
)
    RETURNS text
    LANGUAGE sql
AS
$$
    SELECT TO_CHAR(num * 100, 'fm990D00%');
$$;

WITH cte AS (
    SELECT
        row_number() OVER () AS sid,
        (tip_amount / nullif(total_amount, 0)::float) AS tip_share,
        date_trunc('day', tpep_pickup_datetime) AS tpep_pickup_date,
        *
    FROM dataset
)
SELECT
    q1.tip_share_percent,
    q2.total_avg_tip_diff,
    q3.vendor_avg_tip_diff,
    q5.speed_rank
FROM
(
    SELECT
        sid,
        fmt_percent(tip_share) AS tip_share_percent
    FROM cte
) AS q1

FULL JOIN (
    SELECT
        sid,
        fmt_percent((tip_share - AVG(tip_share) OVER ()) / AVG(tip_share) OVER ())
        AS total_avg_tip_diff
    FROM cte
) AS q2
ON q1.sid = q2.sid

FULL JOIN (
    SELECT
        tbl.sid,
        fmt_percent((tbl.tip_share - qry.avg_tip_share) / qry.avg_tip_share)
        AS vendor_avg_tip_diff
    FROM cte AS tbl
    LEFT JOIN (
        SELECT
            vendorid,
            AVG(tip_share) AS avg_tip_share
        FROM cte
        GROUP BY vendorid
    ) AS qry
    ON tbl.vendorid = qry.vendorid
) AS q3
ON q1.sid = q3.sid

FULL JOIN (
    SELECT
        tbl.sid,
        RANK()
        OVER (
            PARTITION BY vendorid
            ORDER BY trip_distance /
                EXTRACT(EPOCH FROM tpep_dropoff_datetime - tpep_pickup_datetime)
            DESC)
        AS speed_rank
    FROM cte AS tbl
    WHERE tpep_dropoff_datetime > tpep_pickup_datetime
) AS q5
ON q1.sid = q5.sid;

/* */

WITH cte AS (
    SELECT
        row_number() OVER () AS sid,
        (tip_amount / nullif(total_amount, 0)::float) AS tip_share,
        date_trunc('day', tpep_pickup_datetime) AS tpep_pickup_date,
        *
    FROM dataset
)
SELECT
    sid,
    tip_share,
    AVG(tip_share) OVER w AS avg_tip_share,
    tip_share - AVG(tip_share) OVER w AS difference
FROM cte
WINDOW w AS (
    PARTITION BY tpep_pickup_date
    ORDER BY trip_distance ASC
    ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
)
