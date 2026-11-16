#!/usr/bin/env bash
# Flash Muse next to Vibe Buddy on a box, over the USB-SLAVE port (README.md). Vibe Buddy, its Character, its
# settings and its pairings stay. Build Muse first with ./build.sh. Quit the Vibe Buddy app first: it holds the port.
#
#   ./flash.sh <Vibe Buddy firmware zip> <port> [sdk token]
#
# The firmware zip is a Vibe Buddy firmware release (VibeBuddy-firmware-v0.6.2.zip or later). Its bootloader reads
# boot_sel, and its partition table has the Muse partitions; a box flashed before them has neither.
# Without a token it only flashes; send the token later with ./send-token.py <port> <token>.
set -euo pipefail

firmware="${1:?usage: ./flash.sh <Vibe Buddy firmware zip> <port> [sdk token]}"
port="${2:?usage: ./flash.sh <Vibe Buddy firmware zip> <port> [sdk token]}"
token="${3:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build="${here}/build"
[ -f "${build}/muse-gadget.bin" ] || { echo "no Muse build; run ./build.sh first" >&2; exit 1; }

vibebuddy="${build}/vibebuddy"
rm -rf "${vibebuddy}"
mkdir -p "${vibebuddy}"
unzip -q -o "${firmware}" bootloader.bin partition-table.bin -d "${vibebuddy}" \
    || { echo "${firmware}: not a Vibe Buddy firmware zip" >&2; exit 1; }

export IDF_PATH="${IDF_PATH:-${HOME}/esp/esp-idf-v6.0.3}"
# shellcheck disable=SC1091
. "${IDF_PATH}/export.sh" >/dev/null

# An older firmware's table has no Muse partitions: flashing it with Muse would put Muse where nothing boots it.
python3 "${IDF_PATH}/components/partition_table/gen_esp32part.py" "${vibebuddy}/partition-table.bin" 2>/dev/null \
    | grep -q '^boot_sel,' \
    || { echo "${firmware}: this firmware has no Muse partitions; use firmware 0.6.2 or later" >&2; exit 1; }

# boot_sel set to Muse ("MUSE"), so the box starts Muse when the flash is done.
boot_sel="${build}/boot_sel-muse.bin"
python3 -c 'import sys; sys.stdout.buffer.write(b"MUSE" + b"\xff" * 4092)' > "${boot_sel}"

python3 -m esptool --chip esp32s3 -p "${port}" -b 460800 --after hard-reset \
    write-flash --flash-mode keep --flash-freq keep --flash-size keep \
    0x0 "${vibebuddy}/bootloader.bin" \
    0x8000 "${vibebuddy}/partition-table.bin" \
    0xc14000 "${build}/partition_table/partition-table.bin" \
    0xc21000 "${boot_sel}" \
    0xc30000 "${build}/muse-gadget.bin"

if [ -n "${token}" ]; then
    python3 "${here}/send-token.py" "${port}" "${token}"
fi
