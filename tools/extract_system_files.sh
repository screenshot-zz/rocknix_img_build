#!/bin/bash
set -e

if [ "$UID" -ne 0 ]; then
    echo "Please run with: sudo $0 <img_file>"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: sudo $0 <img_file>"
    exit 1
fi

IMG="$1"
SYS_ROOT="sys_root_files"
OUTPUT_DIR="sys_root_files_v2"
PART_MOUNT_DIR=$(mktemp -d)
SYS_MOUNT_DIR=$(mktemp -d)

# 检查依赖工具
command -v fdisk >/dev/null 2>&1 || { echo >&2 "fdisk required but not found. Aborting."; exit 1; }
command -v mount >/dev/null 2>&1 || { echo >&2 "mount required but not found. Aborting."; exit 1; }

# 获取分区信息
get_partitions() {
    fdisk -l "$IMG" | awk -v img="$IMG" '
        $1 ~ img"[0-9]+" {
            # 提取分区号
            split($1, parts, img);
            part_num = parts[2];
            gsub(/[^0-9]/, "", part_num);
            
            # 提取起始扇区
            for (i=2; i<=NF; i++) {
                if ($i ~ /^[0-9]+$/) {
                    start = $i;
                    break;
                }
            }
            print part_num, start;
        }
    '
}

# 获取分区列表
partitions=$(get_partitions)
if [ -z "$partitions" ]; then
    echo "Error: No partitions found in image"
    exit 1
fi

# 获取倒数第二个分区号
partition_count=$(echo "$partitions" | wc -l)
if [ "$partition_count" -lt 2 ]; then
    echo "Error: Image has less than 2 partitions"
    exit 1
fi

# 获取倒数第二个分区的起始扇区
target_partition=$(echo "$partitions" | sort -k1n | tail -n 2 | head -n 1)
partition_num=$(echo "$target_partition" | awk '{print $1}')
start_sector=$(echo "$target_partition" | awk '{print $2}')

echo "Selected partition $partition_num with start sector $start_sector"

# 计算偏移量 (bytes)
offset=$((start_sector * 512))

# 挂载分区（可能是FAT32或EXT4）
echo "Mounting partition $partition_num at $PART_MOUNT_DIR"
mount -o loop,offset="$offset" "$IMG" "$PART_MOUNT_DIR"

# 在分区中查找SYSTEM文件（支持多种常见名称）
SYSTEM_FILE=""
for name in SYSTEM system.img SYSTEM.img system.squashfs; do
    if [ -f "$PART_MOUNT_DIR/$name" ]; then
        SYSTEM_FILE="$PART_MOUNT_DIR/$name"
        echo "Found SYSTEM file: $name"
        break
    fi
done

if [ -z "$SYSTEM_FILE" ]; then
    echo "ERROR: No SYSTEM file found in partition $partition_num"
    umount "$PART_MOUNT_DIR"
    rm -rf "$PART_MOUNT_DIR" "$SYS_MOUNT_DIR"
    exit 1
fi

# 挂载squashfs文件
echo "Mounting SYSTEM squashfs at $SYS_MOUNT_DIR"
mount -t squashfs -o loop "$SYSTEM_FILE" "$SYS_MOUNT_DIR"

# 复制文件
echo "Copying files to $OUTPUT_DIR"
find "$SYS_ROOT" -type f | while read -r local_file; do
    rel_path="${local_file#$SYS_ROOT/}"
    img_file="$SYS_MOUNT_DIR/$rel_path"
    
    if [ -f "$img_file" ]; then
        dest="$OUTPUT_DIR/$rel_path"
        mkdir -p "$(dirname "$dest")"
        cp -v "$img_file" "$dest"
    else
        echo "WARNING: File not found in SYSTEM: $rel_path"
    fi
done

# 清理
umount "$SYS_MOUNT_DIR"
umount "$PART_MOUNT_DIR"
rm -rf "$PART_MOUNT_DIR" "$SYS_MOUNT_DIR"
echo "Operation completed. Files saved to $OUTPUT_DIR"
