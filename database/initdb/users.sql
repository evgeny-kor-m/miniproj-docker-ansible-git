INSERT INTO POSTGRES_TABLE (RLO, USERNAME, PASSWORD, EMAIL, REMARKS) VALUES
    ('1', 'admin', 'admin123', 'admin@example.com', 'System administrator'),
    ('2', 'john_doe', 'pass123', 'john@example.com', 'Regular user'),
    ('3', 'jane_smith', 'jane456', 'jane@example.com', 'Power user')
ON CONFLICT (RLO) DO NOTHING;

DO $$
DECLARE
    row_cnt BIGINT;
    seq_name TEXT := 'put_postgres_table_seq';
    table_name TEXT := 'postgres_table';
BEGIN

    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = lower(table_name)) THEN
        RAISE EXCEPTION 'Table % not found!', table_name;
    END IF;

    EXECUTE format('SELECT COALESCE(MAX(RLO), 0) FROM %I', table_name) INTO row_cnt;

    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I', seq_name);

    IF row_cnt = 0 THEN
        PERFORM setval(seq_name, 1, false);
    ELSE
        PERFORM setval(seq_name, row_cnt, true);
    END IF;

    RAISE NOTICE 'Sequence % sync. Current max RLO in table: %. next value: %', 
                 seq_name, row_cnt, (CASE WHEN row_cnt = 0 THEN 1 ELSE row_cnt + 1 END);
END $$;