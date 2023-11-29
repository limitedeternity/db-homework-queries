SELECT
    q1.vendorid,
    q1.avg_trip_duration,
    q2.fare_variance,
    q3.rides_from_6am_to_6pm,
    COALESCE(q4.new_year_rides, 0),
    q5.max_fare_per_passenger
FROM
(
    SELECT
        vendorid,
        make_interval(
            secs => CEIL(
                AVG(
                    EXTRACT(EPOCH FROM tpep_dropoff_datetime - tpep_pickup_datetime)
                )
            )
        ) AS avg_trip_duration
    FROM dataset
    GROUP BY vendorid
) AS q1

FULL JOIN (
    SELECT
        vendorid,
        var_samp(fare_amount) AS fare_variance
    FROM dataset
    GROUP BY vendorid
) AS q2
ON q1.vendorid = q2.vendorid

FULL JOIN (
    SELECT
        vendorid,
        COUNT(*) AS rides_from_6am_to_6pm
    FROM dataset
    WHERE EXTRACT(HOUR FROM tpep_pickup_datetime) BETWEEN 6 AND 17
    GROUP BY vendorid
) AS q3
ON q1.vendorid = q3.vendorid

FULL JOIN (
    SELECT
        vendorid,
        COUNT(*) as new_year_rides
    FROM dataset
    WHERE EXTRACT(YEAR FROM tpep_pickup_datetime) < EXTRACT(YEAR FROM tpep_dropoff_datetime)
    GROUP BY vendorid
) AS q4
ON q1.vendorid = q4.vendorid

FULL JOIN (
    SELECT
        vendorid,
        MAX(fare_amount / passenger_count) AS max_fare_per_passenger
    FROM dataset
    WHERE passenger_count > 0
    GROUP BY vendorid
) AS q5
ON q1.vendorid = q5.vendorid;
