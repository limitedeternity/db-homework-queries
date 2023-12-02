CREATE TABLE IF NOT EXISTS staff(emp_id INT PRIMARY KEY, reports_to INT REFERENCES staff(emp_id));

INSERT INTO staff (emp_id, reports_to) VALUES (1, NULL)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

INSERT INTO staff (emp_id, reports_to) VALUES (3, 1)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

INSERT INTO staff (emp_id, reports_to) VALUES (2, 3)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

INSERT INTO staff (emp_id, reports_to) VALUES (4, 2)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

INSERT INTO staff (emp_id, reports_to) VALUES (6, 4)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

INSERT INTO staff (emp_id, reports_to) VALUES (7, 6)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

INSERT INTO staff (emp_id, reports_to) VALUES (5, 7)
ON CONFLICT (emp_id) DO UPDATE SET reports_to = EXCLUDED.reports_to;

UPDATE staff SET reports_to = 5 WHERE emp_id = 6;

WITH RECURSIVE hierarchy AS
(
    SELECT emp_id, 0 AS level
    FROM staff
    WHERE reports_to IS NULL
    UNION ALL
    SELECT staff.emp_id, hierarchy.level + 1
    FROM hierarchy
    JOIN staff
    ON hierarchy.emp_id = staff.reports_to
)
CYCLE emp_id SET is_cycle USING path
SELECT emp_id, level
FROM hierarchy
WHERE NOT is_cycle
UNION ALL
SELECT emp_id, -1 AS level
FROM staff
WHERE emp_id NOT IN
(
    SELECT emp_id
    FROM hierarchy
    WHERE NOT is_cycle
)
ORDER BY level, emp_id;
