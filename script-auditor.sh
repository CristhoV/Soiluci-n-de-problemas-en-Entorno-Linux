#!/bin/bash

# Nombre del log con timestamp
LOG_FILE="auditoria_log_$(date +%Y%m%d_%H%M%S).log"

# Carpeta de archivos temporales REAL
TEMP_DIR="/tmp"

# Lista de servicios simulados (puedes ajustar esto según tus necesidades)
SERVICIOS_SIMULADOS=("cron" "ssh" "dbus")

# Lista de usuarios a verificar
USUARIOS=("cristho" "usuario_simulado_1" "usuario_simulado_2")

echo "==== INICIO DE AUDITORÍA: $(date) ====" | tee -a "$LOG_FILE"

# 1. Revisar espacio en disco
echo "-> Espacio en disco:" | tee -a "$LOG_FILE"
df -h | tee -a "$LOG_FILE"

# 2. Buscar y eliminar archivos temporales (accedidos hace más de 2 días)
if [ -d "$TEMP_DIR" ]; then
    echo "-> Eliminando archivos antiguos en $TEMP_DIR" | tee -a "$LOG_FILE"
    find "$TEMP_DIR" -type f -atime +2 -exec rm -v {} \; 2>>"$LOG_FILE" | tee -a "$LOG_FILE"
else
    echo "-> Carpeta $TEMP_DIR no existe (lo cual sería inusual)." | tee -a "$LOG_FILE"
fi

# 3. Verificar permisos de archivos importantes en /etc y en /home/usuarios
echo "-> Verificando permisos de archivos del sistema:" | tee -a "$LOG_FILE"
ARCHIVOS_SISTEMA=("/etc/passwd" "/etc/shadow")

for archivo in "${ARCHIVOS_SISTEMA[@]}"; do
    if [ -e "$archivo" ]; then
        permisos=$(stat -c "%a" "$archivo")
        propietario=$(stat -c "%U:%G" "$archivo")
        echo "Archivo: $archivo | Permisos: $permisos | Propietario: $propietario" | tee -a "$LOG_FILE"
        if [[ $permisos -gt 644 ]]; then
            echo "   >> SUGERENCIA: Revisar permisos de $archivo (actual: $permisos)" | tee -a "$LOG_FILE"
        fi
    else
        echo "   >> $archivo no encontrado." | tee -a "$LOG_FILE"
    fi
done

echo "-> Verificando permisos de archivos de usuarios:" | tee -a "$LOG_FILE"
for usuario in "${USUARIOS[@]}"; do
    USER_HOME="/home/$usuario"
    ARCHIVOS_USUARIO=(".bashrc" ".profile" ".bash_profile")
    
    for archivo in "${ARCHIVOS_USUARIO[@]}"; do
        FULL_PATH="$USER_HOME/$archivo"
        if [ -e "$FULL_PATH" ]; then
            permisos=$(stat -c "%a" "$FULL_PATH")
            propietario=$(stat -c "%U:%G" "$FULL_PATH")
            echo "Archivo: $FULL_PATH | Permisos: $permisos | Propietario: $propietario" | tee -a "$LOG_FILE"
            if [[ $permisos -gt 644 ]]; then
                echo "   >> SUGERENCIA: Revisar permisos de $FULL_PATH (actual: $permisos)" | tee -a "$LOG_FILE"
            fi
        else
            echo "   >> $FULL_PATH no encontrado." | tee -a "$LOG_FILE"
        fi
    done
done

# 4. Simular verificación de estado de servicios (usando pgrep como alternativa)
echo "-> Simulando estado de servicios (usando pgrep como alternativa):" | tee -a "$LOG_FILE"
for servicio in "${SERVICIOS_SIMULADOS[@]}"; do
    if pgrep "$servicio" > /dev/null; then
        echo "   $servicio está activo." | tee -a "$LOG_FILE"
    else
        echo "   >> $servicio está INACTIVO. Debería iniciarse automáticamente." | tee -a "$LOG_FILE"
    fi
done

echo "==== FIN DE AUDITORÍA: $(date) ====" | tee -a "$LOG_FILE"
