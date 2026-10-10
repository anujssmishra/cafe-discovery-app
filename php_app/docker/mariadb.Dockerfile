FROM mariadb:10.11
COPY docker/init-test-db.sql /docker-entrypoint-initdb.d/10-test-db.sql
