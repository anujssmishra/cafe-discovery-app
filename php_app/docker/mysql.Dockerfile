FROM mysql:8.0
COPY docker/init-test-db.sql /docker-entrypoint-initdb.d/10-test-db.sql
