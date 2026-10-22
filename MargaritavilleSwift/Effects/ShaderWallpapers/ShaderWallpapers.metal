#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Живые обои: процедурные шейдеры SwiftUI `.colorEffect`.
// Сигнатура: (position, color, size, time). Яркость намеренно приглушена,
// чтобы ячейки комнат поверх фона оставались читаемыми.

namespace wallpaper {

float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = p * 2.03 + float2(17.1, 9.2);
        amplitude *= 0.5;
    }
    return value;
}

float3 palette(float t, float3 a, float3 b, float3 c, float3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

float stars(float2 uv, float density, float time) {
    float2 cell = floor(uv * density);
    float2 local = fract(uv * density) - 0.5;
    float seed = hash21(cell);
    if (seed < 0.92) { return 0.0; }
    float2 offset = float2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5;
    float d = length(local - offset * 0.7);
    float twinkle = 0.6 + 0.4 * sin(time * (1.0 + seed * 3.0) + seed * 40.0);
    return smoothstep(0.08, 0.0, d) * twinkle;
}

} // namespace wallpaper

[[ stitchable ]] half4 wallpaperAurora(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;
    float aspect = size.x / size.y;
    float3 sky = mix(float3(0.01, 0.02, 0.06), float3(0.0, 0.05, 0.10), uv.y);
    sky += wallpaper::stars(float2(uv.x * aspect, uv.y), 70.0, time) * float3(0.8, 0.9, 1.0) * (1.0 - uv.y);

    float3 aurora = float3(0.0);
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float drift = time * (0.05 + fi * 0.02);
        float center = 0.28 + fi * 0.09
            + 0.07 * sin(uv.x * (2.4 + fi) + time * 0.25 + fi * 1.7)
            + 0.12 * (wallpaper::fbm(float2(uv.x * 1.6 + drift, fi * 3.0)) - 0.5);
        float band = exp(-abs(uv.y - center) * (9.0 + fi * 3.0));
        float curtain = wallpaper::fbm(float2(uv.x * 18.0 + fi * 5.0 + drift * 6.0, uv.y * 1.5 - time * 0.15));
        float rays = smoothstep(0.3, 0.9, curtain);
        float3 tint = mix(float3(0.10, 1.00, 0.55), float3(0.55, 0.25, 1.00), clamp((center - uv.y) * 4.0 + fi * 0.3, 0.0, 1.0));
        aurora += tint * band * (0.35 + 0.65 * rays) * (0.55 - fi * 0.12);
    }
    float3 result = sky + aurora * 0.75;
    return half4(half3(min(result, float3(0.85))), 1.0);
}

[[ stitchable ]] half4 wallpaperLiquidNeon(float2 position, half4 color, float2 size, float time) {
    float2 p = (position - 0.5 * size) / size.y * 2.2;
    float t = time * 0.06;
    float2 q = float2(wallpaper::fbm(p + float2(0.0, t)), wallpaper::fbm(p + float2(5.2, 1.3) - t));
    float2 r = float2(
        wallpaper::fbm(p + 3.5 * q + float2(1.7, 9.2) + t * 1.4),
        wallpaper::fbm(p + 3.5 * q + float2(8.3, 2.8) - t * 1.1)
    );
    float f = wallpaper::fbm(p + 3.5 * r);
    float3 neon = wallpaper::palette(
        f + length(r) * 0.6 + time * 0.02,
        float3(0.45, 0.25, 0.55),
        float3(0.45, 0.35, 0.45),
        float3(1.0, 1.0, 1.0),
        float3(0.0, 0.33, 0.67)
    );
    float glow = smoothstep(0.35, 0.85, f);
    float3 result = neon * (0.18 + 0.55 * glow) + float3(0.02, 0.0, 0.04);
    return half4(half3(min(result, float3(0.8))), 1.0);
}

