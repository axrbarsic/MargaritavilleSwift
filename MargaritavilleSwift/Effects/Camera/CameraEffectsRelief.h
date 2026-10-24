#pragma once
#include "CameraEffectsCommon.h"

// Семейство «Тиснения»: яркость кадра — высота поверхности. Из неё строится
// нормаль, поверхность освещается и получает материал: металл любого цвета,
// камень, бумага или дерево. Свет можно направить или пустить по кругу.

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
    float angle = u.liveLight > 0.5 ? u.time * 0.9 : u.lightAngle;
    return float3(cos(angle) * 0.78, sin(angle) * 0.78, 0.65);
}

/// Металл любого цвета: насыщенность 0 — серебро, дальше оттенок задаёт
/// золото, медь, латунь, синюю сталь и т. д.
inline float3 metalRelief(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float saturation = saturate(u.metalSaturation);
    float3 n = reliefNormal(camera, uv, texel, mix(11.0, 9.0, saturation) * u.reliefDepth);
    float3 tint = hue(fract(u.metalHue));
    float3 silverDark = float3(0.5, 0.52, 0.56);
    float3 silverLight = float3(0.78, 0.8, 0.84);
    float3 dark = mix(silverDark, tint * 0.45 + 0.05, saturation);
    float3 light = mix(silverLight, mix(tint, float3(1.0), 0.35), saturation);
    float3 base = mix(dark, light, luma(sampleCamera(camera, uv)));
    float3 specular = mix(float3(1.0), mix(tint, float3(1.0), 0.6), saturation);
    return reliefLight(n, reliefLightFrom(u), base, specular, mix(60.0, 34.0, saturation), mix(1.0, 0.85, saturation));
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


} // namespace camfx

namespace camfx {

/// Тон, насыщенность и яркость цвета (тон 0…1).
inline float3 rgbToHsv(float3 c) {
    float4 k = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, k.wz), float4(c.gb, k.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

/// Таблица металлов: каждый участок кадра становится металлом своего цвета —
/// медь, бронза, золото, латунь, патина, висмут, титан, кобальт, розовое
/// золото, а бесцветные — серебро, платина и железо. Переходы плавные.
inline float3 periodicMetals(texture2d<float> camera, float2 uv, float2 texel, CameraEffectUniforms u) {
    float3 color = sampleCamera(camera, uv);
    float3 hsv = rgbToHsv(color);
    float3 n = reliefNormal(camera, uv, texel, 9.0 * u.reliefDepth);

    // Цветные металлы: центр тона в градусах, цвет и цвет блика.
    const float centers[9] = { 15.0, 32.0, 48.0, 70.0, 140.0, 182.0, 220.0, 280.0, 340.0 };
    const float3 bases[9] = {
        float3(0.85, 0.45, 0.30), float3(0.70, 0.48, 0.25), float3(0.95, 0.75, 0.30),
        float3(0.82, 0.75, 0.38), float3(0.35, 0.62, 0.50), float3(0.5, 0.5, 0.5),
        float3(0.30, 0.45, 0.80), float3(0.55, 0.35, 0.75), float3(0.90, 0.55, 0.55)
    };
    const float3 speculars[9] = {
        float3(1.0, 0.75, 0.6), float3(1.0, 0.85, 0.6), float3(1.0, 0.93, 0.65),
        float3(1.0, 0.97, 0.7), float3(0.8, 1.0, 0.9), float3(1.0),
        float3(0.8, 0.9, 1.0), float3(0.9, 0.85, 1.0), float3(1.0, 0.85, 0.85)
    };
    float hueDegrees = hsv.x * 360.0;
    float3 colorBase = float3(0.0);
    float3 colorSpecular = float3(0.0);
    float weightSum = 0.0;
    for (int index = 0; index < 9; index++) {
        float distance = abs(hueDegrees - centers[index]);
        distance = min(distance, 360.0 - distance);
        float weight = exp(-pow(distance / 22.0, 2.0));
        float3 base = bases[index];
        if (index == 5) {
            // Висмут переливается радугой в зависимости от наклона поверхности.
            base = hue(fract(dot(n.xy, float2(0.6, 0.4)) * 1.5 + 0.55)) * 0.75 + 0.18;
        }
        colorBase += base * weight;
        colorSpecular += speculars[index] * weight;
        weightSum += weight;
    }
    colorBase /= max(weightSum, 1e-4);
    colorSpecular /= max(weightSum, 1e-4);

    // Основа — яркость: в любой сцене, даже тусклой и бесцветной, кадр
    // раскладывается на ряд металлов от железа в тенях до серебра в светах.
    const float3 bandBases[6] = {
        float3(0.30, 0.31, 0.34), float3(0.28, 0.42, 0.72), float3(0.80, 0.42, 0.28),
        float3(0.72, 0.52, 0.26), float3(0.95, 0.76, 0.30), float3(0.84, 0.85, 0.88)
    };
    const float3 bandSpeculars[6] = {
        float3(0.7), float3(0.8, 0.9, 1.0), float3(1.0, 0.75, 0.6),
        float3(1.0, 0.85, 0.6), float3(1.0, 0.93, 0.65), float3(1.0)
    };
    const float bandShininess[6] = { 18.0, 40.0, 34.0, 34.0, 38.0, 70.0 };
    float level = saturate(luma(color)) * 5.0;
    int lower = min(int(floor(level)), 4);
    float blend = smoothstep(0.35, 0.65, level - float(lower));
    float3 bandBase = mix(bandBases[lower], bandBases[lower + 1], blend);
    float3 bandSpecular = mix(bandSpeculars[lower], bandSpeculars[lower + 1], blend);
    float bandShine = mix(bandShininess[lower], bandShininess[lower + 1], blend);

    // Насыщенные предметы получают металл своего цвета поверх ряда по яркости.
    float colored = smoothstep(0.38, 0.6, hsv.y) * smoothstep(0.12, 0.25, hsv.z);
    float3 base = mix(bandBase, colorBase, colored) * (0.75 + 0.4 * luma(color));
    float3 specular = mix(bandSpecular, colorSpecular, colored);
    float shininess = mix(bandShine, 38.0, colored);
    return reliefLight(n, reliefLightFrom(u), base, specular, shininess, 0.9);
}

} // namespace camfx
