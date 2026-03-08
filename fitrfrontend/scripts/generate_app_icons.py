#!/usr/bin/env python3
"""Generate placeholder iOS app icons (default, dark, tinted)."""

from __future__ import annotations

from pathlib import Path
from typing import Tuple

from PIL import Image, ImageDraw

ICON_SIZE = 1024


def hex_to_rgb(value: str) -> Tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def lerp_color(start: Tuple[int, int, int], end: Tuple[int, int, int], t: float) -> Tuple[int, int, int]:
    return tuple(round(start[i] + (end[i] - start[i]) * t) for i in range(3))


def gradient_background(size: int, top_hex: str, bottom_hex: str) -> Image.Image:
    top = hex_to_rgb(top_hex)
    bottom = hex_to_rgb(bottom_hex)
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / (size - 1)
        draw.line((0, y, size, y), fill=lerp_color(top, bottom, t))
    return image


def draw_glow(image: Image.Image, glow_hex: str, alpha: int = 70) -> None:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    size = image.size[0]
    margin = int(size * 0.16)
    draw.ellipse(
        (margin, margin, size - margin, size - margin),
        fill=(*hex_to_rgb(glow_hex), alpha),
    )
    image.alpha_composite(overlay)


def draw_dumbbell(image: Image.Image, glyph_hex: str) -> None:
    size = image.size[0]
    draw = ImageDraw.Draw(image)
    glyph = hex_to_rgb(glyph_hex)

    cx = size // 2
    cy = size // 2

    bar_w = int(size * 0.46)
    bar_h = int(size * 0.10)
    bar_radius = int(bar_h * 0.45)

    left = cx - bar_w // 2
    right = cx + bar_w // 2
    top = cy - bar_h // 2
    bottom = cy + bar_h // 2

    draw.rounded_rectangle((left, top, right, bottom), radius=bar_radius, fill=glyph)

    plate_gap = int(size * 0.02)
    inner_plate_w = int(size * 0.10)
    outer_plate_w = int(size * 0.09)
    plate_h_inner = int(size * 0.30)
    plate_h_outer = int(size * 0.38)
    plate_radius = int(size * 0.03)

    left_inner_right = left - plate_gap
    left_inner_left = left_inner_right - inner_plate_w
    left_outer_right = left_inner_left - plate_gap
    left_outer_left = left_outer_right - outer_plate_w

    right_inner_left = right + plate_gap
    right_inner_right = right_inner_left + inner_plate_w
    right_outer_left = right_inner_right + plate_gap
    right_outer_right = right_outer_left + outer_plate_w

    inner_top = cy - plate_h_inner // 2
    inner_bottom = cy + plate_h_inner // 2
    outer_top = cy - plate_h_outer // 2
    outer_bottom = cy + plate_h_outer // 2

    draw.rounded_rectangle(
        (left_inner_left, inner_top, left_inner_right, inner_bottom),
        radius=plate_radius,
        fill=glyph,
    )
    draw.rounded_rectangle(
        (left_outer_left, outer_top, left_outer_right, outer_bottom),
        radius=plate_radius,
        fill=glyph,
    )
    draw.rounded_rectangle(
        (right_inner_left, inner_top, right_inner_right, inner_bottom),
        radius=plate_radius,
        fill=glyph,
    )
    draw.rounded_rectangle(
        (right_outer_left, outer_top, right_outer_right, outer_bottom),
        radius=plate_radius,
        fill=glyph,
    )


def make_icon(top_hex: str, bottom_hex: str, glyph_hex: str, glow_hex: str) -> Image.Image:
    image = gradient_background(ICON_SIZE, top_hex, bottom_hex).convert("RGBA")
    draw_glow(image, glow_hex)
    draw_dumbbell(image, glyph_hex)
    return image.convert("RGB")


def generate_icons(destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)

    default_icon = make_icon(
        top_hex="#1CCEF1",
        bottom_hex="#0D86CF",
        glyph_hex="#FFFFFF",
        glow_hex="#FFFFFF",
    )
    dark_icon = make_icon(
        top_hex="#18233A",
        bottom_hex="#0B1020",
        glyph_hex="#E8F4FF",
        glow_hex="#50B6FF",
    )
    tinted_icon = make_icon(
        top_hex="#2A2A2A",
        bottom_hex="#0F0F0F",
        glyph_hex="#F5F5F5",
        glow_hex="#A0A0A0",
    )

    default_icon.save(destination / "app-icon-default.png")
    dark_icon.save(destination / "app-icon-dark.png")
    tinted_icon.save(destination / "app-icon-tinted.png")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    output = root / "fitrfrontend" / "Assets.xcassets" / "AppIcon.appiconset"
    generate_icons(output)
    print(f"Generated app icons in {output}")
