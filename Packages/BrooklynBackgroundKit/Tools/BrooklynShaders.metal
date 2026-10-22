#include <metal_stdlib>
using namespace metal;

constant float brooklynPI = 3.14159265358979323846;

struct MeshVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct SceneUniforms {
    float4x4 viewProjection;
    float4 cameraPosition;
    float4 viewportSpacingScale;
    float4 baseColor;
    float4 fogColor;
    float2 highlightGrid;
    float time;
    uint surfaceStyle;
    float environmentMaxMip;
};

struct CompositeUniforms {
    float brightness;
    float contrast;
    uint applyCorrection;
    uint padding;
};

struct SceneVertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float3 geometryPosition;
    float3 mouseVector;
    float2 uv;
    float viewDepth;
    float isHighlighted [[flat]];
};

struct CompositeVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct BloomDownsampleUniforms {
    uint applyThreshold;
    float threshold;
    float smoothWidth;
    uint padding;
};

struct BloomBlurUniforms {
    uint level;
    uint horizontal;
    uint2 padding;
};

float3 rotateX(float3 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3(point.x, c * point.y - s * point.z, s * point.y + c * point.z);
}

float3 rotateY(float3 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3(c * point.x + s * point.z, point.y, -s * point.x + c * point.z);
}

float3 rotateZ(float3 point, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3(c * point.x - s * point.y, s * point.x + c * point.y, point.z);
}

float easePowerInOut(float progress, float exponent) {
    float t = saturate(progress);
    return t < 0.5
        ? pow(t * 2.0, exponent) * 0.5
        : 1.0 - pow((1.0 - t) * 2.0, exponent) * 0.5;
}

float sineInOut(float progress) {
    return 0.5 - cos(brooklynPI * saturate(progress)) * 0.5;
}

float2 rotateDonorUV(float2 uv, float angle, float2 midpoint) {
    float c = cos(angle);
    float s = sin(angle);
    return float2(
        c * (uv.x - midpoint.x) + s * (uv.y - midpoint.y) + midpoint.x,
        c * (uv.y - midpoint.y) - s * (uv.x - midpoint.x) + midpoint.y
    );
}

float3 srgbToLinear(float3 color) {
    float3 low = color / 12.92;
    float3 high = pow((color + 0.055) / 1.055, float3(2.4));
    return select(high, low, color <= 0.04045);
}

float3 linearToSRGB(float3 color) {
    float3 low = color * 12.92;
    float3 high = pow(max(color, 0.0), float3(0.41666)) * 1.055 - 0.055;
    return select(high, low, color <= 0.0031308);
}

float3 environmentSample(
    texture2d<float> environment,
    sampler environmentSampler,
    float3 direction,
    float mip
) {
    float3 d = normalize(direction);
    float2 uv = float2(
        atan2(d.z, d.x) / (2.0 * brooklynPI) + 0.5,
        0.5 - asin(clamp(d.y, -1.0, 1.0)) / brooklynPI
    );
    return environment.sample(environmentSampler, uv, level(mip)).rgb;
}

float3 environmentBRDF(float3 specularColor, float roughness, float dotNV) {
    const float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
    const float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);
    float4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * dotNV)) * r.x + r.y;
    float2 ab = float2(-1.04, 1.04) * a004 + r.zw;
    return specularColor * ab.x + ab.y;
}

