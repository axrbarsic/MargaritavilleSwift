#pragma once
#include "CameraEffectsCommon.h"

// Семейство «Неон-контуров»: всё строится на контурах (оператор Собеля).
// Неоновая тень (TikTok Neon Shadow), неон-свечение, Трон, чертёж, мел,
// электричество и тиснение.

namespace camfx {

/// Градиент яркости по Собелю: направление и сила контура.
inline float2 sobelVector(texture2d<float> camera, float2 uv, float2 texel) {
    float tl = luma(sampleCamera(camera, uv + texel * float2(-1.0, -1.0)));
    float t = luma(sampleCamera(camera, uv + texel * float2(0.0, -1.0)));
    float tr = luma(sampleCamera(camera, uv + texel * float2(1.0, -1.0)));
    float l = luma(sampleCamera(camera, uv + texel * float2(-1.0, 0.0)));
    float r = luma(sampleCamera(camera, uv + texel * float2(1.0, 0.0)));
    float bl = luma(sampleCamera(camera, uv + texel * float2(-1.0, 1.0)));
    float b = luma(sampleCamera(camera, uv + texel * float2(0.0, 1.0)));
    float br = luma(sampleCamera(camera, uv + texel * float2(1.0, 1.0)));
    return float2(-tl - 2.0 * l - bl + tr + 2.0 * r + br, -tl - 2.0 * t - tr + bl + 2.0 * b + br);
}

inline float edgeMask(texture2d<float> camera, float2 uv, float2 texel, float radius, float low, float high, float gain) {
    return smoothstep(low, high, sobel(camera, uv, texel * radius, gain));
}

/// Неоновая тень: три цветных копии контура расходятся и сходятся, как в TikTok.
inline float3 neonShadow(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float spread = 0.013 + 0.007 * sin(u.time * 1.3);
    float angle = u.time * 0.8;
    float2 offsetA = float2(cos(angle), sin(angle)) * spread;
    float2 offsetB = float2(cos(angle + 2.094), sin(angle + 2.094)) * spread;
    float3 color = sampleCamera(camera, uv) * 0.08;
    color += float3(1.0, 0.15, 0.6) * edgeMask(camera, uv + offsetA, texel, 1.6, 0.12, 0.5, u.edgeSensitivity);
    color += float3(0.1, 0.9, 1.0) * edgeMask(camera, uv + offsetB, texel, 1.6, 0.12, 0.5, u.edgeSensitivity);
    color += float3(1.0, 0.95, 0.3) * edgeMask(camera, uv, texel, 1.6, 0.12, 0.5, u.edgeSensitivity);
    return color;
}

/// Неон-свечение: чёткая линия и широкий ореол из контуров крупного масштаба.
inline float3 neonGlow(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float core = edgeMask(camera, uv, texel, 1.5, 0.12, 0.5, u.edgeSensitivity);
    float halo = edgeMask(camera, uv, texel, 5.0, 0.1, 0.6, u.edgeSensitivity) * 0.5 + edgeMask(camera, uv, texel, 12.0, 0.1, 0.7, u.edgeSensitivity) * 0.3;
    float3 tint = hue(fract(uv.x * 0.4 + uv.y * 0.25 + u.time * 0.05));
    return tint * (core * 1.3 + halo) + float3(1.0) * core * 0.35;
}

/// Трон: голубые и оранжевые контуры по направлению линии и тёмная сетка пола.
inline float3 tron(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, CameraEffectUniforms u) {
    float2 gradient = sobelVector(camera, uv, texel * 1.5);
    float edge = smoothstep(0.12, 0.5, length(gradient) * u.edgeSensitivity);
    float horizontal = abs(gradient.y) / (abs(gradient.x) + abs(gradient.y) + 1e-4);
    float3 line = mix(float3(0.1, 0.85, 1.0), float3(1.0, 0.55, 0.1), step(0.6, horizontal));
    float cell = u.viewSize.x / 14.0;
    float2 offset = abs(fract(pixel / cell + 0.5) - 0.5) * cell;
    float grid = (1.0 - smoothstep(0.0, 1.2, min(offset.x, offset.y))) * 0.12;
    float halo = edgeMask(camera, uv, texel, 6.0, 0.1, 0.6, u.edgeSensitivity) * 0.35;
    return float3(0.0, 0.02, 0.05) + float3(0.1, 0.5, 0.7) * grid + line * (edge * 1.2 + halo);
}

/// Чертёж: белые линии на синем листе с миллиметровой сеткой.
inline float3 blueprint(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, CameraEffectUniforms u) {
    float edge = edgeMask(camera, uv, texel, 1.4, 0.1, 0.35, u.edgeSensitivity);
    float fine = u.viewSize.x / 48.0 * u.detailScale;
    float coarse = fine * 6.0;
    float2 fineOffset = abs(fract(pixel / fine + 0.5) - 0.5) * fine;
    float2 coarseOffset = abs(fract(pixel / coarse + 0.5) - 0.5) * coarse;
    float grid = (1.0 - smoothstep(0.0, 1.0, min(fineOffset.x, fineOffset.y))) * 0.12
        + (1.0 - smoothstep(0.0, 1.4, min(coarseOffset.x, coarseOffset.y))) * 0.22;
    float3 paper = float3(0.05, 0.22, 0.48);
    return paper + float3(0.85, 0.92, 1.0) * max(grid, edge * 0.95);
}

/// Мел: рваные белые штрихи по контурам на тёмно-зелёной доске.
inline float3 chalk(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, float gain) {
    float edge = edgeMask(camera, uv, texel, 1.8, 0.12, 0.45, gain);
    float grain = hash(floor(pixel / 2.0));
    float breakup = step(0.35, grain);
    float dust = hash(floor(pixel / 3.0) + 17.0) * 0.06;
    float3 board = float3(0.13, 0.22, 0.18) + dust;
    return mix(board, float3(0.93, 0.95, 0.9), edge * breakup * 0.95);
}

/// Электричество: дрожащие фиолетовые разряды с белой сердцевиной.
inline float3 electric(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float tick = floor(u.time * 20.0);
    float2 jitter = (float2(hash(floor(uv * 60.0) + tick), hash(floor(uv * 60.0) + tick + 5.0)) - 0.5) * 0.004;
    float core = edgeMask(camera, uv + jitter, texel, 1.4, 0.15, 0.45, u.edgeSensitivity);
    float halo = edgeMask(camera, uv, texel, 6.0, 0.1, 0.6, u.edgeSensitivity);
    float flicker = 0.75 + 0.25 * hash(float2(tick, 2.0));
    return (float3(0.45, 0.25, 1.0) * halo * 0.7 + float3(0.85, 0.9, 1.0) * core) * flicker;
}

/// Тиснение: рельеф, как будто кадр выдавлен в металле.
inline float3 emboss(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float2 offset = -float2(cos(u.lightAngle), sin(u.lightAngle)) * texel * 2.83;
    float relief = luma(sampleCamera(camera, uv - offset)) - luma(sampleCamera(camera, uv + offset));
    float value = saturate(0.5 + relief * 2.5 * u.reliefDepth);
    return float3(value) * float3(0.92, 0.9, 0.86);
}

} // namespace camfx
