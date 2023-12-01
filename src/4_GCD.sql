DROP TABLE IF EXISTS nums;
CREATE TABLE IF NOT EXISTS nums(a INT CHECK (a > 0), b INT CHECK(b > 0));

INSERT INTO nums(a, b)
    SELECT floor(random() * 1000) + 1, floor(random() * 1000) + 1
    FROM generate_series(1, 100);

WITH RECURSIVE
    gcd_impl(real_a, real_b, a, b) AS
    (
        SELECT
            a,
            b,
            a,
            b
        FROM nums
        UNION ALL
        SELECT
            real_a,
            real_b,
            b,
            CASE
            WHEN a = b THEN 0
            WHEN a < b THEN a
            ELSE a % b
            END
        FROM gcd_impl
        WHERE b > 0
    ),
    gcd_cte(a, b, gcd) AS
    (
        SELECT real_a, real_b, MIN(a)
        FROM gcd_impl
        GROUP BY real_a, real_b
    )
SELECT
    bool_and(expl.eq) AS all_eq,
    COUNT(*) = 100 AS all_cnt
FROM gcd_cte AS impl
INNER JOIN LATERAL
(
    SELECT
        a,
        b,
        gcd(a, b),
        impl.gcd = gcd(a, b) AS eq
    FROM nums
) AS expl
ON impl.a = expl.a AND impl.b = expl.b;
