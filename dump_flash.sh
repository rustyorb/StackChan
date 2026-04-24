#!/usr/bin/env bash
# Dumps full 16MB ESP32-S3 flash from COM5 in 1MB chunks, with retry.
set -u
PORT="COM5"
OUT_DIR="U:/_Projects/StackChan/chunks"
FINAL="U:/_Projects/StackChan/stackchan-full-16mb.bin"
CHUNK=$((1024*1024))    # 1 MB
TOTAL=$((16*1024*1024)) # 16 MB
MAX_RETRY=4

mkdir -p "$OUT_DIR"
: > "$FINAL"

off=0
idx=0
while [ "$off" -lt "$TOTAL" ]; do
  chunkfile=$(printf "%s/chunk_%02d.bin" "$OUT_DIR" "$idx")
  if [ -s "$chunkfile" ] && [ "$(stat -c%s "$chunkfile")" -eq "$CHUNK" ]; then
    echo "chunk $idx already complete, skipping"
  else
    attempt=1
    while : ; do
      echo ">>> chunk $idx (offset 0x$(printf '%x' $off), attempt $attempt)"
      if python -m esptool --chip esp32s3 --port "$PORT" read-flash "$off" "$CHUNK" "$chunkfile" 2>&1 | tail -3 ; then
        sz=$(stat -c%s "$chunkfile" 2>/dev/null || echo 0)
        if [ "$sz" -eq "$CHUNK" ]; then break; fi
      fi
      if [ "$attempt" -ge "$MAX_RETRY" ]; then
        echo "!!! chunk $idx failed after $MAX_RETRY attempts"
        exit 1
      fi
      attempt=$((attempt+1))
      sleep 2
    done
  fi
  off=$((off+CHUNK))
  idx=$((idx+1))
done

echo "concatenating..."
: > "$FINAL"
for i in $(seq 0 15); do
  f=$(printf "%s/chunk_%02d.bin" "$OUT_DIR" "$i")
  cat "$f" >> "$FINAL"
done
echo "done: $(stat -c%s "$FINAL") bytes at $FINAL"
