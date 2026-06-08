#include <metal_stdlib>
using namespace metal;

struct AuroraVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct AuroraUniforms {
    float time;
    float width;
    float height;
    float intensity;
};

vertex AuroraVertexOut metalAuroraVertex(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    AuroraVertexOut out;
    float2 position = positions[vertexID];
    out.position = float4(position, 0.0, 1.0);
    out.uv = position * 0.5 + 0.5;
    return out;
}

static float auroraNoise(float2 p) {
    float value = 0.0;
    float amplitude = 0.52;
    float frequency = 1.0;
    for (int i = 0; i < 5; i++) {
        value += sin(p.x * frequency + sin(p.y * frequency * 0.9)) * amplitude;
        p = float2(p.y * 1.18 + 0.37, p.x * 0.82 - 0.21);
        frequency *= 1.72;
        amplitude *= 0.54;
    }
    return value;
}

fragment float4 metalAuroraFragment(AuroraVertexOut in [[stage_in]],
                                    constant AuroraUniforms& uniforms [[buffer(0)]]) {
    float2 uv = in.uv;
    float aspect = max(uniforms.width / max(uniforms.height, 1.0), 0.1);
    float2 p = float2((uv.x - 0.5) * aspect, uv.y - 0.5);
    float t = uniforms.time * 0.18;

    float waveA = auroraNoise(float2(p.x * 2.2 + t, p.y * 2.6 - t * 0.55));
    float waveB = auroraNoise(float2(p.x * 3.4 - t * 0.72, p.y * 1.7 + t * 0.38));
    float ribbon = smoothstep(0.62, 0.05, abs(p.y - waveA * 0.18 - sin(p.x * 3.0 + t) * 0.08));
    float glow = smoothstep(0.85, 0.0, length(p + float2(waveB * 0.08, -0.10)));
    float vignette = smoothstep(0.96, 0.22, length((uv - 0.5) * float2(aspect, 1.0)));

    float intensity = clamp((ribbon * 0.72 + glow * 0.42) * uniforms.intensity, 0.0, 1.0);
    float3 deep = float3(0.0, 0.015, 0.006);
    float3 green = float3(0.02, 0.92, 0.28);
    float3 cyan = float3(0.03, 0.55, 0.42);
    float3 color = deep + green * intensity + cyan * pow(intensity, 2.2) * 0.55;
    color *= vignette;

    return float4(color, 1.0);
}
