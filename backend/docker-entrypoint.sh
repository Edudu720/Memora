#!/bin/sh
set -e

# Se DATABASE_URL estiver presente (padrao fornecido pelo Render / Neon / Supabase),
# normaliza para os parametros JDBC aceitos pelo Spring Boot
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

