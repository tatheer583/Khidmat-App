"""Install the actual APK and exercise launch, language and retained preferences."""
import argparse
import pathlib
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("apk", type=pathlib.Path)
parser.add_argument("--expected-version", type=int, default=5001)
parser.add_argument("--initial-language", choices=("en", "ur"))
parser.add_argument("--evidence-name", default="current")
arguments = parser.parse_args()
apk = arguments.apk.resolve(strict=True)
evidence = pathlib.Path("smoke-evidence") / arguments.evidence_name
evidence.mkdir(parents=True, exist_ok=True)
package = "com.khidmat.khidmat"

def adb(*args, check=True):
    result = subprocess.run(
        ["adb", *args], capture_output=True, text=True, encoding="utf8",
        errors="replace", timeout=90,
    )
    if check and result.returncode:
        raise RuntimeError("adb failed: " + " ".join(args) + "\n" + result.stdout + result.stderr)
    return result.stdout

def hierarchy(name):
    adb("shell", "uiautomator", "dump", "/sdcard/khidmat-ui.xml", check=False)
    xml = adb("shell", "cat", "/sdcard/khidmat-ui.xml", check=False)
    (evidence / (name + ".xml")).write_text(xml, encoding="utf8")
    return xml

def capture(name):
    with (evidence / (name + ".png")).open("wb") as file:
        subprocess.run(["adb", "exec-out", "screencap", "-p"], stdout=file, check=True, timeout=30)

def labels(xml):
    try:
        return [node.get("text", "") + node.get("content-desc", "") for node in ET.fromstring(xml).iter("node")]
    except ET.ParseError:
        return []

def has_label(xml, label):
    return any(label in value for value in labels(xml))

def wait_for_screen(name, language=None):
    """A loading spinner or the native splash does not count as a usable screen."""
    deadline = time.monotonic() + 75
    while time.monotonic() < deadline:
        xml = hierarchy(name)
        english = "Unable to connect" in xml or "Trusted help" in xml
        urdu = "رابطہ نہیں ہو سکا" in xml or "قابلِ اعتماد مدد" in xml
        usable = english or urdu
        expected = language is None or has_label(xml, "English" if language == "ur" else "اردو")
        if usable and expected:
            assert adb("shell", "pidof", package).strip(), "App process died"
            return xml
        time.sleep(2)
    raise AssertionError("No usable app screen in the expected language after launch")

def tap_label(xml, label):
    root = ET.fromstring(xml)
    for node in root.iter("node"):
        if label in (node.get("text", "") + node.get("content-desc", "")):
            values = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
            if len(values) == 4:
                x1, y1, x2, y2 = values
                adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
                return
    raise AssertionError("Visible control missing: " + label)

def launch():
    adb("shell", "am", "force-stop", package)
    output = adb("shell", "am", "start", "-W", "-n", package + "/.MainActivity")
    assert "Error:" not in output and "Error type" not in output, output
    print(output)

try:
    print(adb("install", "-r", str(apk)).strip())
    package_info = adb("shell", "dumpsys", "package", package)
    (evidence / "package.txt").write_text(package_info, encoding="utf8")
    assert re.search(r"\bversionCode=" + str(arguments.expected_version) + r"\b", package_info), "Wrong APK version installed"
    adb("logcat", "-c")
    launch()
    xml = wait_for_screen("startup", arguments.initial_language)
    capture("startup")
    if has_label(xml, "English"):
        tap_label(xml, "English")
        xml = wait_for_screen("english", "en")
    capture("english")
    tap_label(xml, "اردو")
    wait_for_screen("urdu", "ur")
    capture("urdu")
    launch()
    wait_for_screen("restart", "ur")
    capture("restart")
    print("PASS: APK installs, launches usable UI, switches Urdu and retains language through restart/upgrade.")
finally:
    # Retain diagnostics on failed installs and launches as well as passing runs.
    try:
        hierarchy("final")
        capture("final")
        (evidence / "logcat.txt").write_text(adb("logcat", "-d", check=False), encoding="utf8")
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as diagnostic_error:
        print("Could not collect all diagnostics:", diagnostic_error)
