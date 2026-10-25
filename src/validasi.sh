# shellcheck shell=bash
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] [$level] $message"
    echo "$entry"
    if [ -n "$LOG_FILE" ]; then
        echo "$entry" >> "$LOG_FILE"
    fi
}

parse_args() {
    while getopts ":s:d:" opt; do
        case $opt in
            s) SOURCE_DIR="$OPTARG" ;;
            d) DEST_DIR="$OPTARG" ;;
            \?) log "ERROR" "Opsi tidak dikenal: -$OPTARG"; exit 1 ;;
            :)  log "ERROR" "Opsi -$OPTARG butuh argumen"; exit 1 ;;
        esac
    done

    if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
        log "ERROR" "Penggunaan: $0 -s <sumber> -d <tujuan>"
        exit 1
    fi
}

validate_input() {
    if [ ! -d "$SOURCE_DIR" ]; then
        log "ERROR" "Direktori sumber tidak ditemukan: $SOURCE_DIR"
        exit 2
    fi
    if [ ! -r "$SOURCE_DIR" ]; then
        log "ERROR" "Direktori sumber tidak dapat dibaca: $SOURCE_DIR"
        exit 2
    fi
    if [ ! -d "$DEST_DIR" ]; then
        log "ERROR" "Direktori tujuan tidak ditemukan: $DEST_DIR"
        exit 3
    fi
    if [ ! -w "$DEST_DIR" ]; then
        log "ERROR" "Direktori tujuan tidak dapat ditulis: $DEST_DIR"
        exit 3
    fi
}

cleanup() {
    local rc=$?
    if [ "$rc" -ne 0 ] && [ -n "$ARCHIVE_NAME" ] && [ -n "$DEST_DIR" ]; then
        local partial="${DEST_DIR}/${ARCHIVE_NAME}"
        if [ -f "$partial" ]; then
            rm -f "$partial" "${partial}.sha256"
            log "INFO" "Arsip parsial dihapus: $partial"
        fi
    fi
}
