#pragma once
#include "CameraEffectsCommon.h"

// «Мультфильм» (абстракция видео по Winnemöller et al., SIGGRAPH 2006:
// сглаживание с сохранением краёв + мягкое квантование яркости + контуры)
// и «Лего» (мир из кубиков с шипами в палитре настоящих деталей).

namespace camfx {

/// Мультфильм: кадр уже прошёл медианный фильтр MPS (сглаживание с краями).
inline float3 cartoon(texture2d<float> smoothed, float2 uv, float2 texel, float gain) {
    float3 color = sampleCamera(smoothed, uv);
    float value = max(luma(color), 0.001);
    // Квантование яркости на 4 заметные ступени с узким сглаженным переходом.
    const float levels = 4.0;
    float nearest = floor(value * levels + 0.5) / levels;
    float quantized = nearest + tanh((value - nearest) * 60.0) / (2.0 * levels);
    color = saturate(color * (max(quantized, 0.08) / value));
    // Заливки как в анимации: оттенок упрощается до 8 уровней на канал.
    color = floor(color * 8.0 + 0.5) / 8.0;
    // Сочнее цвета.
    color = saturate(mix(float3(luma(color)), color, 1.6));
    // Толстые мягкие контуры.
    float edge = smoothstep(0.08, 0.22, sobel(smoothed, uv, texel * 2.5, gain));
    return mix(color, float3(0.04, 0.03, 0.05), edge);
}

/// Ближайший цвет из палитры стандартных Лего-деталей.
inline float3 legoColor(float3 color) {
    const float3 palette[16] = {
        float3(0.95, 0.95, 0.95), float3(0.11, 0.16, 0.20), float3(0.77, 0.16, 0.11), float3(0.05, 0.41, 0.67),
        float3(0.96, 0.80, 0.18), float3(0.16, 0.50, 0.27), float3(0.29, 0.59, 0.29), float3(0.85, 0.52, 0.25),
        float3(0.39, 0.37, 0.38), float3(0.64, 0.64, 0.64), float3(0.84, 0.77, 0.60), float3(0.41, 0.25, 0.15),
        float3(0.13, 0.23, 0.34), float3(0.91, 0.73, 0.78), float3(0.64, 0.74, 0.27), float3(0.21, 0.68, 0.75)
    };
    const float3 weights = float3(0.30, 0.59, 0.11);
    float3 best = palette[0];
    float bestDistance = 1e9;
    for (int index = 0; index < 16; index++) {
        float3 delta = (color - palette[index]) * weights;
        float distance = dot(delta, delta);
        if (distance < bestDistance) {
            bestDistance = distance;
            best = palette[index];
        }
    }
    return best;
}

/// Лего: каждый блок — кубик 1×1 с фаской и шипом, свет сверху слева.
inline float3 lego(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    float block = u.viewSize.x / 28.0 * u.detailScale;
    float2 cell = floor(pixel / block);
    float3 base = legoColor(sampleScreen(camera, (cell + 0.5) * block, u));
    float2 local = fract(pixel / block) - 0.5;

    // Фаска кубика: верх и лево светлее, низ и право темнее, шов между кубиками.
    float edge = max(abs(local.x), abs(local.y));
    float bevel = smoothstep(0.40, 0.47, edge);
    float side = (abs(local.x) > abs(local.y) ? local.x : local.y) > 0.0 ? -0.28 : 0.16;
    float3 color = base * (1.0 + bevel * side);
    color *= 1.0 - smoothstep(0.47, 0.5, edge) * 0.55;

    // Шип: тень снизу справа, освещённый верх и блик.
    const float studRadius = 0.27;
    float shadow = 1.0 - smoothstep(studRadius - 0.03, studRadius + 0.03, length(local - float2(0.06, 0.07)));
    color *= 1.0 - shadow * 0.32;
    float stud = 1.0 - smoothstep(studRadius - 0.015, studRadius + 0.015, length(local));
    float rim = smoothstep(studRadius - 0.07, studRadius, length(local)) * stud;
    float facing = dot(normalize(local + 1e-4), float2(-0.707, -0.707));
    float3 studColor = base * (1.06 + rim * facing * 0.35);
    float highlight = 1.0 - smoothstep(0.0, 0.07, length(local - float2(-0.1, -0.1)));
    studColor += highlight * 0.35;
    return mix(color, studColor, stud);
}

} // namespace camfx
