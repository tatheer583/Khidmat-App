"""Install the actual APK and exercise launch, language and retained preferences."""
import argparse
import pathlib
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("apk", type=pathlib.Path)
parser.add_argument("--expected-version", type=int, default=5005)
parser.add_argument("--package", default="com.khidmat.khidmat")
parser.add_argument("--initial-language", choices=("en", "ur"))
parser.add_argument("--evidence-name", default="current")
parser.add_argument("--offline", action="store_true")
parser.add_argument("--exercise-local-flow", action="store_true")
arguments = parser.parse_args()
apk = arguments.apk.resolve(strict=True)
evidence = pathlib.Path("smoke-evidence") / arguments.evidence_name
evidence.mkdir(parents=True, exist_ok=True)
package = arguments.package

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
        return [node.get("text", "") + node.get("content-desc", "") + node.get("hint", "") for node in ET.fromstring(xml).iter("node")]
    except ET.ParseError:
        return []

def has_label(xml, label):
    return any(label in value for value in labels(xml))

def wait_for_screen(name, language=None):
    """A loading spinner or the native splash does not count as a usable screen."""
    deadline = time.monotonic() + 75
    while time.monotonic() < deadline:
        xml = hierarchy(name)
        english = (
            "Unable to connect" in xml
            or "Khidmat setup is not complete" in xml
            or "Trusted local help" in xml
            or "Trusted help" in xml  # Previous signed releases use this label.
            or "Private organizer" in xml
        )
        urdu = (
            "رابطہ نہیں ہو سکا" in xml
            or "خدمت کی تیاری مکمل نہیں ہوئی" in xml
            or "قابلِ اعتماد مقامی مدد" in xml
            or "قابلِ اعتماد مدد" in xml  # Previous signed releases use this translation.
            or "نجی ریکارڈ" in xml
        )
        usable = english or urdu
        expected = language is None or has_label(xml, "English" if language == "ur" else "اردو")
        if usable and expected:
            assert adb("shell", "pidof", package).strip(), "App process died"
            return xml
        time.sleep(2)
    raise AssertionError("No usable app screen in the expected language after launch")

def tap_label(xml, label):
    root = ET.fromstring(xml)
    candidates = [node for node in root.iter("node")
                  if label in (node.get("text", "") + node.get("content-desc", ""))]
    candidates.sort(key=lambda node: node.get("clickable") == "true", reverse=True)
    for node in candidates:
        if node.get("enabled") != "false":
            values = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
            if len(values) == 4:
                x1, y1, x2, y2 = values
                adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
                return
    raise AssertionError("Visible control missing: " + label)

def launch():
    adb("shell", "am", "force-stop", package)
    output = adb("shell", "am", "start", "-W", "-n", package + "/com.khidmat.khidmat.MainActivity")
    assert "Error:" not in output and "Error type" not in output, output
    print(output)

def wait_for_label(name, label):
    deadline = time.monotonic() + 40
    while time.monotonic() < deadline:
        xml = hierarchy(name)
        if has_label(xml, label):
            assert adb("shell", "pidof", package).strip(), "App process died"
            return xml
        time.sleep(1)
    raise AssertionError("Screen did not show: " + label)

def scroll():
    dimensions = re.findall(r"(\d+)x(\d+)", adb("shell", "wm", "size"))
    width, height = map(int, dimensions[-1])
    adb("shell", "input", "swipe", str(width // 2), str(height * 3 // 4),
        str(width // 2), str(height // 3), "350")
    time.sleep(0.5)

def tap_visible(label):
    for _ in range(10):
        xml = hierarchy("controls")
        if has_label(xml, label):
            tap_label(xml, label)
            time.sleep(0.5)
            return
        scroll()
    raise AssertionError("Control did not become visible: " + label)

def fill_input(label, value):
    identifier = "khidmat.input." + re.sub(r"[^a-z0-9]+", "_", label.lower())
    for _ in range(10):
        xml = hierarchy("form")
        for node in ET.fromstring(xml).iter("node"):
            description = node.get("content-desc", "") + node.get("hint", "") + node.get("text", "")
            if label not in description and node.get("resource-id") != identifier:
                continue
            fields = [item for item in node.iter("node") if item.get("class") == "android.widget.EditText"]
            if fields:
                field = fields[0]
                x1, y1, x2, y2 = map(int, re.findall(r"\d+", field.get("bounds", "")))
                adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
                adb("shell", "input", "text", value.replace(" ", "%s"))
                adb("shell", "input", "keyevent", "KEYCODE_BACK")
                time.sleep(0.5)
                return
        scroll()
    raise AssertionError("Editable field did not become visible: " + label)

def exercise_local_flow():
    xml = hierarchy("local-flow-start")
    if has_label(xml, "English"):
        tap_label(xml, "English")
        wait_for_screen("local-flow-english", "en")
    xml = hierarchy("local-entry")
    if has_label(xml, "Private organizer"):
        tap_visible("Private organizer")
    xml = hierarchy("local-profile-check")
    if not has_label(xml, "Work giver dashboard"):
        tap_visible("Get started")
    wait_for_label("profile-form", "Create your profile")
    fill_input("Your name", "Ali Test")
    fill_input("City", "Lahore")
    tap_visible("Save profile")
    wait_for_label("dashboard", "Work giver dashboard")
    capture("dashboard")
    tap_visible("Workers")
    tap_visible("Add worker")
    wait_for_label("worker-form", "Add worker")
    fill_input("Worker name", "Aslam Test")
    fill_input("Phone number", "03001234567")
    tap_visible("Save worker")
    wait_for_label("worker-saved", "Worker details")
    capture("worker-saved")
    tap_visible("Plan an appointment")
    wait_for_label("job-form", "Add job")
    fill_input("Work address", "Garden Town Lahore")
    tap_visible("Save job")
    wait_for_label("job-saved", "Job details")
    capture("job-saved")
    launch()
    xml = wait_for_screen("local-restart-entry", "en")
    if has_label(xml, "Private organizer"):
        tap_visible("Private organizer")
    wait_for_label("records-restart", "Work giver dashboard")
    tap_visible("Jobs")
    xml = wait_for_label("retained-job", "Aslam Test")
    assert has_label(xml, "Planned"), "Appointment did not persist after process restart"
    capture("retained-job")
    print("PASS: Without a network, created profile/contact/job and retained the appointment after restart.")

try:
    print(adb("install", "-r", str(apk)).strip())
    if arguments.offline:
        # API 24 emulator images have no Wi-Fi service. Cellular data can
        # still be disabled; also disconnect the emulator's virtual radio.
        adb("shell", "svc", "wifi", "disable", check=False)
        adb("shell", "svc", "data", "disable")
        adb("emu", "gsm", "data", "off", check=False)
        (evidence / "connectivity.txt").write_text(
            adb("shell", "dumpsys", "connectivity", check=False), encoding="utf8")
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
    if arguments.exercise_local_flow:
        exercise_local_flow()
finally:
    # Retain diagnostics on failed installs and launches as well as passing runs.
    try:
        hierarchy("final")
        capture("final")
        (evidence / "logcat.txt").write_text(adb("logcat", "-d", check=False), encoding="utf8")
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as diagnostic_error:
        print("Could not collect all diagnostics:", diagnostic_error)
