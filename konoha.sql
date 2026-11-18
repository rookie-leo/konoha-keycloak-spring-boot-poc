-- Executado pelo psql. As credenciais deste arquivo sao para a PoC local.
SELECT 'CREATE ROLE rhbk_app LOGIN PASSWORD ''rhbk-local'''
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rhbk_app')
\gexec

GRANT CONNECT ON DATABASE rhbk TO rhbk_app;
GRANT USAGE, CREATE ON SCHEMA public TO rhbk_app;

SELECT 'CREATE DATABASE academia_ninja'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'academia_ninja')
\gexec
\connect academia_ninja

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

SELECT 'CREATE ROLE academia_leitor LOGIN PASSWORD ''academia-local'''
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'academia_leitor')
\gexec

CREATE TABLE IF NOT EXISTS ninja (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    patente text NOT NULL CHECK (patente IN ('genin', 'chunin', 'jonin', 'hokage'))
);

INSERT INTO ninja (username, password_hash, patente)
SELECT inicial.username, crypt('konoha-local', gen_salt('bf', 10)), inicial.patente
FROM (VALUES
    ('konohamaru.sarutobi', 'genin'),
    ('sakura.haruno',       'chunin'),
    ('kakashi.hatake',      'jonin'),
    ('tsunade',             'hokage')
) AS inicial(username, patente)
ON CONFLICT (username) DO NOTHING;

GRANT CONNECT ON DATABASE academia_ninja TO academia_leitor;
GRANT USAGE ON SCHEMA public TO academia_leitor;
GRANT SELECT ON ninja TO academia_leitor;
COMMIT;
 