#!/bin/bash
# ==============================================================================
# Script Name : backup.sh
# Deskripsi   : Modul otomatisasi backup direktori dengan kompresi tar.gz dan SHA256
# Penulis     : Kelompok 4 (Bagian A: Galang Putra Pratama)
# Checkpoint  : P2-CHECKPOINT-P11-v01
# ==============================================================================
# Exit Codes:
#   0 - Berhasil
#   1 - Argumen salah / tidak lengkap
#   2 - Direktori sumber bermasalah (tidak ada / tidak terbaca)
#   3 - Direktori tujuan bermasalah (tidak ada / tidak writable)
#   4 - Proses kompresi tar gagal
# ==============================================================================

set -o pipefail

# --- Variabel Global ---
SOURCE_DIR=""
DEST_DIR=""
LOG_FILE=""
ARCHIVE_NAME=""
ARCHIVE_PATH=""

# ==============================================================================
# STUB SEMENTARA (Akan digantikan oleh modul Bagian B - Rania)
# ==============================================================================
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    echo "$log_entry"
    if [ -n "$LOG_FILE" ]; then
        echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

parse_args() {
    while getopts ":s:d:h" opt; do
        case $opt in
            s) SOURCE_DIR="$OPTARG" ;;
            d) DEST_DIR="$OPTARG" ;;
            h)
                echo "Penggunaan: $0 -s <direktori_sumber> -d <direktori_tujuan>"
                exit 0
                ;;
            \?) log "ERROR" "Opsi tidak valid: -$OPTARG"; exit 1 ;;
            :)  log "ERROR" "Opsi -$OPTARG memerlukan argumen"; exit 1 ;;
        esac
    done

    if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
        log "ERROR" "Argumen wajib kurang. Gunakan: $0 -s <sumber> -d <tujuan>"
        exit 1
    fi
}

validate_input() {
    # Stub validasi dasar sebelum integrasi penuh modul B
    if [ ! -d "$SOURCE_DIR" ]; then
        log "ERROR" "Direktori sumber tidak ditemukan: $SOURCE_DIR"
        exit 2
    fi
    if [ ! -d "$DEST_DIR" ]; then
        log "ERROR" "Direktori tujuan tidak ditemukan: $DEST_DIR"
        exit 3
    fi
}

cleanup() {
    # ponytail: pembersihan parsial saat sinyal interupsi diterima
    if [ -n "$ARCHIVE_PATH" ] && [ -f "$ARCHIVE_PATH" ] && [ "${BACKUP_SUCCESS:-0}" -ne 1 ]; then
        rm -f "$ARCHIVE_PATH" "${ARCHIVE_PATH}.sha256" 2>/dev/null || true
        log "WARN" "Pembersihan: arsip parsial dihapus akibat proses terhenti."
    fi
}
trap cleanup EXIT INT TERM

# ==============================================================================
# FUNGSI UTAMA (Bagian A - Galang Putra Pratama)
# ==============================================================================

# Membuat arsip tar.gz dan menghitung checksum SHA256
do_backup() {
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    ARCHIVE_NAME="backup_${timestamp}.tar.gz"
    ARCHIVE_PATH="${DEST_DIR}/${ARCHIVE_NAME}"

    log "INFO" "Memulai kompresi direktori $SOURCE_DIR ..."

    local src_parent
    local src_base
    src_parent=$(dirname "$SOURCE_DIR")
    src_base=$(basename "$SOURCE_DIR")

    if ! tar -czf "$ARCHIVE_PATH" -C "$src_parent" "$src_base" 2>/dev/null; then
        log "ERROR" "Kompresi tar gagal dibuat pada $ARCHIVE_PATH"
        rm -f "$ARCHIVE_PATH" 2>/dev/null || true
        return 4
    fi

    log "INFO" "Arsip berhasil dibuat: $ARCHIVE_NAME"

    # Buat file checksum sha256 di direktori tujuan
    if ! (cd "$DEST_DIR" && sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"); then
        log "ERROR" "Gagal menghitung checksum SHA256"
        rm -f "$ARCHIVE_PATH" "${ARCHIVE_PATH}.sha256" 2>/dev/null || true
        return 4
    fi

    log "INFO" "Checksum SHA256 tersimpan: ${ARCHIVE_NAME}.sha256"
    return 0
}

# Verifikasi integritas arsip terhadap file checksum
verify_backup() {
    local target_archive="${1:-$ARCHIVE_NAME}"
    local target_dir="${2:-$DEST_DIR}"
    local sha_file="${target_archive}.sha256"

    log "INFO" "Memverifikasi integritas arsip $target_archive ..."

    if [ ! -f "${target_dir}/${sha_file}" ]; then
        log "ERROR" "File checksum tidak ditemukan: ${target_dir}/${sha_file}"
        return 1
    fi

    if (cd "$target_dir" && sha256sum -c "$sha_file" --status 2>/dev/null); then
        log "INFO" "Verifikasi integritas valid (SHA256 OK)."
        return 0
    else
        log "ERROR" "Verifikasi gagal: checksum arsip tidak cocok!"
        return 1
    fi
}

# Fungsi rollback / restore arsip ke direktori tertentu
restore_backup() {
    local archive_file="$1"
    local restore_dir="$2"

    if [ -z "$archive_file" ] || [ -z "$restore_dir" ]; then
        log "ERROR" "Penggunaan restore: restore_backup <file_arsip.tar.gz> <target_restore_dir>"
        return 1
    fi

    if [ ! -f "$archive_file" ]; then
        log "ERROR" "File arsip tidak ditemukan: $archive_file"
        return 1
    fi

    mkdir -p "$restore_dir"
    log "INFO" "Mengekstrak $archive_file ke $restore_dir ..."

    if tar -xzf "$archive_file" -C "$restore_dir"; then
        log "INFO" "Restore berhasil diselesaikan di $restore_dir"
        return 0
    else
        log "ERROR" "Gagal mengekstrak file arsip"
        return 4
    fi
}

# Entry point alur eksekusi script
main() {
    parse_args "$@"
    validate_input

    # Inisialisasi lokasi file log setelah DEST_DIR divalidasi
    LOG_FILE="${DEST_DIR}/backup.log"

    log "INFO" "=== Memulai Sesi Backup ==="
    log "INFO" "Sumber: $SOURCE_DIR | Tujuan: $DEST_DIR"

    if do_backup; then
        BACKUP_SUCCESS=1
        verify_backup "$ARCHIVE_NAME" "$DEST_DIR"
        log "INFO" "=== Sesi Backup Berhasil Selesai ==="
        exit 0
    else
        local exit_code=$?
        log "ERROR" "=== Sesi Backup Gagal (Exit Code: $exit_code) ==="
        exit "$exit_code"
    fi
}

# Jalankan jika dipanggil langsung sebagai script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
