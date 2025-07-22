```
sudo wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/16/mysql-tomcat/mysql/init.sql
```

```
version: '3'
networks:
  bridge:
    driver: bridge
services:
  web:
    image: "xwiki:stable-mysql-tomcat"
    container_name: xwiki-mysql-tomcat-web
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_HOST=xwiki-mysql-db
    volumes:
      - /opt/xwiki/xwiki-data:/usr/local/xwiki
    networks:
      - bridge
  db:
    image: "mysql:8.2"
    container_name: xwiki-mysql-db
    volumes:
      - /opt/xwiki/mysql-data:/var/lib/mysql
      - /opt/xwiki/init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
    command:
      - "--character-set-server=utf8mb4"
      - "--collation-server=utf8mb4_bin"
      - "--explicit-defaults-for-timestamp=1"
    networks:
      - bridge
volumes:
  mysql-data: {}
  xwiki-data: {}
```
