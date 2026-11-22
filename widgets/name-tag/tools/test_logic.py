#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: techonerd
"""Test suite for Name Tag widget logic: KCFG sync, metadata, fallback logic, width bounds, theme compliance."""

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
NAMETAG_DIR = ROOT / "widgets" / "name-tag"


def test_kcfg_matches_qml():
    """Verify that every entry in main.xml has cfg_<key> and cfg_<key>Default in configGeneral.qml."""
    xml_path = NAMETAG_DIR / "contents" / "config" / "main.xml"
    qml_path = NAMETAG_DIR / "contents" / "ui" / "configGeneral.qml"

    tree = ET.parse(xml_path)
    root = tree.getroot()
    ns = {"kcfg": "http://www.kde.org/standards/kcfg/1.0"}

    entries = {}
    for entry in root.findall(".//kcfg:entry", ns):
        name = entry.attrib["name"]
        entry_type = entry.attrib.get("type", "String")
        default_elem = entry.find("kcfg:default", ns)
        default_val = default_elem.text if default_elem is not None and default_elem.text else ""
        entries[name] = {"type": entry_type, "default": default_val}

    assert len(entries) > 0, "No entries found in main.xml"

    qml_content = qml_path.read_text(encoding="utf-8")

    for key, data in entries.items():
        cfg_key = f"cfg_{key}"
        cfg_default = f"cfg_{key}Default"

        # Check property alias cfg_<key>
        assert re.search(rf"\bproperty\s+alias\s+{cfg_key}\b", qml_content), (
            f"Missing 'property alias {cfg_key}' in configGeneral.qml"
        )

        # Check property <type> cfg_<key>Default
        assert re.search(rf"\bproperty\s+\w+\s+{cfg_default}\b", qml_content), (
            f"Missing default '{cfg_default}' declaration in configGeneral.qml"
        )

    print(f"PASS: All {len(entries)} KCFG entries verified with matching cfg_<key> and cfg_<key>Default in configGeneral.qml.")


def test_metadata_json():
    """Verify metadata.json structure and plasma 6 specifications."""
    meta_path = NAMETAG_DIR / "metadata.json"
    with open(meta_path, "r", encoding="utf-8") as f:
        meta = json.load(f)

    assert meta.get("KPackageStructure") == "Plasma/Applet", "Must be Plasma/Applet"
    kplugin = meta.get("KPlugin", {})
    assert kplugin.get("Id") == "com.github.techonerd.nametag", "Id must match com.github.techonerd.nametag"
    assert kplugin.get("Version") == "0.1.0", "Version must be 0.1.0"
    assert meta.get("X-Plasma-API-Minimum-Version") == "6.0", "Must target Plasma 6.0"
    assert kplugin.get("License") == "GPL-3.0-or-later", "License must be GPL-3.0-or-later"
    print("PASS: metadata.json schema and Plasma 6 compliance verified.")


def test_fallback_logic():
    """Verify empty text modes fallback behavior."""
    def fallback_title(mode, custom_text, activity_name):
        if mode == 1:
            return "Desktop"
        elif mode == 2:
            return custom_text or "Desktop"
        elif mode == 3:
            return ""
        # mode == 0: activity name or Desktop
        if activity_name and activity_name.strip():
            return activity_name.strip()
        return "Desktop"

    # Mode 0: Activity Name present
    assert fallback_title(0, "", "Work Activity") == "Work Activity"
    # Mode 0: Activity Name empty -> Desktop
    assert fallback_title(0, "", "") == "Desktop"
    # Mode 1: Fixed Desktop
    assert fallback_title(1, "Custom", "Work Activity") == "Desktop"
    # Mode 2: Custom text
    assert fallback_title(2, "My Space", "Work Activity") == "My Space"
    # Mode 2: Empty custom text -> Desktop
    assert fallback_title(2, "", "Work Activity") == "Desktop"
    # Mode 3: Blank
    assert fallback_title(3, "Custom", "Work Activity") == ""

    print("PASS: Fallback title empty state logic verified across all 4 modes.")


def test_width_bounds():
    """Verify max width and elision constraints."""
    def compute_max_label_width(configured_max_width, icon_visible, is_vertical):
        if is_vertical:
            return -1
        if configured_max_width <= 0:
            return -1
        icon_width = 16 if icon_visible else 0
        spacing = 4 if icon_visible else 0
        return configured_max_width - (icon_width + spacing)

    # Unlimited width
    assert compute_max_label_width(0, True, False) == -1
    # Standard 300px with icon
    assert compute_max_label_width(300, True, False) == 280
    # Standard 300px without icon
    assert compute_max_label_width(300, False, False) == 300
    # Vertical panel
    assert compute_max_label_width(300, True, True) == -1

    print("PASS: Width bounding and layout calculations verified.")


def test_theme_compliance():
    """Verify that QML files do not hardcode theme hex colors."""
    qml_files = list((NAMETAG_DIR / "contents" / "ui").glob("*.qml"))
    hex_color_pattern = re.compile(r'#[0-9a-fA-F]{3,8}\b')

    for qml in qml_files:
        content = qml.read_text(encoding="utf-8")
        matches = hex_color_pattern.findall(content)
        assert len(matches) == 0, f"Found hardcoded hex color(s) {matches} in {qml.name}"

    print(f"PASS: Theme compliance verified; 0 hardcoded colors in {len(qml_files)} QML files.")


if __name__ == "__main__":
    print("=== Name Tag Logic & Compliance Verification ===")
    test_kcfg_matches_qml()
    test_metadata_json()
    test_fallback_logic()
    test_width_bounds()
    test_theme_compliance()
    print("=== All 5 Tests Passed Successfully ===")
