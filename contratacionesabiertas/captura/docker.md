# Docker

La aplicación puede ser ejecutada utilizando contenedores docker, de la siguiente forma.

### Crear imagen:
`docker build -t mxabierto/edca .`

### Ejecutar dependencias:
`docker run -d --name mongodb mxabierto/mongodb-min`

`docker run -d --name postgres -e POSTGRES_PASSWORD=secretpassword postgres`

### Ejecutar aplicación:
```
docker run \
--link mongodb-container:mongodb \
--link postgres-container:postgres \
--name edca \
-dP mxabierto/edca
```

### Crear schema:
```
docker run -it --rm -v `pwd`/sql:/sql --link postgres:postgres postgres /bin/bash
psql -h postgres -U postgres < /sql/edca.sql
```

### Ejecutar comandos:
`docker exec -it edca useradm add USERNAME`
