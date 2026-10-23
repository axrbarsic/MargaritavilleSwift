#pragma once
#include "CameraEffectsCommon.h"
#include "CameraEffectsRetro.h"

// Вирусные эффекты фона «Камера»: скан времени TikTok и шлейф (с историей
// кадров), матричный дождь, анаглиф, рентген, вейпорвейв, зеркало, голограмма.

namespace camfx {

/// Скан времени: выше линии — замороженная история, сама линия светится синим.
inline float3 timeScan(texture2d<float> history, float2 screenUV, CameraEffectUniforms u) {
    float3 color = history.sample(linearSampler, screenUV).rgb;
    if (u.scanLine < 1.0) {
        float distanceToLine = abs(screenUV.y - u.scanLine) * u.viewSize.y;
        color += float3(0.15, 0.55, 1.0) * exp(-distanceToLine * 0.22) * 1.4;
    }
    return color;
}

/// Глиф цифрового дождя: случайный символ, меняется со временем.
inline int matrixGlyph(float2 cell, float time) {
    const int glyphs[8] = { 15255086, 13121101, 15252014, 13195790, 11512810, 163153, 4329604, 32570911 };
    return glyphs[int(hash(cell + floor(time * 4.0 + hash(cell) * 10.0)) * 7.99)];
}

inline float3 matrixRain(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float cellSize = u.viewSize.x / 44.0;
    float2 cell = floor(pixel / cellSize);
    float value = luma(sampleScreen(camera, (cell + 0.5) * cellSize, u));
    float columns = u.viewSize.y / cellSize;
    float speed = 6.0 + hash(float2(cell.x, 1.0)) * 10.0;
    float head = fract(u.time * speed / columns + hash(float2(cell.x, 7.0))) * (columns + 12.0);
    float trail = cell.y <= head ? exp(-(head - cell.y) * 0.18) : 0.0;
    float brightness = saturate(value * 1.4) * (0.25 + trail * 1.2);
    float glyph = asciiGlyph(matrixGlyph(cell, u.time), fract(pixel / cellSize) * 2.0 - 1.0);
    float3 green = float3(0.15, 1.0, 0.35);
    float3 headColor = float3(0.85, 1.0, 0.9);
    float isHead = step(abs(cell.y - floor(head)), 0.5);
    return mix(green, headColor, isHead) * glyph * brightness;
}

/// Красно-голубой анаглиф для 3D-очков.
inline float3 anaglyph(texture2d<float> camera, float2 uv) {
    const float2 offset = float2(0.008, 0.0);
    float3 left = sampleCamera(camera, uv - offset);
    float3 right = sampleCamera(camera, uv + offset);
    return float3(luma(left) * 1.1, right.g, right.b);
}

/// Рентген: инверсия яркости в холодных тонах и светящиеся контуры.
inline float3 xray(texture2d<float> camera, float2 uv, float2 texel) {
    float inverse = 1.0 - luma(sampleCamera(camera, uv));
    float edge = smoothstep(0.1, 0.6, sobel(camera, uv, texel * 1.5));
    return float3(0.55, 0.82, 1.0) * pow(inverse, 1.6) * 0.9 + float3(0.6, 0.9, 1.0) * edge * 0.6;
}

/// Вейпорвейв: градиентная карта фиолетовый → розовый → бирюзовый и развёртка.
inline float3 vaporwave(texture2d<float> camera, float2 uv, float2 pixel) {
    float value = luma(sampleCamera(camera, uv));
    const float3 stops[4] = {
        float3(0.10, 0.02, 0.22), float3(0.85, 0.15, 0.62),
        float3(0.20, 0.85, 0.95), float3(1.0, 0.92, 0.98)
    };
    float t = saturate(value) * 3.0;
    int index = min(int(floor(t)), 2);
    float3 color = mix(stops[index], stops[index + 1], t - float(index));
    return color * (0.9 + 0.1 * cos(pixel.y * 2.0944));
}

/// Зеркало: правая половина повторяет левую.
inline float3 mirror(texture2d<float> camera, float2 screenUV, CameraEffectUniforms u) {
    float2 mirrored = float2(screenUV.x > 0.5 ? 1.0 - screenUV.x : screenUV.x, screenUV.y);
    return sampleCamera(camera, aspectFill(mirrored, u.viewSize, u.textureSize));
}

/// Голограмма: синее свечение, бегущие строки, мерцание и контуры.
inline float3 hologram(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, CameraEffectUniforms u) {
    float value = luma(sampleCamera(camera, uv));
    float edge = smoothstep(0.1, 0.5, sobel(camera, uv, texel * 1.5));
    float lines = 0.65 + 0.35 * step(0.5, fract(pixel.y / 4.0 - u.time * 2.0));
    float sweep = exp(-abs(fract(uv.y - u.time * 0.15) - 0.5) * 30.0) * 0.4;
    float flicker = 0.92 + 0.08 * hash(float2(floor(u.time * 20.0), 1.0));
    float3 tint = float3(0.25, 0.75, 1.0);
    return (tint * value * lines + tint * edge * 0.8 + tint * sweep) * flicker;
}

} // namespace camfx
