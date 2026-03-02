#!/usr/bin/env python3
"""
Render PNG node icons from a BloodHound OpenGraph extension schema.

Produces colored circles with black Font Awesome icon silhouettes.
Downloads Font Awesome 6 Free Solid SVGs on the fly (cached per run).
"""

import argparse
import json
import math
import os
import sys
import tempfile
from pathlib import Path

import numpy as np
import requests
from PIL import Image, ImageDraw
from svgpathtools import parse_path


# Font Awesome 6 Free Solid SVG CDN base URL
FA_SVG_BASE = "https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/svgs/solid"

# Cache directory for downloaded SVGs
_svg_cache_dir = None


def get_svg_cache_dir():
    global _svg_cache_dir
    if _svg_cache_dir is None:
        _svg_cache_dir = tempfile.mkdtemp(prefix="fa_icons_")
    return _svg_cache_dir


def download_svg(icon_name: str) -> str | None:
    """Download a Font Awesome SVG and return its file path, or None on failure."""
    cache_dir = get_svg_cache_dir()
    cached_path = os.path.join(cache_dir, f"{icon_name}.svg")
    if os.path.exists(cached_path):
        return cached_path

    url = f"{FA_SVG_BASE}/{icon_name}.svg"
    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        with open(cached_path, "w") as f:
            f.write(resp.text)
        return cached_path
    except requests.RequestException as e:
        print(f"  WARNING: Failed to download icon '{icon_name}': {e}")
        return None


