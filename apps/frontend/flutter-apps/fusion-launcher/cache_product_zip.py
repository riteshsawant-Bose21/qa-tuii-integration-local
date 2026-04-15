"""
generate_product_cache_zip.py
─────────────────────────────
Builds product_cache.zip preserving ORIGINAL image filenames.

ZIP layout produced:
    products.json
    assets/
      DM8S_Right-Facing_1200x1022.jpeg   ← original name, NOT base64
      DM8C_Flush_Group_1200x1022.jpeg
      …

Usage (from Flutter project root):
    python generate_product_cache_zip.py --dry-run
    python generate_product_cache_zip.py
"""

import argparse
import json
import os
import sys
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path


def filename_from_url(url: str) -> str:
    path = urllib.parse.urlparse(url).path
    name = path.rstrip("/").rsplit("/", 1)[-1]
    return urllib.parse.unquote(name)


def collect_image_urls(products_json: dict) -> list:
    urls = []
    seen = set()
    for products in products_json.values():
        if not isinstance(products, list):
            continue
        for product in products:
            if not isinstance(product, dict):
                continue
            assets = product.get("assets") or product.get("images")
            if not isinstance(assets, list):
                continue
            for group in assets:
                if not isinstance(group, dict):
                    continue
                for url_list in group.values():
                    if not isinstance(url_list, list):
                        continue
                    for url in url_list:
                        url = url.strip() if isinstance(url, str) else ""
                        if url.startswith("http") and url not in seen:
                            seen.add(url)
                            urls.append(url)
    return urls


def build_filename_index(images_dir: Path) -> dict:
    index = {}
    if not images_dir.is_dir():
        return index
    for f in images_dir.iterdir():
        if f.is_file():
            index[f.name.lower()] = f
    return index


def download_file(url: str, dest: Path) -> bool:
    try:
        print(f"    downloading {url}")
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            dest.write_bytes(resp.read())
        return True
    except Exception as e:
        print(f"    download failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--product-cache-dir", default="assets/zip/product_cache")
    parser.add_argument("--output", default="assets/zip/product_cache.zip")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-download", action="store_true")
    args = parser.parse_args()

    cache_dir  = Path(args.product_cache_dir).expanduser().resolve()
    images_dir = cache_dir / "images"
    json_path  = cache_dir / "products.json"

    print(f"Cache dir : {cache_dir}")
    print(f"Images dir: {images_dir}")

    if not json_path.exists():
        print(f"ERROR: products.json not found at {json_path}", file=sys.stderr)
        sys.exit(1)

    with open(json_path, encoding="utf-8") as f:
        products_json = json.load(f)

    urls = collect_image_urls(products_json)
    print(f"Image URLs in products.json: {len(urls)}")

    filename_index = build_filename_index(images_dir)
    print(f"Files in images/: {len(filename_index)}")

    # Plan: url → (source_file, zip_entry_name)
    # zip_entry_name = assets/<original_filename>  ← no hashing
    plan = []
    matched = missing = 0

    for url in urls:
        orig_name = filename_from_url(url)
        zip_name  = f"assets/{orig_name}"          # original name in ZIP
        source    = filename_index.get(orig_name.lower())

        if source:
            matched += 1
            status = "matched"
        else:
            missing += 1
            status = "MISSING"

        plan.append({"zip_name": zip_name, "source": source,
                     "url": url, "orig_name": orig_name, "status": status})

    print(f"\nMatched : {matched}")
    print(f"Missing : {missing}")

    if args.dry_run:
        print("\n─── Dry run ───────────────────────────────────────────")
        for e in plan:
            mark = "✓" if e["status"] == "matched" else "✗"
            print(f"  [{mark}] {e['orig_name']}  ->  {e['zip_name']}")
        print("\nNothing written.")
        return

    # Download missing
    tmp_downloads = []
    if missing > 0 and not args.no_download:
        print(f"\nDownloading {missing} missing image(s)…")
        tmp_dir = cache_dir / "_tmp_downloads"
        tmp_dir.mkdir(exist_ok=True)
        for entry in plan:
            if entry["source"] is None:
                dest = tmp_dir / entry["orig_name"]
                if download_file(entry["url"], dest):
                    entry["source"] = dest
                    entry["status"] = "downloaded"
                    tmp_downloads.append(dest)

    # Write ZIP
    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"\nWriting ZIP -> {output_path}")
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(json_path, "products.json")
        print("  + products.json")

        version_path = cache_dir / "version.txt"
        if version_path.exists():
            zf.write(version_path, "version.txt")
            print("  + version.txt")

        for entry in plan:
            if entry["source"] is not None:
                zf.write(entry["source"], entry["zip_name"])
                print(f"  + {entry['zip_name']}")
            else:
                print(f"  - SKIPPED {entry['orig_name']}")

    for f in tmp_downloads:
        f.unlink(missing_ok=True)
    tmp_dir = cache_dir / "_tmp_downloads"
    if tmp_dir.exists():
        try: tmp_dir.rmdir()
        except: pass

    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"\nDone! {output_path.name}  ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()