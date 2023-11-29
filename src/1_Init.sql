CREATE EXTENSION IF NOT EXISTS hstore;

CREATE OR REPLACE FUNCTION load_dataset(
    target_table text,
    csv_file_path text,
    col_type_map hstore
)
    RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    iter integer;
    col text;
    col_first text;
    col_type record;

BEGIN
    CREATE TABLE temp_table ();

    FOR iter IN 1..array_length(akeys(col_type_map), 1)
    loop
        EXECUTE format('ALTER TABLE temp_table ADD COLUMN col_%s text', iter);
    END loop;

    EXECUTE format('COPY temp_table FROM %L WITH DELIMITER '','' QUOTE ''"'' CSV', csv_file_path);

    iter := 1;
    col_first := (SELECT col_1 FROM temp_table LIMIT 1);

    FOR col IN EXECUTE format('SELECT unnest(string_to_array(trim(temp_table::text, ''()''), '','')) FROM temp_table WHERE col_1 = %L', col_first)
    loop
        EXECUTE format('ALTER TABLE temp_table RENAME COLUMN col_%s TO %s', iter, col);
        iter := iter + 1;
    END loop;

    EXECUTE format('DELETE FROM temp_table WHERE %s = %L', col_first, col_first);

    FOR col_type IN SELECT (each(col_type_map)).*
    loop
        EXECUTE format('ALTER TABLE temp_table ALTER COLUMN %1$I TYPE %2$s USING %1$I::%2$s', col_type.key, col_type.value);
    END loop;

    EXECUTE format('ALTER TABLE temp_table RENAME TO %I', target_table);
END;
$$;

SELECT load_dataset(
    'dataset',
    '/mnt/datasets/2018_Yellow_Taxi_Trip_Data_20231108.csv',
    hstore(ARRAY[
        ['vendorid', 'integer'],
        ['tpep_pickup_datetime', 'timestamp'],
        ['tpep_dropoff_datetime', 'timestamp'],
        ['passenger_count', 'integer'],
        ['trip_distance', 'double precision'],
        ['ratecodeid', 'integer'],
        ['store_and_fwd_flag', 'varchar(1)'],
        ['pulocationid', 'integer'],
        ['dolocationid', 'integer'],
        ['payment_type', 'integer'],
        ['fare_amount', 'double precision'],
        ['extra', 'double precision'],
        ['mta_tax', 'double precision'],
        ['tip_amount', 'double precision'],
        ['tolls_amount', 'double precision'],
        ['improvement_surcharge', 'double precision'],
        ['total_amount', 'double precision']
    ])
);
