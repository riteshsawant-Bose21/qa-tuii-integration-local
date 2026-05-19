"""
generate_product_cache_zip.py
─────────────────────────────
Builds product_cache.zip with images organized into category subfolders.

ZIP layout produced:
    products.json
    assets/
      speakers/
        DM8S_Right-Facing_1200x1022.jpeg
      amplifiers/
      controllers/
      dsps/
      accessories/
      io_endpoints/
      sources/
      outputs/

Usage (from Flutter project root):
    python generate_product_cache_zip.py --dry-run
    python generate_product_cache_zip.py
"""

import argparse
import json
import sys
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path


# ── helpers ───────────────────────────────────────────────────────────────────

def filename_from_url(url: str) -> str:
    path = urllib.parse.urlparse(url).path
    name = path.rstrip("/").rsplit("/", 1)[-1]
    return urllib.parse.unquote(name)


def get_category_folder(category_key: str) -> str:
    """Map API key to folder name — must match Dart's ProductCategory.folderName."""
    mapping = {
        "speaker": "speakers",
        "amplifier": "amplifiers",
        "controller": "controllers",
        "dsp": "dsps",
        "accessory": "accessories",
        "io_endpoint": "io_endpoints",
        "source": "sources",
        "output": "outputs",
    }
    return mapping.get(category_key, category_key + "s")


def build_filename_index(images_dir: Path) -> dict:
    """Build a lowercase-name → Path index from a flat images directory."""
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


# ── main ──────────────────────────────────────────────────────────────────────

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

    # Build a flat filename index from the local images directory
    filename_index = build_filename_index(images_dir)
    print(f"Files in images/: {len(filename_index)}")

    # Plan: url → {zip_name, source, orig_name, status}
    # zip_name = assets/<category_folder>/<original_filename>
    plan = []
    matched = missing = 0
    seen_urls: set = set()

    for category_key, products in products_json.items():
        folder = get_category_folder(category_key)
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
                        if not url.startswith("http") or url in seen_urls:
                            continue
                        seen_urls.add(url)
                        orig_name = filename_from_url(url)
                        zip_name = f"assets/{folder}/{orig_name}"
                        source = filename_index.get(orig_name.lower())
                        if source:
                            matched += 1
                            status = "matched"
                        else:
                            missing += 1
                            status = "MISSING"
                        plan.append({
                            "zip_name": zip_name,
                            "source": source,
                            "url": url,
                            "orig_name": orig_name,
                            "status": status,
                        })

    print(f"Image URLs found : {len(plan)}")
    print(f"Matched          : {matched}")
    print(f"Missing          : {missing}")

    # ── dry run ────────────────────────────────────────────────────────────────

    if args.dry_run:
        print("\n─── Dry run ───────────────────────────────────────────")
        for e in plan:
            mark = "✓" if e["status"] == "matched" else "✗"
            print(f"  [{mark}] {e['orig_name']}  ->  {e['zip_name']}")
        print("\nNothing written.")
        return

    # ── download missing ───────────────────────────────────────────────────────

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

    # ── write ZIP ──────────────────────────────────────────────────────────────

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

    # Cleanup temp downloads
    for f in tmp_downloads:
        f.unlink(missing_ok=True)
    tmp_dir = cache_dir / "_tmp_downloads"
    if tmp_dir.exists():
        try:
            tmp_dir.rmdir()
        except Exception:
            pass

    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"\nDone! {output_path.name}  ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
