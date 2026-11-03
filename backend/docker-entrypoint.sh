#!/bin/sh
set -e

# Se DATABASE_URL estiver presente (padrao fornecido pelo Render / Neon / Supabase),
# normaliza para os parametros JDBC aceitos pelo Spring Boot.
# postgresql://u:p@host/banco?sslmode=require -> jdbc:postgresql://host/banco?sslmode=require
# Parametros da consulta passam intactos. O "channel_binding=require" que o Neon
# acrescenta as vezes e ignorado pelo pgjdbc 42.7 (medido: a conexao abre igual),
# entao nao precisa ser removido.
if [ -n "$DATABASE_URL" ]; then
    CLEAN_URL=$(echo "$DATABASE_URL" | sed -E 's/^postgres(ql)?:\/\///')
    if echo "$CLEAN_URL" | grep -q "@"; then
        USER_PASS=$(echo "$CLEAN_URL" | cut -d'@' -f1)
        HOST_PORT_DB=$(echo "$CLEAN_URL" | cut -d'@' -f2)
        DB_USER=$(echo "$USER_PASS" | cut -d':' -f1)
        DB_PASS=$(echo "$USER_PASS" | cut -d':' -f2-)
        
        export MEMORA_DB_USUARIO="${MEMORA_DB_USUARIO:-$DB_USER}"
        export MEMORA_DB_SENHA="${MEMORA_DB_SENHA:-$DB_PASS}"
        export MEMORA_DB_URL="${MEMORA_DB_URL:-jdbc:postgresql://$HOST_PORT_DB}"
    fi
fi

# Ajustes de memoria para container (adequado para o plano gratuito ou starter do Render)
JAVA_OPTS="${JAVA_OPTS:--XX:+UseG1GC -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError}"

exec java $JAVA_OPTS -jar /app/app.jar "$@"

