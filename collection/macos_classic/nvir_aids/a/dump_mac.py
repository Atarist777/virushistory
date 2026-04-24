#!/usr/bin/env python3
"""
dump_mac.py

Dissects classic Mac OS resource fork data.

Usage:
  python dump_mac.py file.rsrc
  python dump_mac.py file.rsrc --dump outdir
  python dump_mac.py
 file.rsrc --json
"""

#!/usr/bin/env python3

import argparse
import json
import os
import struct
import hashlib
from pathlib import Path


def u16(b, o): return struct.unpack_from(">H", b, o)[0]
def i16(b, o): return struct.unpack_from(">h", b, o)[0]
def u32(b, o): return struct.unpack_from(">I", b, o)[0]


def macroman(bs):
    return bs.decode("mac_roman", errors="replace")


def fourcc(bs):
    return bs.decode("mac_roman", errors="replace")


def hash_blob(b):
    return {
        "sha256": hashlib.sha256(b).hexdigest(),
        "md5": hashlib.md5(b).hexdigest()
    }


def parse_resource_fork(data):
    if len(data) < 16:
        raise ValueError("Too small to be a resource fork")

    data_off = u32(data, 0)
    map_off = u32(data, 4)
    data_len = u32(data, 8)
    map_len = u32(data, 12)

    if data_off + data_len > len(data):
        raise ValueError("Resource data area extends past end of file")
    if map_off + map_len > len(data):
        raise ValueError("Resource map extends past end of file")

    map_attr = u16(data, map_off + 0x16)
    type_list_off = map_off + u16(data, map_off + 0x18)
    name_list_off = map_off + u16(data, map_off + 0x1A)

    type_count = u16(data, type_list_off) + 1
    type_entries_off = type_list_off + 2

    result = {
        "header": {
            "data_offset": data_off,
            "map_offset": map_off,
            "data_length": data_len,
            "map_length": map_len,
            "map_attributes": map_attr,
            "type_count": type_count,
        },
        "resources": []
    }

    for t in range(type_count):
        te = type_entries_off + t * 8

        rtype = fourcc(data[te:te+4])
        count = u16(data, te + 4) + 1
        ref_list_off = type_list_off + u16(data, te + 6)

        for r in range(count):
            re = ref_list_off + r * 12

            rid = i16(data, re)
            name_off_raw = u16(data, re + 2)
            attrs = data[re + 4]

            body_rel_off = (
                (data[re + 5] << 16) |
                (data[re + 6] << 8) |
                data[re + 7]
            )

            handle = u32(data, re + 8)

            body_len_off = data_off + body_rel_off
            body_len = u32(data, body_len_off)
            body_off = body_len_off + 4
            body_end = body_off + body_len

            if body_end > len(data):
                status = "truncated_or_invalid"
                body_len = max(0, len(data) - body_off)
                body_end = len(data)
            else:
                status = "ok"

            body = data[body_off:body_end]
            hashes = hash_blob(body)

            if name_off_raw == 0xFFFF:
                name = None
            else:
                no = name_list_off + name_off_raw
                nlen = data[no]
                name = macroman(data[no + 1:no + 1 + nlen])

            result["resources"].append({
                "type": rtype,
                "id": rid,
                "name": name,
                "attributes": attrs,
                "data_offset": body_off,
                "data_length": body_len,
                "data_end": body_end,
                "handle": handle,
                "status": status,
                "hashes": hashes
            })

    return result


def safe_name(s):
    bad = '<>:"/\\|?*\x00'
    return "".join("_" if c in bad else c for c in str(s))


def dump_resources(data, parsed, outdir):
    Path(outdir).mkdir(parents=True, exist_ok=True)

    for res in parsed["resources"]:
        body = data[res["data_offset"]:res["data_end"]]

        namepart = f"_{safe_name(res['name'])}" if res["name"] else ""
        fname = f"{safe_name(res['type'])}_{res['id']}{namepart}.bin"
        path = Path(outdir) / fname

        with open(path, "wb") as f:
            f.write(body)

        res["dumped_to"] = str(path)


def print_text(parsed):
    h = parsed["header"]

    print("Resource fork")
    print("=" * 60)
    print(f"Data offset : 0x{h['data_offset']:08X}")
    print(f"Map offset  : 0x{h['map_offset']:08X}")
    print(f"Data length : 0x{h['data_length']:08X} / {h['data_length']}")
    print(f"Map length  : 0x{h['map_length']:08X} / {h['map_length']}")
    print(f"Map attrs   : 0x{h['map_attributes']:04X}")
    print(f"Types       : {h['type_count']}")
    print()

    headers = [
        "TYPE", "ID", "ATTR", "OFFSET", "SIZE",
        "NAME", "MD5", "SHA256", "STATUS"
    ]

    rows = []

    for r in parsed["resources"]:
        rows.append([
            r["type"],
            str(r["id"]),
            f"0x{r['attributes']:02X}",
            f"0x{r['data_offset']:08X}",
            str(r["data_length"]),
            r["name"] or "",
            r["hashes"]["md5"],
            r["hashes"]["sha256"],
            r["status"],
        ])

    widths = [
        max(len(headers[i]), *(len(row[i]) for row in rows))
        for i in range(len(headers))
    ]

    fmt = "  ".join(f"{{:<{w}}}" for w in widths)

    print(fmt.format(*headers))
    print(fmt.format(*["-" * w for w in widths]))

    for row in sorted(rows, key=lambda x: (x[0], int(x[1]))):
        print(fmt.format(*row))




def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--dump", metavar="DIR")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    with open(args.file, "rb") as f:
        data = f.read()

    parsed = parse_resource_fork(data)

    if args.dump:
        dump_resources(data, parsed, args.dump)

    if args.json:
        print(json.dumps(parsed, indent=2, ensure_ascii=False))
    else:
        print_text(parsed)


if __name__ == "__main__":
    main()
