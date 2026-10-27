# Etapa 1: Build da aplicacao com Maven e Eclipse Temurin JDK 21
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Copia dependencias do wrapper Maven primeiro para aproveitar cache de camadas Docker
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw

# Baixa dependencias do Maven em cache
RUN ./mvnw dependency:go-offline -B || true

# Copia o codigo-fonte e compila o pacote JAR
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# Etapa 2: Imagem final leve para execucao (JRE 21 Alpine)
FROM eclipse-temurin:21-jre-alpine AS runner

WORKDIR /app

# Cria usuario sem privilegios de root para seguranca
RUN addgroup -S memora && adduser -S memora -G memora

# Copia artefato gerado na etapa de build
COPY --from=builder /build/target/memora-0.0.1-SNAPSHOT.jar /app/app.jar
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && chmod +x /app/docker-entrypoint.sh

USER memora

EXPOSE 8080

ENTRYPOINT ["/app/docker-entrypoint.sh"]

