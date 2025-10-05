import shutil
import os
from pathlib import Path
import getpass
import py7zr


def load_dist_rules(rules_file='.dist.rules'):
    includes = []
    exclude_names = []
    exclude_prefixes = []
    exclude_suffixes = []

    current_section = None

    with open(rules_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            if line == 'INCLUDE:':
                current_section = 'include'
            elif line == 'EXCLUDE_NAMES:':
                current_section = 'exclude_names'
            elif line == 'EXCLUDE_PREFIXES:':
                current_section = 'exclude_prefixes'
            elif line == 'EXCLUDE_SUFFIXES:':
                current_section = 'exclude_suffixes'
            else:
                if current_section == 'include':
                    includes.append(line)
                elif current_section == 'exclude_names':
                    exclude_names.append(line)
                elif current_section == 'exclude_prefixes':
                    exclude_prefixes.append(line)
                elif current_section == 'exclude_suffixes':
                    exclude_suffixes.append(line)

    return includes, exclude_names, exclude_prefixes, exclude_suffixes


def should_exclude(path, exclude_names, exclude_prefixes, exclude_suffixes, includes):
    path_str = str(path)
    name = path.name

    if name in exclude_names:
        return True

    for prefix in exclude_prefixes:
        if name.startswith(prefix):
            if name in includes or name == '.dist.rules':
                return False
            return True

    for suffix in exclude_suffixes:
        if name.endswith(suffix):
            return True

    parts = Path(path_str).parts
    for part in parts:
        if part in exclude_names:
            return True

    return False


def copy_with_rules(src, dst, exclude_names, exclude_prefixes, exclude_suffixes, includes):
    src_path = Path(src)
    dst_path = Path(dst)

    if should_exclude(src_path, exclude_names, exclude_prefixes, exclude_suffixes, includes):
        return

    if src_path.is_file():
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"Copied: {src}")
    elif src_path.is_dir():
        dst_path.mkdir(parents=True, exist_ok=True)
        for item in src_path.iterdir():
            copy_with_rules(item, dst_path / item.name, exclude_names, exclude_prefixes, exclude_suffixes, includes)


def compress_to_7z(dist_dir, password=None):
    archive_file = Path('./act-aio-dist.7z')

    if archive_file.exists():
        print(f"Removing existing {archive_file}...")
        archive_file.unlink()

    print(f"\nCompressing {dist_dir} to {archive_file}...")

    try:
        # Create 7z archive with py7zr
        with py7zr.SevenZipFile(archive_file, 'w', password=password, header_encryption=bool(password)) as archive:
            # Add all files from dist directory
            for root, dirs, files in os.walk(dist_dir):
                for file in files:
                    file_path = Path(root) / file
                    arcname = file_path.relative_to(dist_dir.parent)
                    archive.write(file_path, arcname)

        if password:
            print(f"✓ Password-protected 7z archive created with filename encryption: {archive_file}")
        else:
            print(f"✓ 7z archive created: {archive_file}")
    except Exception as e:
        print(f"✗ Error creating 7z archive: {e}")


def create_distribution():
    dist_dir = Path('./dist')

    if dist_dir.exists():
        print(f"Removing existing {dist_dir}...")
        shutil.rmtree(dist_dir)

    print("Loading distribution rules from .dist.rules...")
    includes, exclude_names, exclude_prefixes, exclude_suffixes = load_dist_rules()

    print(f"\nCreating distribution in {dist_dir}...\n")
    dist_dir.mkdir(exist_ok=True)

    for item in includes:
        src = Path(item)
        if src.exists():
            dst = dist_dir / item
            copy_with_rules(src, dst, exclude_names, exclude_prefixes, exclude_suffixes, includes)
        else:
            print(f"Warning: {item} not found, skipping...")

    print(f"\n✓ Distribution created successfully in {dist_dir}")

    # Ask user about compression
    print("\n" + "="*50)
    response = input("Compress to 7z? (Y/N): ").strip().upper()

    if response == 'Y':
        password = getpass.getpass("Enter password (leave empty for no password): ").strip()
        if password:
            compress_to_7z(dist_dir, password)
        else:
            compress_to_7z(dist_dir)
    else:
        print("Skipping compression.")


if __name__ == '__main__':
    create_distribution()