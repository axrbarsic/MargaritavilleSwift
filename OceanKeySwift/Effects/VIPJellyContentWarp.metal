#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] float2 vipJellyContentWarp(
    float2 position,
    float time,
    float speed,
    float seed,
    float2 size,
    float amplitude
) {
    float width = max(size.x, 1.0);
    float height = max(size.y, 1.0);
    float unitX = fract(position.x / width);
    float unitY = fract(position.y / height);
    float t = time * clamp(speed, 0.2, 2.5);
    float edgeBias = 1.0 - abs(unitY - 0.5) * 2.0;
    float falloff = 0.34 + smoothstep(0.0, 1.0, edgeBias) * 0.66;

    float slow = sin((unitX * (1.7 + seed * 1.9) + t * (0.31 + seed * 0.017) + seed * 19.37) * 6.2831853);
    float medium = sin((unitX * (3.1 + seed * 2.4) - t * (0.47 + seed * 0.09) + seed * 27.31) * 6.2831853);
    float fast = sin((unitX * (4.6 + seed * 1.7) + t * 0.61 + seed * 42.0) * 6.2831853);
    float vertical = (slow * 0.58 + medium * 0.34 + fast * 0.16) * amplitude * falloff;

    float sideWave = sin((unitY * 2.4 + t * 0.37 + seed * 11.0) * 6.2831853);
    float horizontal = sideWave * amplitude * 0.34 * (0.45 + edgeBias * 0.55);

    return float2(position.x - horizontal, position.y - vertical);
}
