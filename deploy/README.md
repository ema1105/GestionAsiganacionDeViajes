# GAV — Despliegue

Todo lo necesario para correr GAV con Docker: en el portátil (prueba) y en la VM de Azure (nube).
Guía completa paso a paso: documento "GAV — Guía de despliegue en Azure".

```
gav/                              (este repo)
├── Dockerfile                    backend Spring Boot (Java 21)
├── .dockerignore
├── src/main/resources/application-prod.properties   perfil de producción (sin secretos)
├── prediction-service/
│   ├── Dockerfile                FastAPI + TensorFlow
│   └── artefactos/               modelo RNA entrenado (ahora se versiona)
└── deploy/
    ├── docker-compose.yml        nube: backend + prediction + caddy (HTTPS)
    ├── docker-compose.local.yml  portátil: + MySQL en contenedor, sin HTTPS
    ├── Caddyfile                 HTTPS automático + Flutter Web + proxy a la API
    ├── .env.example              variables (copiar a .env; .env no se sube a Git)
    ├── web/                      aquí va el build de Flutter Web
    └── scripts/
        ├── azure-crear-infraestructura.sh   crea los recursos en Azure (Cloud Shell)
        ├── deploy.sh                        git pull + rebuild en el servidor
        └── db-tunnel.sh                     túnel SSH al MySQL privado
```

## 1. Prueba local (Docker Desktop en Windows)

```powershell
cd deploy
docker compose -f docker-compose.local.yml up -d --build    # 1ª vez: 10-15 min
docker compose -f docker-compose.local.yml ps
```

- API: http://localhost:8080/swagger-ui.html  (usuario `admin` / `admin123` lo crea AdminSeeder)
- Predicción: http://localhost:8000/api/prediccion/salud  y  http://localhost:8000/docs
- MySQL del contenedor: 127.0.0.1:3308, `gav_admin` / `gavlocal123`

Para la app móvil contra este backend local (celular en la misma red Wi-Fi o hotspot del portátil):
`flutter run --dart-define-from-file=env/dev.json` cambiando las URLs por `http://<IP-del-portátil>:8080` y `:8000`.

## 2. Azure

1. Cloud Shell: `bash azure-crear-infraestructura.sh` (crea VM + MySQL). Descargar la llave y el resumen.
2. DuckDNS: `gav-app` y `gav-pred` -> IP de la VM.
3. En la VM:
   ```bash
   git clone https://github.com/ema1105/GestionAsiganacionDeViajes.git gav
   cd gav/deploy && cp .env.example .env && nano .env
   docker compose up -d --build
   ```
4. Flutter Web (opcional, la "página" pública):
   ```powershell
   # en el PC, carpeta front-flt
   flutter build web --release --dart-define-from-file=env/prod.json
   scp -i gav-azure-key -r build/web/* azureuser@<IP_VM>:~/gav/deploy/web/
   ```
   Queda en https://gav-app.duckdns.org. Agreguen ese dominio a las restricciones de la API key de Google Maps.
5. Actualizar después de un push: `bash deploy/scripts/deploy.sh`

## 3. APK

```powershell
# carpeta front-flt
flutter build apk --release --dart-define-from-file=env/prod.json   # nube (con respaldo demo)
flutter build apk --release --dart-define-from-file=env/demo.json   # predicción siempre desde assets/demo
```

El modo demo cubre solo la predicción (FastAPI). Login, viajes y flota siguen necesitando el backend:
en la nube, o en el portátil con `docker-compose.local.yml` (Plan C).

## Seguridad

`src/main/resources/application.properties` y `application-dev.properties` tienen versionados la clave de
MySQL local y el `jwt.secret` de desarrollo. En producción NO se usan (el perfil `prod` los toma del `.env`),
pero conviene sacarlos del repo y usar un `JWT_SECRET` nuevo: `openssl rand -base64 48`.