vertex SceneVertexOut brooklynSceneVertex(
    MeshVertex in [[stage_in]],
    constant SceneUniforms& uniforms [[buffer(1)]],
    constant float4* instances [[buffer(2)]],
    uint instanceID [[instance_id]]
) {
    float4 cell = instances[instanceID];
    float seed = cell.z;
    float delay = 0.2 + seed * 1.8;
    float duration = brooklynPI * 0.5 + seed * brooklynPI;
    float repeatDelay = 2.0 + seed;
    float cycleDuration = delay + duration + repeatDelay;
    float cycle = floor(uniforms.time / cycleDuration);
    float localTime = uniforms.time - cycle * cycleDuration;
    float exponent = 3.0 + floor(seed * 3.0);
    float turnProgress = easePowerInOut((localTime - delay) / duration, exponent);
    float turn = (cycle + turnProgress) * brooklynPI * 0.5;

    float spacing = uniforms.viewportSpacingScale.z;
    float scale = spacing * 0.9;
    float breathTime = uniforms.time - delay;
    if (breathTime > 0.0 && breathTime < 4.0) {
        float breathProgress = breathTime <= 2.0 ? breathTime * 0.5 : (4.0 - breathTime) * 0.5;
        scale += (seed * 0.05 - 0.05) * sineInOut(breathProgress);
    }

    float3 localVertex = in.position * scale;
    float3 localNormal = in.normal;
    if (seed < 0.5) {
        localVertex = rotateX(localVertex, turn);
        localNormal = rotateX(localNormal, turn);
    } else {
        localVertex = rotateZ(localVertex, turn);
        localNormal = rotateZ(localNormal, turn);
    }

    float3 instanceOrigin = float3(cell.x * spacing, 0.0, cell.y * spacing);
    float3 localPosition = instanceOrigin + localVertex;
    float3 worldPosition = rotateX(
        rotateY(localPosition, -brooklynPI * 0.25),
        brooklynPI * 0.2
    );
    float3 worldNormal = rotateX(
        rotateY(localNormal, -brooklynPI * 0.25),
        brooklynPI * 0.2
    );

    SceneVertexOut out;
    out.position = uniforms.viewProjection * float4(worldPosition, 1.0);
    out.worldPosition = worldPosition;
    out.normal = normalize(worldNormal);
    out.geometryPosition = in.position;
    out.mouseVector = -localVertex;
    out.uv = in.uv;
    out.viewDepth = uniforms.cameraPosition.z - worldPosition.z;
    out.isHighlighted = all(abs(cell.xy - uniforms.highlightGrid) < 0.01) ? 1.0 : 0.0;
    return out;
}

