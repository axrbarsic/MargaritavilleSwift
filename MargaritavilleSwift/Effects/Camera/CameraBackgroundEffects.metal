#include "CameraEffectsCommon.h"
#include "CameraEffectsRetro.h"
#include "CameraEffectsViral.h"

// Эффекты фона «Камера». Номера веток совпадают с порядком
// `CameraBackgroundEffect.allCases`.

struct CameraVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex CameraVertexOut cameraEffectVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
    float2 p = positions[vertexID];
    CameraVertexOut out;
    out.position = float4(p, 0.0, 1.0);
    out.uv = float2(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5);
    return out;
}

namespace camfx {

inline float3 thermal(float value) {
    const float3 stops[5] = {
        float3(0.0, 0.0, 0.08),
        float3(0.30, 0.0, 0.62),
        float3(0.92, 0.05, 0.32),
        float3(1.0, 0.55, 0.0),
        float3(1.0, 1.0, 0.65)
    };
    float t = saturate(value) * 4.0;
    int index = min(int(floor(t)), 3);
    return mix(stops[index], stops[index + 1], t - float(index));
}

} // namespace camfx

/// Обновление истории кадров для эффектов с памятью (скан времени, шлейф).
fragment float4 cameraHistoryFragment(
    CameraVertexOut in [[stage_in]],
    texture2d<float> camera [[texture(0)]],
    texture2d<float> history [[texture(1)]],
    constant CameraEffectUniforms& u [[buffer(0)]]
) {
    float3 live = camfx::sampleCamera(camera, camfx::aspectFill(in.uv, u.viewSize, u.textureSize));
    if (u.resetHistory != 0) {
        return float4(live, 1.0);
    }
    float3 previous = history.sample(camfx::linearSampler, in.uv).rgb;
    if (u.effect == 16) {
        float y = in.uv.y;
        bool frozen = y < u.previousScanLine;
        return float4(frozen ? previous : live, 1.0);
    }
    return float4(mix(live, previous * float3(0.97, 0.9, 1.0), 0.8), 1.0);
}

fragment float4 cameraEffectFragment(
    CameraVertexOut in [[stage_in]],
    texture2d<float> camera [[texture(0)]],
    texture2d<float> history [[texture(1)]],
    constant CameraEffectUniforms& u [[buffer(0)]]
) {
    float2 uv = camfx::aspectFill(in.uv, u.viewSize, u.textureSize);
    float2 texel = 1.0 / u.textureSize;
    float2 pixel = in.uv * u.viewSize;
    float3 color;

    switch (u.effect) {
    case 1: { // Матовый: кадр уже размыт MPS, добавляем молочность и зерно.
        color = camfx::sampleCamera(camera, uv);
        color = mix(color, float3(camfx::luma(color)), 0.15);
        color = mix(color, float3(1.0), 0.14);
        color += (camfx::hash(pixel + fract(u.time) * 61.0) - 0.5) * 0.05;
        break;
    }
    case 2: { // Сетка: неоновые линии и бегущая строка сканирования.
        color = camfx::sampleCamera(camera, uv) * 0.82;
        float cell = u.viewSize.x / 12.0;
        float2 offset = abs(fract(pixel / cell + 0.5) - 0.5) * cell;
        float distanceToLine = min(offset.x, offset.y);
        float line = 1.0 - smoothstep(0.0, 1.6, distanceToLine);
        float glow = exp(-distanceToLine * 0.35) * 0.35;
        float scanY = fract(u.time * 0.25) * u.viewSize.y;
        float scan = exp(-abs(pixel.y - scanY) * 0.02) * 0.25;
        color += float3(0.1, 1.0, 0.85) * (line * 0.7 + glow * 0.6) + float3(0.2, 1.0, 0.8) * scan;
        break;
    }
    case 3: { // Ночное видение.
        float value = pow(saturate(camfx::luma(camfx::sampleCamera(camera, uv)) * 1.9), 0.75);
        float noise = (camfx::hash(pixel + floor(u.time * 30.0)) - 0.5) * 0.18;
        float scanlines = 0.88 + 0.12 * sin(pixel.y * 1.6);
        float vignette = smoothstep(0.85, 0.25, length((in.uv - 0.5) * float2(1.0, 0.8)));
        color = float3(0.18, 1.0, 0.28) * saturate(value + noise) * scanlines * vignette;
        break;
    }
    case 4: // Тепловизор.
        color = camfx::thermal(camfx::luma(camfx::sampleCamera(camera, uv)));
        break;
    case 5: { // Неон-контуры: светящиеся края на тёмном фоне.
        float edge = smoothstep(0.12, 0.55, camfx::sobel(camera, uv, texel * 1.5));
        float3 tint = camfx::hue(fract(in.uv.y * 0.6 + in.uv.x * 0.3 + u.time * 0.08));
        color = camfx::sampleCamera(camera, uv) * 0.06 + tint * edge * 1.2;
        break;
    }
    case 6: { // Комикс: постеризация и чёрные контуры.
        float3 base = floor(camfx::sampleCamera(camera, uv) * 5.0 + 0.5) / 5.0;
        float edge = step(0.35, camfx::sobel(camera, uv, texel * 1.8));
        color = mix(base * 1.08, float3(0.02), edge);
        break;
    }
    case 7: { // Пиксели: мозаика с тонкими швами.
        float block = u.viewSize.x / 40.0;
        color = camfx::sampleScreen(camera, (floor(pixel / block) + 0.5) * block, u);
        float2 inner = fract(pixel / block);
        color *= 1.0 - step(0.92, max(inner.x, inner.y)) * 0.35;
        break;
    }
    case 8: color = camfx::ascii(camera, pixel, u); break;
    case 9: color = camfx::dither1Bit(camera, pixel, u); break;
    case 10: color = camfx::halftone(camera, pixel, u); break;
    case 11: color = camfx::gameBoy(camera, pixel, u); break;
    case 12: color = camfx::crt(camera, pixel, u); break;
    case 13: color = camfx::sketch(camera, uv, pixel, u); break;
    case 14: color = camfx::kaleidoscope(camera, pixel, u); break;
    case 15: color = camfx::glitch(camera, pixel, u); break;
    case 16: color = camfx::timeScan(history, in.uv, u); break;
    case 17: color = history.sample(camfx::linearSampler, in.uv).rgb; break;
    case 18: color = camfx::matrixRain(camera, pixel, u); break;
    case 19: color = camfx::anaglyph(camera, uv); break;
    case 20: color = camfx::xray(camera, uv, texel); break;
    case 21: color = camfx::vaporwave(camera, uv, pixel); break;
    case 22: color = camfx::mirror(camera, in.uv, u); break;
    case 23: color = camfx::hologram(camera, uv, pixel, texel, u); break;
    default: // Обычный.
        color = camfx::sampleCamera(camera, uv);
        break;
    }
    return float4(saturate(color), 1.0);
}
