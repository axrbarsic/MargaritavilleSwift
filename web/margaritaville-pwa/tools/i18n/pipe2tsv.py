#!/usr/bin/env python3
"""Переводит черновик таблицы с разделителем « | » в TSV (удобно писать без табуляций)."""
import sys
src, dst = sys.argv[1], sys.argv[2]
rows = []
for line in open(src, encoding="utf-8"):
    line = line.rstrip("\n")
    if not line.strip():
        continue
    rows.append("\t".join(cell.strip() for cell in line.split(" | ")))
open(dst, "w", encoding="utf-8").write("\n".join(rows) + "\n")