fragment float4 brooklynSceneFragment(
    SceneVertexOut in [[stage_in]],
    constant SceneUniforms& uniforms [[buffer(1)]],
    texture2d<float> texture0 [[texture(0)]],
    texture2d<float> texture1 [[texture(1)]],
    texture2d<float> environment [[texture(2)]],
    sampler textureSampler [[sampler(0)]],
    sampler environmentSampler [[sampler(1)]]
) {
    float3 diffuseColor = in.isHighlighted > 0.5 ? float3(1.0) : uniforms.baseColor.rgb;

    float2 st = in.uv * 2.0 - 0.5;
    float3 q = in.geometryPosition;
    float3 p = in.worldPosition;
    float2 mouseDistance = (in.mouseVector - p).xy;

    float isBottom = step(q.y, -0.45);
    float isBack = step(q.z, -0.45);
    float2 patternUV = rotateDonorUV(st, length(mouseDistance) * brooklynPI, float2(0.5));
    patternUV = rotateDonorUV(patternUV, uniforms.time * 0.15, float2(0.5));

    float4 channel0 = texture0.sample(textureSampler, patternUV);
    float4 channel1 = texture1.sample(textureSampler, patternUV);
    float4 lowerTexture = mix(channel0, channel1, isBottom);
    lowerTexture = mix(lowerTexture, channel0, step(0.9, diffuseColor.g));
    float4 lineTexture = mix(float4(0.0), lowerTexture, min(isBottom + isBack, 1.0));

    float inversion = 1.0 - smoothstep(0.2, 0.745, length(mouseDistance));
    lineTexture.rgb = mix(lineTexture.rgb, 1.0 - lineTexture.rgb, inversion);

    float whiteMask = 1.0 - smoothstep(0.0, 1.5, distance(abs(st), float2(1.0, 0.5)));
    diffuseColor = mix(diffuseColor, float3(1.2), whiteMask);
    diffuseColor = mix(diffuseColor, lineTexture.rgb * 2.0, pow(lineTexture.a, 4.0));

    float mouseBoost = 1.0 - smoothstep(-0.2, 0.6, length(mouseDistance));
    diffuseColor = mix(diffuseColor, diffuseColor * 1.23, mouseBoost);

    float3 normal = normalize(in.normal);
    float3 viewDirection = normalize(uniforms.cameraPosition.xyz - in.worldPosition);
    float dotNV = saturate(dot(normal, viewDirection));
    float roughness = uniforms.surfaceStyle == 0 ? 0.5 : 0.28;
    float3 reflection = normalize(mix(
        reflect(-viewDirection, normal),
        normal,
        roughness * roughness
    ));
    float diffuseMip = max(uniforms.environmentMaxMip - 1.0, 0.0);
    float specularMip = roughness * uniforms.environmentMaxMip;
    float3 irradiance = environmentSample(environment, environmentSampler, normal, diffuseMip);
    float3 radiance = environmentSample(environment, environmentSampler, reflection, specularMip);
    float3 specularColor = float3(0.04);
    float3 specular = radiance * environmentBRDF(specularColor, roughness, dotNV);
    float3 color = (diffuseColor * irradiance + specular) * 0.24;

    if (uniforms.surfaceStyle == 1) {
        float rim = pow(1.0 - dotNV, 3.0);
        float3 lightDirection = normalize(float3(-0.45, 0.78, 0.62));
        float3 halfVector = normalize(lightDirection + viewDirection);
        float keySpecular = pow(max(dot(normal, halfVector), 0.0), 34.0);
        color += radiance * environmentBRDF(float3(0.08), roughness, dotNV) * 0.22;
        color += rim * float3(0.68, 0.15, 0.34) * 0.34;
        color += keySpecular * float3(1.15, 0.72, 0.92) * 0.48;
    }

    float fogFactor = 1.0 - exp(-0.08 * 0.08 * in.viewDepth * in.viewDepth);
    float3 fogColor = uniforms.fogColor.rgb;
    color = mix(color, fogColor, saturate(fogFactor));
    return float4(color, 1.0);
}

kernel void brooklynBloomDownsample(
    texture2d<float, access::sample> source [[texture(0)]],
    texture2d<float, access::write> destination [[texture(1)]],
    constant BloomDownsampleUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= destination.get_width() || gid.y >= destination.get_height()) return;
    constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = (float2(gid) + 0.5) / float2(destination.get_width(), destination.get_height());
    float4 color = source.sample(linearSampler, uv);
    if (uniforms.applyThreshold != 0) {
        float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
        float alpha = smoothstep(uniforms.threshold, uniforms.threshold + uniforms.smoothWidth, luminance);
        color = float4(color.rgb * alpha, alpha);
    }
    destination.write(color, gid);
}

constant float bloomWeights0[3] = { 1.0, 0.945959469, 0.800737403 };
constant float bloomWeights1[5] = { 1.0, 0.980198673, 0.923116346, 0.835270211, 0.726149037 };
constant float bloomWeights2[7] = { 1.0, 0.989847803, 0.960005441, 0.912254077, 0.849365817, 0.774837429, 0.692569324 };
constant float bloomWeights3[9] = { 1.0, 0.993846173, 0.975610980, 0.945959469, 0.905955191, 0.856996891, 0.800737403, 0.738991296, 0.673638455 };
constant float bloomWeights4[11] = { 1.0, 0.995876295, 0.983606928, 0.963492975, 0.936022558, 0.901851159, 0.861775631, 0.816703356, 0.767618196, 0.715545032, 0.661514656 };

float bloomWeight(uint level, uint index) {
    switch (level) {
    case 0: return bloomWeights0[index];
    case 1: return bloomWeights1[index];
    case 2: return bloomWeights2[index];
    case 3: return bloomWeights3[index];
    default: return bloomWeights4[index];
    }
}

