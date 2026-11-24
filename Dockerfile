# Backend GAV (Spring Boot 4, Java 21) — build multi-etapa.
# Se construye desde la raíz del repo:  docker build -t gav-backend .
# (deploy/docker-compose.yml ya lo hace con context: ..)

# ---------- Etapa 1: compilación ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src

# Primero solo el pom: las dependencias quedan en caché entre builds
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q -DskipTests package

# ---------- Etapa 2: ejecución ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd --system --uid 1001 gav
COPY --from=build /src/target/*.jar /app/app.jar
USER gav

EXPOSE 8080
# Memoria (JAVA_TOOL_OPTIONS), perfil y secretos llegan desde docker-compose / .env
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
