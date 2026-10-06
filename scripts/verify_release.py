"""Reject missing, truncated, corrupt or wrongly targeted downloaded APK assets."""
import argparse
import hashlib
import pathlib
import re
import zipfile


APK_ABIS = {
    "khidmat-universal.apk": {"armeabi-v7a", "arm64-v8a", "x86_64"},
    "khidmat-arm64-v8a.apk": {"arm64-v8a"},
    "khidmat-armeabi-v7a.apk": {"armeabi-v7a"},
    "khidmat-x86_64.apk": {"x86_64"},
}


def verify(directory):
    manifest = (directory / "SHA256SUMS").read_text(encoding="utf8")
    hashes = {}
    for line in manifest.splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r"([0-9a-fA-F]{64}) [ *]([^/\\]+)", line)
        if match is None:
            raise ValueError("Malformed checksum line: " + line)
        digest, filename = match.groups()
        if filename in hashes:
            raise ValueError("Duplicate checksum entry: " + filename)
        hashes[filename] = digest.lower()
    for filename, expected_abis in APK_ABIS.items():
        if filename not in hashes:
            raise ValueError("Required APK checksum missing: " + filename)
        apk = directory / filename
        with apk.open("rb") as file:
            actual_digest = hashlib.file_digest(file, "sha256").hexdigest()
        if actual_digest != hashes[filename]:
            raise ValueError("APK checksum mismatch: " + filename)
        with zipfile.ZipFile(apk) as archive:
            corrupt_entry = archive.testzip()
            if corrupt_entry:
                raise ValueError("Corrupt APK ZIP entry: " + filename + ": " + corrupt_entry)
            names = set(archive.namelist())
            if not {"AndroidManifest.xml", "classes.dex", "resources.arsc"}.issubset(names):
                raise ValueError("Incomplete Android package: " + filename)
            actual_abis = {name.split("/")[1] for name in names if re.fullmatch(r"lib/[^/]+/libflutter\.so", name)}
            if actual_abis != expected_abis:
                raise ValueError("Unexpected Flutter native architectures: " + filename + ": " + str(actual_abis))
            for abi in expected_abis:
                if "lib/" + abi + "/libapp.so" not in names:
                    raise ValueError("Compiled app code missing: " + filename + ": " + abi)
        print("Verified complete APK:", filename, apk.stat().st_size, "bytes", actual_digest)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=pathlib.Path)
    verify(parser.parse_args().directory)