kernel void brooklynBloomBlur(
    texture2d<float, access::sample> source [[texture(0)]],
    texture2d<float, access::write> destination [[texture(1)]],
    constant BloomBlurUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= destination.get_width() || gid.y >= destination.get_height()) return;
    constexpr sampler linearSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 size = float2(destination.get_width(), destination.get_height());
    float2 uv = (float2(gid) + 0.5) / size;
    float2 direction = uniforms.horizontal != 0 ? float2(1.0 / size.x, 0.0) : float2(0.0, 1.0 / size.y);
    uint radius = 3 + uniforms.level * 2;
    float weightSum = bloomWeight(uniforms.level, 0);
    float3 sum = source.sample(linearSampler, uv).rgb * weightSum;
    for (uint index = 1; index < radius; index += 1) {
        float weight = bloomWeight(uniforms.level, index);
        float2 offset = direction * float(index);
        sum += source.sample(linearSampler, uv + offset).rgb * weight;
        sum += source.sample(linearSampler, uv - offset).rgb * weight;
        weightSum += 2.0 * weight;
    }
    destination.write(float4(sum / weightSum, 1.0), gid);
}

vertex CompositeVertexOut brooklynCompositeVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[] = {
        float2(-1.0, -1.0),
        float2(3.0, -1.0),
        float2(-1.0, 3.0)
    };
    CompositeVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = float2(
        positions[vertexID].x * 0.5 + 0.5,
        0.5 - positions[vertexID].y * 0.5
    );
    return out;
}

float3 rrtAndODTFit(float3 value) {
    float3 a = value * (value + 0.0245786) - 0.000090537;
    float3 b = value * (0.983729 * value + 0.4329510) + 0.238081;
    return a / b;
}

float3 acesFilmicToneMapping(float3 color) {
    const float3x3 inputMatrix = float3x3(
        float3(0.59719, 0.07600, 0.02840),
        float3(0.35458, 0.90834, 0.13383),
        float3(0.04823, 0.01566, 0.83777)
    );
    const float3x3 outputMatrix = float3x3(
        float3(1.60475, -0.10208, -0.00327),
        float3(-0.53108, 1.10813, -0.07276),
        float3(-0.07367, -0.00605, 1.07602)
    );
    color *= 1.0 / 0.6;
    color = inputMatrix * color;
    color = rrtAndODTFit(color);
    return saturate(outputMatrix * color);
}

fragment float4 brooklynCompositeFragment(
    CompositeVertexOut in [[stage_in]],
    texture2d<float> scene [[texture(0)]],
    texture2d<float> bloom0 [[texture(1)]],
    texture2d<float> bloom1 [[texture(2)]],
    texture2d<float> bloom2 [[texture(3)]],
    texture2d<float> bloom3 [[texture(4)]],
    texture2d<float> bloom4 [[texture(5)]],
    sampler linearSampler [[sampler(0)]],
    constant CompositeUniforms& correction [[buffer(0)]]
) {
    float2 uv = saturate(in.uv);
    float3 bloom = 0.25 * (
        0.24 * bloom0.sample(linearSampler, uv).rgb +
        0.42 * bloom1.sample(linearSampler, uv).rgb +
        0.60 * bloom2.sample(linearSampler, uv).rgb +
        0.78 * bloom3.sample(linearSampler, uv).rgb +
        0.96 * bloom4.sample(linearSampler, uv).rgb
    );
    float3 linearColor = scene.sample(linearSampler, uv).rgb + bloom;
    float3 color = linearToSRGB(acesFilmicToneMapping(linearColor));
    if (correction.applyCorrection != 0) {
        // Яркость/контраст финальной цветокоррекции (формула BrightnessContrastEffect).
        color += correction.brightness - 0.5;
        color = correction.contrast > 0.0
            ? color / (1.0 - correction.contrast)
            : color * (1.0 + correction.contrast);
        color = saturate(color + 0.5);
    }
    return float4(color, 1.0);
}
