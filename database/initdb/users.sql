INSERT INTO POSTGRES_TABLE (RLO, USERNAME, PASSWORD, EMAIL, REMARKS) VALUES
    ('1', 'admin', 'admin123', 'admin@example.com', 'System administrator'),
    ('2', 'john_doe', 'pass123', 'john@example.com', 'Regular user'),
    ('3', 'jane_smith', 'jane456', 'jane@example.com', 'Power user')
ON CONFLICT (RLO) DO NOTHING;

DO $$
DECLARE
    row_cnt BIGINT;
    PUT_SeqName TEXT := 'PUT_POSTGRES_TABLE_SEQ';
BEGIN

    EXECUTE 'SELECT count(*) FROM POSTGRES_TABLE' INTO row_cnt;

    row_cnt := row_cnt + 1;

    EXECUTE 'DROP SEQUENCE IF EXISTS ' || quote_ident(PUT_SeqName); 

    EXECUTE 'CREATE SEQUENCE ' || quote_ident(PUT_SeqName) || 
            ' START WITH ' || row_cnt || 
            ' MINVALUE 1 MAXVALUE 1000000000000000 INCREMENT BY 1 NO CACHE NO CYCLE';
            
    RAISE NOTICE 'Sequence % created starting with %', PUT_SeqName, row_cnt;
END $$;