def parse_svg_paths(svg_path: str):
    """Extract SVG path data and viewBox from a Font Awesome SVG file."""
    with open(svg_path, "r") as f:
        content = f.read()

    # Extract viewBox
    import re
    vb_match = re.search(r'viewBox="([^"]+)"', content)
    if not vb_match:
        return None, None
    vb = [float(x) for x in vb_match.group(1).split()]

    # Extract all path d attributes
    path_strings = re.findall(r'\bd="([^"]+)"', content)
    return path_strings, vb


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color string to RGB tuple."""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def _line_x_at_y(y, p0, p1):
    """Find x-intercept(s) of a line segment at a given y (scanline)."""
    y0, y1 = p0.imag, p1.imag
    if y0 == y1:
        return []
    if not (min(y0, y1) <= y < max(y0, y1)):
        return []
    t = (y - y0) / (y1 - y0)
    x = p0.real + t * (p1.real - p0.real)
    return [x]


def _cubic_x_at_y(y, seg):
    """Find x-intercept(s) of a cubic bezier at a given y (scanline)."""
    # B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
    p0y = seg.start.imag
    p1y = seg.control1.imag
    p2y = seg.control2.imag
    p3y = seg.end.imag

    # Coefficients of the cubic in t: a*t^3 + b*t^2 + c*t + d = y
    a = -p0y + 3*p1y - 3*p2y + p3y
    b = 3*p0y - 6*p1y + 3*p2y
    c = -3*p0y + 3*p1y
    d = p0y - y

    roots = np.roots([a, b, c, d])
    xs = []
    for root in roots:
        if np.iscomplex(root) and abs(root.imag) > 1e-6:
            continue
        t = root.real
        if -1e-6 <= t < 1.0 - 1e-6:
            t = max(0.0, t)
            pt = seg.point(t)
            xs.append(pt.real)
    return xs


def _quad_x_at_y(y, seg):
    """Find x-intercept(s) of a quadratic bezier at a given y (scanline)."""
    p0y = seg.start.imag
    p1y = seg.control.imag
    p2y = seg.end.imag

    a = p0y - 2*p1y + p2y
    b = -2*p0y + 2*p1y
    c = p0y - y

    if abs(a) < 1e-10:
        if abs(b) < 1e-10:
            return []
        t = -c / b
        if -1e-6 <= t < 1.0 - 1e-6:
            t = max(0.0, t)
            return [seg.point(t).real]
        return []

    disc = b*b - 4*a*c
    if disc < 0:
        return []

    xs = []
    for sign in [1, -1]:
        t = (-b + sign * math.sqrt(disc)) / (2*a)
        if -1e-6 <= t < 1.0 - 1e-6:
            t = max(0.0, t)
            xs.append(seg.point(t).real)
    return xs


def _arc_x_at_y(y, seg, num_subdivisions=64):
    """Find x-intercept(s) of an arc at a given y (scanline) via linear subdivision."""
    xs = []
    prev = seg.point(0)
    for i in range(1, num_subdivisions + 1):
        t = i / num_subdivisions
        cur = seg.point(t)
        result = _line_x_at_y(y, prev, cur)
        xs.extend(result)
        prev = cur
    return xs


def scanline_fill(path, scale, off_x, off_y, width, height):
    """
    Rasterize an SVG path using scanline rendering with even-odd fill rule.

    For each row y, finds all x-intersections with path segments, sorts them,
    and fills between pairs (even-odd rule).  Returns a numpy uint8 mask.
    """
    from svgpathtools import Line, CubicBezier, QuadraticBezier, Arc

    mask = np.zeros((height, width), dtype=np.uint8)

    # Transform segments to screen coordinates
    transformed_segs = []
    for seg in path:
        if isinstance(seg, Line):
            s = complex(seg.start.real * scale + off_x, seg.start.imag * scale + off_y)
            e = complex(seg.end.real * scale + off_x, seg.end.imag * scale + off_y)
            transformed_segs.append(("line", s, e))
        elif isinstance(seg, CubicBezier):
            new_seg = CubicBezier(
                complex(seg.start.real * scale + off_x, seg.start.imag * scale + off_y),
                complex(seg.control1.real * scale + off_x, seg.control1.imag * scale + off_y),
                complex(seg.control2.real * scale + off_x, seg.control2.imag * scale + off_y),
                complex(seg.end.real * scale + off_x, seg.end.imag * scale + off_y),
            )
            transformed_segs.append(("cubic", new_seg))
        elif isinstance(seg, QuadraticBezier):
            new_seg = QuadraticBezier(
                complex(seg.start.real * scale + off_x, seg.start.imag * scale + off_y),
                complex(seg.control.real * scale + off_x, seg.control.imag * scale + off_y),
                complex(seg.end.real * scale + off_x, seg.end.imag * scale + off_y),
            )
            transformed_segs.append(("quad", new_seg))
        elif isinstance(seg, Arc):
            # Linearize arcs for transformation
            transformed_segs.append(("arc", seg, scale, off_x, off_y))

    for row_y in range(height):
        y = row_y + 0.5  # sample at pixel center
        x_crossings = []

        for item in transformed_segs:
            if item[0] == "line":
                x_crossings.extend(_line_x_at_y(y, item[1], item[2]))
            elif item[0] == "cubic":
                x_crossings.extend(_cubic_x_at_y(y, item[1]))
            elif item[0] == "quad":
                x_crossings.extend(_quad_x_at_y(y, item[1]))
            elif item[0] == "arc":
                seg, sc, ox, oy = item[1], item[2], item[3], item[4]
                # Sample arc in original coordinates, transform crossings
                for sub_i in range(64):
                    t0 = sub_i / 64
                    t1 = (sub_i + 1) / 64
                    p0 = seg.point(t0)
                    p1 = seg.point(t1)
                    p0t = complex(p0.real * sc + ox, p0.imag * sc + oy)
                    p1t = complex(p1.real * sc + ox, p1.imag * sc + oy)
                    x_crossings.extend(_line_x_at_y(y, p0t, p1t))

        if not x_crossings:
            continue

        x_crossings.sort()

        # Even-odd fill: fill between pairs
        for i in range(0, len(x_crossings) - 1, 2):
            x_start = max(0, int(math.floor(x_crossings[i])))
            x_end = min(width, int(math.ceil(x_crossings[i + 1])))
            if x_start < x_end:
                mask[row_y, x_start:x_end] = 255

    return mask


def render_icon(icon_name: str, color: str, size: int, supersample: int = 4) -> Image.Image | None:
    """
    Render a node icon: colored circle with black border, black FA icon silhouette.

    Uses supersampled scanline rendering with even-odd fill for correct
    handling of compound SVG paths (shapes with cutouts/holes).
    """
    svg_path = download_svg(icon_name)
    if svg_path is None:
        return None

    path_strings, viewbox = parse_svg_paths(svg_path)
    if not path_strings or not viewbox:
        print(f"  WARNING: Could not parse SVG for icon '{icon_name}'")
        return None

    # Supersample dimensions
    ss = size * supersample
    img = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw filled circle with color
    fill_rgb = hex_to_rgb(color)
    border_width = max(2, ss // 40)
    draw.ellipse(
        [border_width // 2, border_width // 2, ss - border_width // 2 - 1, ss - border_width // 2 - 1],
        fill=fill_rgb,
        outline=(0, 0, 0),
        width=border_width,
    )

    # Rasterize the Font Awesome icon paths onto the circle
    vb_x, vb_y, vb_w, vb_h = viewbox

    # Target the icon to fill ~55% of the circle, centered
    icon_target = ss * 0.55
    scale = icon_target / max(vb_w, vb_h)

    # Center offset
    icon_actual_w = vb_w * scale
    icon_actual_h = vb_h * scale
    off_x = (ss - icon_actual_w) / 2 - vb_x * scale
    off_y = (ss - icon_actual_h) / 2 - vb_y * scale

    # Parse all path data into one combined path and scanline-rasterize
    combined_path = None
    for path_str in path_strings:
        try:
            p = parse_path(path_str)
            if combined_path is None:
                combined_path = p
            else:
                combined_path.extend(p)
        except Exception:
            continue

    if combined_path is None or len(combined_path) == 0:
        print(f"  WARNING: No valid path segments for icon '{icon_name}'")
        return None

    mask_array = scanline_fill(combined_path, scale, off_x, off_y, ss, ss)

    # Apply the icon mask as black pixels
    img_array = np.array(img)
    black_mask = mask_array > 127
    img_array[black_mask, 0] = 0  # R
    img_array[black_mask, 1] = 0  # G
    img_array[black_mask, 2] = 0  # B

    img = Image.fromarray(img_array)

    # Downsample with high-quality resampling
    img = img.resize((size, size), Image.LANCZOS)
    return img


def main():
    parser = argparse.ArgumentParser(description="Render BloodHound OpenGraph node icons")
    parser.add_argument("--schema", default="schema.json", help="Path to schema.json")
    parser.add_argument("--output", default="Documentation/Icons", help="Output directory")
    parser.add_argument("--prefix", default="", help="Filename prefix")
    parser.add_argument("--size", type=int, default=220, help="Output icon size in pixels")
    args = parser.parse_args()

    # Load schema
    schema_path = Path(args.schema)
    if not schema_path.exists():
        print(f"ERROR: Schema file not found: {schema_path}")
        sys.exit(1)

    with open(schema_path) as f:
        schema = json.load(f)

    node_kinds = schema.get("node_kinds", [])
    if not node_kinds:
        print("ERROR: No node_kinds found in schema")
        sys.exit(1)

    # Create output directory
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    rendered = 0
    skipped = 0
    errors = 0

    print(f"Rendering {len(node_kinds)} node icons to {output_dir}/")
    print(f"  Prefix: '{args.prefix}', Size: {args.size}px")
    print()

    for nk in node_kinds:
        name = nk["name"]
        icon = nk.get("icon", "placeholder")
        color = nk.get("color", "#000000")

        if icon == "placeholder" or color == "#000000":
            print(f"  SKIP: {name} (placeholder icon/color)")
            skipped += 1
            continue

        print(f"  Rendering {name} (icon={icon}, color={color})...", end=" ")

        img = render_icon(icon, color, args.size)
        if img is None:
            print("FAILED")
            errors += 1
            continue

        out_path = output_dir / f"{args.prefix}{name}.png"
        img.save(str(out_path), "PNG")
        print(f"OK -> {out_path}")
        rendered += 1

    print()
    print(f"Summary: {rendered} rendered, {skipped} skipped, {errors} errors")

    # Check for stale icons
    existing = set(output_dir.glob(f"{args.prefix}*.png"))
    expected = {output_dir / f"{args.prefix}{nk['name']}.png" for nk in node_kinds
                if nk.get("icon", "placeholder") != "placeholder" and nk.get("color", "#000000") != "#000000"}
    stale = existing - expected
    if stale:
        print(f"\nStale icon files ({len(stale)}):")
        for s in sorted(stale):
            print(f"  {s}")


if __name__ == "__main__":
    main()
