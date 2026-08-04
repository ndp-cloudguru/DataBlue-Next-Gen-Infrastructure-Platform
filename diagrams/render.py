#!/usr/bin/env python3
"""
Mermaid Diagram Extractor & Renderer for BlueData Platform Architecture Review
Usage:
    python3 diagrams/render.py          # Extract and render SVG/PNG diagrams
    python3 diagrams/render.py --svg    # Render SVG only
    python3 diagrams/render.py --png    # Render PNG only
"""

import os
import sys
import glob
import re
import subprocess

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DOCS_DIR = os.path.join(REPO_ROOT, "docs")
DIAGRAMS_DIR = os.path.join(REPO_ROOT, "diagrams")
SRC_DIR = os.path.join(DIAGRAMS_DIR, "src")
SVG_DIR = os.path.join(DIAGRAMS_DIR, "svg")
PNG_DIR = os.path.join(DIAGRAMS_DIR, "png")

def ensure_dirs():
    os.makedirs(SRC_DIR, exist_ok=True)
    os.makedirs(SVG_DIR, exist_ok=True)
    os.makedirs(PNG_DIR, exist_ok=True)

def extract_diagrams():
    """Extract all mermaid blocks from docs/en/ into .mmd files in diagrams/src/"""
    print("[1/2] Extracting Mermaid blocks from markdown docs...")
    pattern = re.compile(r'```mermaid\n(.*?)```', re.DOTALL)
    en_files = sorted(glob.glob(os.path.join(DOCS_DIR, "en", "*.md")))
    
    count = 0
    for file_path in en_files:
        basename = os.path.basename(file_path)
        doc_id = basename.split("_")[0]
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        matches = pattern.findall(content)
        for idx, code in enumerate(matches, 1):
            count += 1
            name = f"{doc_id}_diagram_{idx}"
            mmd_path = os.path.join(SRC_DIR, f"{name}.mmd")
            with open(mmd_path, "w", encoding="utf-8") as f_out:
                f_out.write(code.strip() + "\n")
            print(f"  - Extracted: {name}.mmd from {basename}")
    
    print(f"  Total extracted: {count} diagrams.")

def render_diagrams(render_svg=True, render_png=True):
    """Render all .mmd files in diagrams/src/ to SVG and PNG using @mermaid-js/mermaid-cli"""
    print("\n[2/2] Rendering diagrams using @mermaid-js/mermaid-cli...")
    mmd_files = sorted(glob.glob(os.path.join(SRC_DIR, "*.mmd")))
    
    if not mmd_files:
        print("  No .mmd files found to render.")
        return
        
    for mmd_path in mmd_files:
        name = os.path.splitext(os.path.basename(mmd_path))[0]
        
        if render_svg:
            svg_path = os.path.join(SVG_DIR, f"{name}.svg")
            print(f"  - Rendering SVG: {name}.svg")
            subprocess.run([
                "npx", "-y", "@mermaid-js/mermaid-cli",
                "-i", mmd_path,
                "-o", svg_path,
                "-b", "white"
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        if render_png:
            png_path = os.path.join(PNG_DIR, f"{name}.png")
            print(f"  - Rendering PNG: {name}.png")
            subprocess.run([
                "npx", "-y", "@mermaid-js/mermaid-cli",
                "-i", mmd_path,
                "-o", png_path,
                "-b", "white",
                "-s", "2"
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print("  Rendering complete.")

if __name__ == "__main__":
    ensure_dirs()
    extract_diagrams()
    
    svg_only = "--svg" in sys.argv
    png_only = "--png" in sys.argv
    
    if svg_only:
        render_diagrams(render_svg=True, render_png=False)
    elif png_only:
        render_diagrams(render_svg=False, render_png=True)
    else:
        render_diagrams(render_svg=True, render_png=True)
        
    print("\n[SUCCESS] Diagram extraction and rendering completed without modifying Markdown files!")
