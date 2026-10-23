#!/bin/bash
# ================================================
# run_tests.sh — Test case untuk backup.sh
# Penulis: Shelenia Violine Karo Karo
# ================================================
# Jalankan dari root repo: ./tests/run_tests.sh

SCRIPT="./src/backup.sh"
PASS=0
FAIL=0
TOTAL=3

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

report() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" -eq "$actual" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name (expected=$expected, actual=$actual)"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}[FAIL]${NC} $test_name (expected=$expected, actual=$actual)"
        FAIL=$((FAIL + 1))
    fi
}

echo "========================================"
echo " Test Suite — backup.sh"
echo " Tanggal: $(date)"
echo "========================================"
echo ""

# --- Test 1: Backup normal (exit 0) ---
echo "--- Test 1: Backup normal (harus sukses, exit 0) ---"
TEST1_SRC=$(mktemp -d)
TEST1_DST=$(mktemp -d)
echo "data test 1" > "$TEST1_SRC/contoh.txt"
mkdir -p "$TEST1_SRC/subfolder"
echo "data subfolder" > "$TEST1_SRC/subfolder/file2.txt"

$SCRIPT -s "$TEST1_SRC" -d "$TEST1_DST"
actual=$?
report "Backup normal" 0 "$actual"

arsip=$(ls "$TEST1_DST"/backup_*.tar.gz 2>/dev/null | head -1)
if [ -f "$arsip" ] && [ -f "${arsip}.sha256" ]; then
    echo "  ✓ Arsip ditemukan: $(basename "$arsip")"
    echo "  ✓ Checksum ditemukan: $(basename "${arsip}.sha256")"
else
    echo "  ✗ Arsip atau checksum tidak ditemukan"
fi

# Simpan log sukses (kalau ada) sebagai bukti
cp "$TEST1_DST"/backup_*.log docs/log_sukses.txt 2>/dev/null

rm -rf "$TEST1_SRC" "$TEST1_DST"
echo ""

# --- Test 2: Sumber tidak ada (exit 2) ---
echo "--- Test 2: Sumber tidak ada (harus gagal, exit 2) ---"
TEST2_DST=$(mktemp -d)

$SCRIPT -s "/path/yang/tidak/ada" -d "$TEST2_DST"
actual=$?
report "Sumber tidak ada" 2 "$actual"

rm -rf "$TEST2_DST"
echo ""

# --- Test 3: Argumen kurang (exit 1) ---
echo "--- Test 3: Argumen kurang (harus gagal, exit 1) ---"

$SCRIPT
actual=$?
report "Argumen kurang" 1 "$actual"
echo ""

echo "========================================"
echo " Hasil: $PASS/$TOTAL lulus, $FAIL/$TOTAL gagal"
echo "========================================"
