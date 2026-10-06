"""Install and exercise the actual APK. Saves screenshots, hierarchy and logs."""
import pathlib
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

apk = pathlib.Path(sys.argv[1]).resolve(strict=True)
evidence = pathlib.Path("smoke-evidence")
evidence.mkdir(exist_ok=True)
package = "com.khidmat.khidmat"

def adb(*args, check=True):
    return subprocess.run(["adb", *args], capture_output=True, text=True, check=check).stdout

def hierarchy(name):
    adb("shell", "uiautomator", "dump", "/sdcard/khidmat-ui.xml", check=False)
    xml = adb("shell", "cat", "/sdcard/khidmat-ui.xml", check=False)
    (evidence / (name + ".xml")).write_text(xml, encoding="utf8")
    return xml

def capture(name):
    with (evidence / (name + ".png")).open("wb") as file:
        subprocess.run(["adb", "exec-out", "screencap", "-p"], stdout=file, check=True)

def tap_label(xml, label):
    root = ET.fromstring(xml)
    for node in root.iter("node"):
        if label in (node.get("text", "") + node.get("content-desc", "")):
            values = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
            if len(values) == 4:
                x1, y1, x2, y2 = values
                adb("shell", "input", "tap", str((x1+x2)//2), str((y1+y2)//2))
                return
    raise AssertionError("Visible control missing: " + label)

try:
    print(adb("install", "-r", str(apk)).strip())
    package_info = adb("shell", "dumpsys", "package", package)
    assert "versionCode=5001 " in package_info, "Wrong APK version installed"
    adb("logcat", "-c")
    print(adb("shell", "am", "start", "-W", "-n", package + "/.MainActivity"))
    deadline = time.monotonic() + 75
    xml = ""
    while time.monotonic() < deadline:
        xml = hierarchy("startup")
        if "Unable to connect" in xml or "Trusted help" in xml:
            break
        time.sleep(2)
    assert "Unable to connect" in xml or "Trusted help" in xml, "No usable app screen after launch"
    assert adb("shell", "pidof", package).strip(), "App process died"
    capture("english")
    tap_label(xml, "اردو")
    time.sleep(1)
    urdu = hierarchy("urdu")
    assert "English" in urdu, "Language switch failed"
    capture("urdu")
    adb("shell", "am", "force-stop", package)
    adb("shell", "am", "start", "-W", "-n", package + "/.MainActivity")
    time.sleep(5)
    assert "English" in hierarchy("restart"), "Language preference did not survive restart"
    print("PASS: APK installs, launches, draws real UI, switches Urdu, and survives restart.")
finally:
    (evidence / "logcat.txt").write_text(adb("logcat", "-d"), encoding="utf8")
