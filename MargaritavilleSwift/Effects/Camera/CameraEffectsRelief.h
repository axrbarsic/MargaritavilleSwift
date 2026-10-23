#pragma once
#include "CameraEffectsCommon.h"

// Семейство «Тиснения»: яркость кадра — высота поверхности. Из неё строится
// нормаль, поверхность освещается сверху слева и получает материал:
// золото, серебро, медь, камень, бумага, дерево и рельеф с бегущим светом.

namespace camfx {

/// Нормаль рельефа по разности высот соседних точек (y вниз, z к зрителю).
inline float3 reliefNormal(texture2d<float> camera, float2 uv, float2 texel, float strength) {
    float2 o = texel * 2.0;
    float left = luma(sampleCamera(camera, uv - float2(o.x, 0.0)));
    float right = luma(sampleCamera(camera, uv + float2(o.x, 0.0)));
    float top = luma(sampleCamera(camera, uv - float2(0.0, o.y)));
    float bottom = luma(sampleCamera(camera, uv + float2(0.0, o.y)));
    return normalize(float3((left - right) * strength, (top - bottom) * strength, 1.0));
}

/// Освещение по Блинну — Фонгу: рассеянный свет и блик материала.
inline float3 reliefLight(float3 normal, float3 lightDirection, float3 base, float3 specular, float shininess, float specularStrength) {
    float3 light = normalize(lightDirection);
    float diffuse = saturate(dot(normal, light));
    float3 halfVector = normalize(light + float3(0.0, 0.0, 1.0));
    float highlight = pow(saturate(dot(normal, halfVector)), shininess) * specularStrength;
    return base * (0.3 + 0.8 * diffuse) + specular * highlight;
}

/// Направление света из угла настроек (ось y вниз), под 40° к поверхности.
inline float3 reliefLightFrom(CameraEffectUniforms u) {
    return float3(cos(u.lightAngle) * 0.78, sin(u.lightAngle) * 0.78, 0.65);
}

inline float3 goldRelief(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 9.0 * u.reliefDepth);
    float3 base = mix(float3(0.55, 0.36, 0.1), float3(0.95, 0.76, 0.32), luma(sampleCamera(camera, uv)));
    return reliefLight(n, reliefLightFrom(u), base, float3(1.0, 0.92, 0.65), 36.0, 0.9);
}

inline float3 silverRelief(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 11.0 * u.reliefDepth);
    return reliefLight(n, reliefLightFrom(u), float3(0.68, 0.7, 0.74), float3(1.0), 60.0, 1.0);
}

inline float3 copperRelief(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 9.0 * u.reliefDepth);
    float3 base = mix(float3(0.42, 0.18, 0.08), float3(0.85, 0.48, 0.28), luma(sampleCamera(camera, uv)));
    return reliefLight(n, reliefLightFrom(u), base, float3(1.0, 0.72, 0.52), 30.0, 0.8);
}

/// Камень: барельеф на шершавом песчанике.
inline float3 stoneRelief(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 7.0 * u.reliefDepth);
    float grain = hash(floor(pixel / 2.0)) * 0.12 + hash(floor(pixel / 7.0) + 3.0) * 0.1;
    float3 base = float3(0.62, 0.58, 0.52) * (0.85 + grain);
    return reliefLight(n, reliefLightFrom(u), base, float3(0.3), 12.0, 0.25);
}

/// Бумага: слепое тиснение белым по белому, как на открытке.
inline float3 paperRelief(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 5.0 * u.reliefDepth);
    float fiber = hash(floor(pixel / 1.5)) * 0.03;
    return reliefLight(n, reliefLightFrom(u), float3(0.92, 0.91, 0.87) + fiber, float3(0.25), 16.0, 0.2);
}

/// Дерево: резьба по доске с годичными волокнами.
inline float3 woodRelief(texture2d<float> camera, float2 uv, float2 pixel, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 8.0 * u.reliefDepth);
    float rings = sin(uv.y * 140.0 + sin(uv.x * 9.0) * 3.0 + hash(float2(floor(uv.y * 40.0), 1.0)) * 2.0);
    float3 base = mix(float3(0.42, 0.25, 0.12), float3(0.66, 0.44, 0.24), 0.5 + 0.25 * rings);
    return reliefLight(n, reliefLightFrom(u), base, float3(0.5, 0.4, 0.3), 20.0, 0.3);
}

/// Живой рельеф: серебро, по которому по кругу ходит источник света.
inline float3 liveRelief(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float3 n = reliefNormal(camera, uv, texel, 11.0 * u.reliefDepth);
    float angle = u.time * 0.9;
    float3 light = float3(cos(angle) * 0.7, sin(angle) * 0.7, 0.6);
    return reliefLight(n, light, float3(0.66, 0.68, 0.74), float3(1.0, 0.97, 0.9), 50.0, 1.1);
}

} // namespace camfx