[[ stitchable ]] half4 wallpaperHyperspace(float2 position, half4 color, float2 size, float time) {
    float2 p = (position - 0.5 * size) / size.y;
    float3 result = float3(0.0);
    float nebula = wallpaper::fbm(p * 2.5 + float2(time * 0.02, -time * 0.015));
    result += mix(float3(0.02, 0.0, 0.08), float3(0.0, 0.10, 0.18), nebula) * (0.6 + 0.8 * nebula);

    const int layers = 6;
    for (int i = 0; i < layers; i++) {
        float depth = fract(float(i) / float(layers) + time * 0.06);
        float scale = mix(22.0, 0.6, depth);
        float fade = depth * smoothstep(1.0, 0.85, depth);
        float2 grid = p * scale + float(i) * 37.13;
        float2 cell = floor(grid);
        float2 local = fract(grid) - 0.5;
        float seed = wallpaper::hash21(cell);
        float2 offset = float2(seed, wallpaper::hash21(cell + 11.0)) - 0.5;
        float d = length(local - offset * 0.8);
        float star = 0.012 / max(d, 0.004) * smoothstep(0.5, 0.15, d);
        float3 tint = mix(float3(0.6, 0.8, 1.0), float3(1.0, 0.7, 0.9), wallpaper::hash21(cell + 5.0));
        result += star * fade * tint;
    }
    float core = exp(-length(p) * 5.0);
    result += float3(0.15, 0.25, 0.5) * core * 0.35;
    return half4(half3(min(result, float3(0.9))), 1.0);
}

[[ stitchable ]] half4 wallpaperSynthwave(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;
    float aspect = size.x / size.y;
    float horizon = 0.58;
    float3 result;

    if (uv.y < horizon) {
        float h = uv.y / horizon;
        result = mix(float3(0.04, 0.0, 0.10), float3(0.45, 0.05, 0.35), h * h);
        result += wallpaper::stars(float2(uv.x * aspect, uv.y), 60.0, time) * 0.7 * (1.0 - h);

        float2 sunCenter = float2(0.5, horizon - 0.17);
        float2 d = float2((uv.x - sunCenter.x) * aspect, uv.y - sunCenter.y);
        float radius = 0.24;
        float dist = length(d);
        float stripes = 1.0;
        float below = (uv.y - sunCenter.y) / radius;
        if (below > 0.0) {
            float band = fract(below * 6.0 - time * 0.25);
            stripes = step(below * 0.55, band);
        }
        float sunMask = smoothstep(radius, radius - 0.004, dist) * stripes;
        float3 sun = mix(float3(1.0, 0.85, 0.25), float3(1.0, 0.2, 0.55), clamp((uv.y - (sunCenter.y - radius)) / (2.0 * radius), 0.0, 1.0));
        result = mix(result, sun * 0.85, sunMask);
        result += float3(1.0, 0.3, 0.6) * exp(-max(dist - radius, 0.0) * 14.0) * 0.25;
    } else {
        float depth = 1.0 / max(uv.y - horizon, 0.002);
        float worldX = (uv.x - 0.5) * aspect * depth;
        float worldZ = depth * 0.35 + time * 1.2;
        float lineWidth = 0.035 * depth * 0.12;
        float gx = abs(fract(worldX * 0.5) - 0.5);
        float gz = abs(fract(worldZ) - 0.5);
        float line = max(smoothstep(lineWidth + 0.02, lineWidth, gx), smoothstep(lineWidth + 0.02, lineWidth, gz));
        float fadeOut = clamp((uv.y - horizon) * 4.0, 0.0, 1.0);
        result = float3(0.03, 0.0, 0.07) + float3(1.0, 0.2, 0.8) * line * fadeOut * 0.75;
        result += float3(0.5, 0.1, 0.4) * exp(-(uv.y - horizon) * 18.0) * 0.6;
    }
    return half4(half3(min(result, float3(0.9))), 1.0);
}
