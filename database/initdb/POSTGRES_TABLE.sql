/*
CREATE TABLE POSTGRES_TABLE_OLD AS
01-init-table-users-sequence
*/

drop table if EXISTS POSTGRES_TABLE;
drop sequence if exists PUT_POSTGRES_TABLE_SEQ; 
drop sequence if exists GET_POSTGRES_TABLE_SEQ; 


CREATE TABLE POSTGRES_TABLE (
    RLO          numeric(9),
    USERNAME     varchar(25),
    PASSWORD     varchar(25) DEFAULT NULL,
    EMAIL        varchar(50) DEFAULT NULL,  
    CREATED_AT   timestamp DEFAULT CURRENT_TIMESTAMP,
    REMARKS      varchar(255) DEFAULT NULL
);


CREATE UNIQUE INDEX POSTGRES_TABLE_PK2 ON POSTGRES_TABLE (RLO);
CREATE INDEX POSTGRES_TABLE_3UQ ON POSTGRES_TABLE (USERNAME, RLO);


CREATE SEQUENCE put_postgres_table_seq START WITH 1;
CREATE SEQUENCE get_postgres_table_seq START WITH 1;

-- 5. Вставляем начальные данные
INSERT INTO POSTGRES_TABLE (RLO, USERNAME, PASSWORD, EMAIL, REMARKS) VALUES
    (1, 'admin', 'admin123', 'admin@example.com', 'System administrator'),
    (2, 'john_doe', 'pass123', 'john@example.com', 'Regular user'),
    (3, 'jane_smith', 'jane456', 'jane@example.com', 'Power user');


DO $$
DECLARE
    max_id BIGINT;
BEGIN

    SELECT COALESCE(MAX(RLO), 0)::BIGINT INTO max_id FROM POSTGRES_TABLE;

    IF max_id > 0 THEN

        PERFORM setval('put_postgres_table_seq', max_id, true);
    ELSE
        PERFORM setval('put_postgres_table_seq', 1, false);
    END IF;
    
    RAISE NOTICE 'Sequence put_postgres_table_seq synchronized at %', max_id;
END $$;