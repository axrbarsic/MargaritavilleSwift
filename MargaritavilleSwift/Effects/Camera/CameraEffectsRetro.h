#pragma once
#include "CameraEffectsCommon.h"

// Ретро- и арт-эффекты фона «Камера», выбранные по отзывам сообществ:
// ASCII-камеры, 1-бит дизеринг (Obra Dinn), полутон и штриховка (GPUImage),
// ЭЛТ и Game Boy (RetroArch), калейдоскоп и глитч.

namespace camfx {

/// Глиф 5×5, закодированный битами числа (классическая ASCII-схема Shadertoy).
inline float asciiGlyph(int bits, float2 p) {
    float2 cell = floor(p * float2(-4.0, -4.0) + 2.5);
    if (any(cell < 0.0) || any(cell > 4.0)) {
        return 0.0;
    }
    int index = int(cell.x + 5.0 * cell.y);
    return float((bits >> index) & 1);
}

inline float3 ascii(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float cellSize = u.viewSize.x / 56.0 * u.detailScale;
    float2 cellOrigin = floor(pixel / cellSize) * cellSize;
    float3 color = sampleScreen(camera, cellOrigin + cellSize * 0.5, u);
    float gray = luma(color);
    int bits = 4096;                     // .
    if (gray > 0.2) bits = 65600;        // :
    if (gray > 0.3) bits = 163153;       // *
    if (gray > 0.4) bits = 15255086;     // o
    if (gray > 0.5) bits = 13121101;     // &
    if (gray > 0.6) bits = 15252014;     // 8
    if (gray > 0.7) bits = 13195790;     // @
    if (gray > 0.8) bits = 11512810;     // #
    float2 p = fract(pixel / cellSize) * 2.0 - 1.0;
    return min(color * 1.3, 1.0) * asciiGlyph(bits, p);
}

/// 1-бит: упорядоченный дизеринг Байера, стабильный рисунок как у Obra Dinn.
inline float3 dither1Bit(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float dotSize = 3.0 * u.detailScale;
    float2 cell = floor(pixel / dotSize);
    float value = luma(sampleScreen(camera, (cell + 0.5) * dotSize, u));
    value = saturate((value - 0.5) * 1.35 + 0.5);
    const float3 paper = float3(0.93, 0.91, 0.82);
    const float3 ink = float3(0.08, 0.07, 0.11);
    return value > bayer8(uint2(cell)) ? paper : ink;
}

/// Покрытие одного печатного растра CMYK под заданным углом.
inline float halftoneDot(texture2d<float> camera, float2 pixel, CameraEffectUniforms u, float angle, int channel, float cellSize) {
    float2x2 rotation = float2x2(float2(cos(angle), sin(angle)), float2(-sin(angle), cos(angle)));
    float2 rotated = rotation * pixel;
    float2 center = (floor(rotated / cellSize) + 0.5) * cellSize;
    float3 rgb = sampleScreen(camera, transpose(rotation) * center, u);
    float key = 1.0 - max(rgb.r, max(rgb.g, rgb.b));
    float4 cmyk = float4((1.0 - rgb - key) / max(1.0 - key, 0.001), key);
    float radius = sqrt(saturate(cmyk[channel])) * cellSize * 0.62;
    return 1.0 - smoothstep(radius - 1.0, radius + 1.0, length(rotated - center));
}

inline float3 halftone(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float cellSize = u.viewSize.x / 64.0 * u.detailScale;
    float c = halftoneDot(camera, pixel, u, 0.2618, 0, cellSize);
    float m = halftoneDot(camera, pixel, u, 1.3090, 1, cellSize);
    float y = halftoneDot(camera, pixel, u, 0.0, 2, cellSize);
    float k = halftoneDot(camera, pixel, u, 0.7854, 3, cellSize);
    float3 color = float3(0.96, 0.94, 0.88) * (1.0 - float3(c, m, y) * 0.92);
    return color * (1.0 - k * 0.9);
}

/// Экран Game Boy: крупные пиксели, 4 оттенка зелёного и дизеринг.
inline float3 gameBoy(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float block = u.viewSize.x / 128.0 * u.detailScale;
    float2 cell = floor(pixel / block);
    float value = luma(sampleScreen(camera, (cell + 0.5) * block, u));
    value = saturate((value - 0.5) * 1.2 + 0.5);
    float level = clamp(floor(value * 3.0 + (bayer8(uint2(cell)) - 0.5) * 0.9 + 0.5), 0.0, 3.0);
    const float3 palette[4] = {
        float3(0.06, 0.22, 0.06), float3(0.19, 0.38, 0.19),
        float3(0.55, 0.67, 0.06), float3(0.61, 0.74, 0.06)
    };
    float2 inner = fract(pixel / block);
    return palette[int(level)] * (1.0 - step(0.85, max(inner.x, inner.y)) * 0.18);
}

/// ЭЛТ-телевизор: выпуклый экран, сдвиг цветов, строки развёртки и маска триад.
inline float3 crt(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float2 centered = pixel / u.viewSize * 2.0 - 1.0;
    centered *= 1.0 + 0.06 * dot(centered, centered);
    if (any(abs(centered) > 1.0)) {
        return float3(0.0);
    }
    float2 curved = centered * 0.5 + 0.5;
    float jitter = (hash(float2(floor(u.time * 24.0), floor(curved.y * 90.0))) - 0.5) * 0.0015;
    float2 base = curved + float2(jitter, 0.0);
    const float2 shift = float2(0.0025, 0.0);
    float3 color = float3(
        sampleCamera(camera, aspectFill(base + shift, u.viewSize, u.textureSize)).r,
        sampleCamera(camera, aspectFill(base, u.viewSize, u.textureSize)).g,
        sampleCamera(camera, aspectFill(base - shift, u.viewSize, u.textureSize)).b
    );
    float scanline = 0.75 + 0.25 * cos(pixel.y * 2.0944);
    float3 mask = float3(0.85);
    mask[int(pixel.x) % 3] = 1.15;
    float band = exp(-pow((fract(curved.y + u.time * 0.1) - 0.5) * 12.0, 2.0)) * 0.08;
    float vignette = pow(16.0 * curved.x * curved.y * (1.0 - curved.x) * (1.0 - curved.y), 0.25);
    float noise = (hash(pixel + fract(u.time) * 97.0) - 0.5) * 0.04;
    return color * scanline * mask * vignette * 1.15 + band + noise;
}

/// Линия штриховки: 1 на линии, 0 между линиями.
inline float hatchLine(float2 pixel, float spacing, float direction, float offset) {
    float coordinate = pixel.x + direction * pixel.y + offset;
    float distanceToLine = abs(fract(coordinate / spacing + 0.5) - 0.5) * spacing;
    return 1.0 - smoothstep(0.7, 1.5, distanceToLine);
}

/// Карандаш: перекрёстная штриховка по тёмным зонам и контуры.
inline float3 sketch(texture2d<float> camera, float2 uv, float2 pixel, CameraEffectUniforms u) {
    float value = luma(sampleCamera(camera, uv));
    float spacing = 9.0 * u.detailScale;
    float ink = 0.0;
    if (value < 0.85) ink = max(ink, hatchLine(pixel, spacing, 1.0, 0.0));
    if (value < 0.60) ink = max(ink, hatchLine(pixel, spacing, -1.0, 0.0));
    if (value < 0.40) ink = max(ink, hatchLine(pixel, spacing, 1.0, spacing * 0.5));
    if (value < 0.22) ink = max(ink, hatchLine(pixel, spacing, -1.0, spacing * 0.5));
    float edge = smoothstep(0.25, 0.7, sobel(camera, uv, 1.5 / u.textureSize, u.edgeSensitivity));
    ink = max(ink * 0.85, edge);
    return mix(float3(0.95, 0.93, 0.87), float3(0.16, 0.16, 0.20), ink);
}

/// Калейдоскоп из 8 зеркальных секторов, медленно вращается.
inline float3 kaleidoscope(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float scale = min(u.viewSize.x, u.viewSize.y);
    float2 centered = (pixel - u.viewSize * 0.5) / scale;
    const float segment = 6.28318 / 8.0;
    float angle = atan2(centered.y, centered.x) + u.time * 0.15;
    angle = fmod(angle, segment);
    if (angle < 0.0) angle += segment;
    angle = abs(angle - segment * 0.5);
    float2 mapped = float2(cos(angle), sin(angle)) * length(centered);
    return sampleScreen(camera, mapped * scale + u.viewSize * 0.5, u);
}

/// Глитч: сдвиг полос, разделение каналов, вспышки инверсии и шумовые строки.
inline float3 glitch(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float2 screenUV = pixel / u.viewSize;
    float tick = floor(u.time * 7.0);
    float band = floor(screenUV.y * 24.0);
    float trigger = hash(float2(band, tick));
    float shift = trigger > 0.82 ? (hash(float2(tick, band + 7.0)) - 0.5) * 0.12 : 0.0;
    float2 shifted = screenUV + float2(shift, 0.0);
    float split = 0.004 + step(0.9, hash(float2(tick, 3.0))) * 0.012;
    float3 color = float3(
        sampleCamera(camera, aspectFill(shifted + float2(split, 0.0), u.viewSize, u.textureSize)).r,
        sampleCamera(camera, aspectFill(shifted, u.viewSize, u.textureSize)).g,
        sampleCamera(camera, aspectFill(shifted - float2(split, 0.0), u.viewSize, u.textureSize)).b
    );
    if (trigger > 0.96) {
        color = 1.0 - color;
    }
    return color + step(0.995, hash(float2(floor(pixel.y / 2.0), tick))) * 0.5;
}

} // namespace camfx
