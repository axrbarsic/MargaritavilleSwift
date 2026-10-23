#pragma once
#include <metal_stdlib>
using namespace metal;

// Общие типы и функции эффектов фона «Камера».

struct CameraEffectUniforms {
    float2 viewSize;
    float2 textureSize;
    float time;
    uint effect;
    /// Смешивание эффекта с исходным кадром, 0…1.
    float amount;
    float brightness;
    float reliefDepth;
    /// Направление света в радианах (ось y вниз).
    float lightAngle;
    float edgeSensitivity;
    /// Множитель размера ячеек, пикселей, символов и кубиков.
    float detailScale;
};

namespace camfx {

constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);

inline float luma(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

inline float hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

/// Заполнение экрана кадром без искажения пропорций (aspect fill).
inline float2 aspectFill(float2 uv, float2 view, float2 texture) {
    float viewAspect = view.x / view.y;
    float textureAspect = texture.x / texture.y;
    if (viewAspect < textureAspect) {
        uv.x = 0.5 + (uv.x - 0.5) * viewAspect / textureAspect;
    } else {
        uv.y = 0.5 + (uv.y - 0.5) * textureAspect / viewAspect;
    }
    return uv;
}

inline float3 sampleCamera(texture2d<float> camera, float2 uv) {
    return camera.sample(linearSampler, uv).rgb;
}

/// Цвет кадра под точкой экрана (в пикселях drawable).
inline float3 sampleScreen(texture2d<float> camera, float2 pixel, CameraEffectUniforms u) {
    return sampleCamera(camera, aspectFill(pixel / u.viewSize, u.viewSize, u.textureSize));
}

/// Сила контура по оператору Собеля на яркости; `gain` — чувствительность.
inline float sobel(texture2d<float> camera, float2 uv, float2 texel, float gain = 1.0) {
    float tl = luma(sampleCamera(camera, uv + texel * float2(-1.0, -1.0)));
    float t = luma(sampleCamera(camera, uv + texel * float2(0.0, -1.0)));
    float tr = luma(sampleCamera(camera, uv + texel * float2(1.0, -1.0)));
    float l = luma(sampleCamera(camera, uv + texel * float2(-1.0, 0.0)));
    float r = luma(sampleCamera(camera, uv + texel * float2(1.0, 0.0)));
    float bl = luma(sampleCamera(camera, uv + texel * float2(-1.0, 1.0)));
    float b = luma(sampleCamera(camera, uv + texel * float2(0.0, 1.0)));
    float br = luma(sampleCamera(camera, uv + texel * float2(1.0, 1.0)));
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    return length(float2(gx, gy)) * gain;
}

inline float3 hue(float h) {
    return saturate(abs(fmod(h * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0);
}

/// Порог упорядоченного дизеринга Байера 8×8, значения в (0, 1).
inline float bayer8(uint2 p) {
    uint x = p.x & 7u;
    uint y = p.y & 7u;
    uint xy = x ^ y;
    uint value = ((xy & 1u) << 5) | ((y & 1u) << 4) | ((xy & 2u) << 2)
        | ((y & 2u) << 1) | ((xy & 4u) >> 1) | ((y & 4u) >> 2);
    return (float(value) + 0.5) / 64.0;
}

} // namespace camfx
