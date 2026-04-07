* Traefik on `nexus.local` (dashboard)
* Wiki.js on `wiki.nexus.local`
* Postgres internal only
* Dedicated `proxy` network

---

## 1️⃣ SSH into traefik-node and create project folder

```bash
cd /opt
sudo mkdir -p traefik-nexus/traefik
cd traefik-nexus
```

---

## 2️⃣ Create `traefik.yml`

```bash
sudo tee traefik/traefik.yml > /dev/null <<'EOF'
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"

providers:
  docker:
    exposedByDefault: false
  file:
    filename: /etc/traefik/dynamic.yml
EOF
```

---

## 3️⃣ Create `dynamic.yml` (empty for now, optional middlewares)

```bash
sudo tee traefik/dynamic.yml > /dev/null <<'EOF'
http:
  middlewares:
    # Example middleware (not used yet)
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true
EOF
```

---

## 4️⃣ Create `docker-compose.yml`

```bash
sudo tee docker-compose.yml > /dev/null <<'EOF'
version: '3.9'

services:
  traefik:
    image: traefik:v3.1
    container_name: traefik
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --api.dashboard=true
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro
    networks:
      - proxy
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: wiki
      POSTGRES_PASSWORD: wikijsrocks
      POSTGRES_USER: wikijs
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - proxy
    restart: unless-stopped

  wiki:
    image: requarks/wiki:2
    depends_on:
      - db
    environment:
      DB_TYPE: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: wikijs
      DB_PASS: wikijsrocks
      DB_NAME: wiki
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.wiki.rule=Host(`wiki.nexus.local`)"
      - "traefik.http.routers.wiki.entrypoints=web"
      - "traefik.http.services.wiki.loadbalancer.server.port=3000"
    networks:
      - proxy
    restart: unless-stopped

volumes:
  db-data:

networks:
  proxy:
    driver: bridge
EOF
```

---

## 5️⃣ Set permissions (optional, just to be safe)

```bash
sudo chown -R $USER:$USER /opt/traefik-nexus
```

---

## 6️⃣ Update your `/etc/hosts` on your **local machine**

```
192.168.0.237 nexus.local
192.168.0.237 wiki.nexus.local
```

---

## 7️⃣ Start Docker Compose

```bash
cd /opt/traefik-nexus
sudo docker compose up -d
```

---

## 8️⃣ Test

* [http://nexus.local:8080](http://nexus.local:8080) → Traefik dashboard
* [http://wiki.nexus.local](http://wiki.nexus.local) → Wiki.js

---

