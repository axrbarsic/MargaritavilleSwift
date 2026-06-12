#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Единое желе-поле VIP-ячейки.
//
// Ячейка растеризуется ЦЕЛИКОМ (заливка, рамка, номер, буквы S/L/B, бейджи)
// в один слой, и этот слой деформируется ОДНИМ полем смещения. Контур и
// содержимое по построению двигаются вместе — монолитный материал, без
// отдельной CPU-кляксы и отдельного warp контента.
//
// Семантика distortionEffect: для пикселя назначения возвращаем позицию
// ИСТОЧНИКА, поэтому смещение вычитается.
[[ stitchable ]] float2 vipJellyUnifiedWarp(
    float2 position,
    float time,
    float speed,
    float seed,
    float2 size,
    float amplitude
) {
    float2 safe = max(size, float2(1.0, 1.0));
    float2 uv = position / safe;
    float t = time * clamp(speed, 0.2, 2.5);
    float ph = seed * 37.0;
    const float tau = 6.2831853;

    // Три октавы плавного 2D-поля; без циклов и ветвлений — дёшево для GPU.
    float dx =
        sin((uv.y * 1.7 + t * 0.23 + ph) * tau) * 0.55 +
        sin((uv.y * 3.4 - t * 0.31 + uv.x * 1.3 + ph * 1.7) * tau) * 0.30 +
        sin((uv.x * 2.6 + t * 0.17 + ph * 2.3) * tau) * 0.15;
    float dy =
        sin((uv.x * 1.9 - t * 0.27 + ph * 1.3) * tau) * 0.55 +
        sin((uv.x * 3.1 + t * 0.21 + uv.y * 1.6 + ph * 0.7) * tau) * 0.30 +
        sin((uv.y * 2.2 - t * 0.19 + ph * 2.9) * tau) * 0.15;

    // Кромка гуляет сильнее, центр дышит мягче — как у настоящего желе:
    // у мягкого тела максимально подвижна поверхность, сердцевина следует.
    float edge = min(min(uv.x, 1.0 - uv.x) * 2.0, min(uv.y, 1.0 - uv.y) * 2.0);
    float weight = mix(1.0, 0.44, smoothstep(0.0, 0.9, clamp(edge, 0.0, 1.0)));

    float2 displacement = float2(dx * 0.8, dy * 1.15) * amplitude * weight;
    return position - displacement;
}

static float2 vipJellyDisplacement(float2 position, float time, float speed, float seed, float2 size, float amplitude) {
    float2 safe = max(size, float2(1.0, 1.0));
    float2 uv = clamp(position / safe, float2(0.0, 0.0), float2(1.0, 1.0));
    float t = time * clamp(speed, 0.2, 2.5);
    float ph = seed * 37.0;
    const float tau = 6.2831853;

    float dx =
        sin((uv.y * 1.5 + t * 0.29 + ph) * tau) * 0.44 +
        sin((uv.y * 3.1 - t * 0.37 + uv.x * 1.4 + ph * 1.7) * tau) * 0.34 +
        sin((uv.x * 2.8 + t * 0.19 + ph * 2.3) * tau) * 0.22;
    float dy =
        sin((uv.x * 1.7 - t * 0.31 + ph * 1.3) * tau) * 0.44 +
        sin((uv.x * 3.0 + t * 0.27 + uv.y * 1.5 + ph * 0.7) * tau) * 0.34 +
        sin((uv.y * 2.5 - t * 0.23 + ph * 2.9) * tau) * 0.22;

    float edge = min(min(uv.x, 1.0 - uv.x) * 2.0, min(uv.y, 1.0 - uv.y) * 2.0);
    float weight = mix(1.0, 0.38, smoothstep(0.0, 0.85, clamp(edge, 0.0, 1.0)));
    return float2(dx * 0.95, dy * 1.28) * amplitude * weight;
}

// Layer effect version: samples the already composited room cell and applies
// the same displacement to color and alpha. The SwiftUI shape mask owns the
// outer contour so the visible silhouette cannot disappear if the layer shader
// samples transparent edge pixels.
[[ stitchable ]] half4 vipJellyUnifiedLayer(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float speed,
    float seed,
    float2 size,
    float amplitude,
    float cornerRadius
) {
    float2 safe = max(size, float2(1.0, 1.0));
    float2 displacement = vipJellyDisplacement(position, time, speed, seed, safe, amplitude);
    float2 sourcePosition = position - displacement;
    return layer.sample(sourcePosition);
}
