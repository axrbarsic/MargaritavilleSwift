#include <metal_stdlib>
using namespace metal;

constant float kPi = 3.14159265358979323846;

struct LiveCellGPUInstance {
    float4 rect;
    float4 colorDepth;
    float4 cornerRadii;
    float4 motion;
};

struct LiveCellFrameUniforms {
    float4 viewportTimeHeadroom;
};

struct LiveCellNormalVertexOut {
    float4 position [[position]];
    float2 uv;
    uint instanceIndex [[flat]];
};

struct LiveCellVIPVertexOut {
    float4 position [[position]];
    float2 uv;
    float3 normal;
    float height;
    uint instanceIndex [[flat]];
};

float2 liveCellViewportPosition(
    float2 point,
    constant LiveCellFrameUniforms& uniforms
) {
    float2 viewport = max(uniforms.viewportTimeHeadroom.xy, float2(1.0));
    return float2(
        point.x / viewport.x * 2.0 - 1.0,
        1.0 - point.y / viewport.y * 2.0
    );
}

float liveCellCornerRadius(
    float2 centeredPoint,
    float4 radii
) {
    bool isLeft = centeredPoint.x < 0.0;
    bool isTop = centeredPoint.y < 0.0;
    if (isLeft && isTop) {
        return radii.x;
    }
    if (isLeft) {
        return radii.y;
    }
    if (!isTop) {
        return radii.z;
    }
    return radii.w;
}

float liveCellRoundedRectAlpha(
    float2 uv,
    float2 size,
    float4 radii
) {
    float2 centered = uv * size - size * 0.5;
    float radius = min(
        liveCellCornerRadius(centered, radii),
        min(size.x, size.y) * 0.5
    );
    float2 q = abs(centered) - (size * 0.5 - float2(radius));
    float distance = length(max(q, float2(0.0)))
        + min(max(q.x, q.y), 0.0)
        - radius;
    return 1.0 - smoothstep(-1.1, 1.1, distance);
}

float2 liveCellRotate2D(float2 value, float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return float2(
        cosine * value.x - sine * value.y,
        sine * value.x + cosine * value.y
    );
}

float3 liveCellRotateX(float3 value, float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return float3(
        value.x,
        cosine * value.y - sine * value.z,
        sine * value.y + cosine * value.z
    );
}

float3 liveCellRotateY(float3 value, float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return float3(
        cosine * value.x + sine * value.z,
        value.y,
        -sine * value.x + cosine * value.z
    );
}

float liveCellRoundedBoxDistance(
    float3 point,
    float3 halfBounds,
    float radius
) {
    float3 q = abs(point) - halfBounds + float3(radius);
    return length(max(q, float3(0.0)))
        + min(max(q.x, max(q.y, q.z)), 0.0)
        - radius;
}

float3 liveCellRoundedBoxNormal(
    float3 point,
    float3 halfBounds,
    float radius
) {
    constexpr float epsilon = 0.0025;
    float center = liveCellRoundedBoxDistance(point, halfBounds, radius);
    return normalize(float3(
        liveCellRoundedBoxDistance(
            point + float3(epsilon, 0.0, 0.0),
            halfBounds,
            radius
        ) - center,
        liveCellRoundedBoxDistance(
            point + float3(0.0, epsilon, 0.0),
            halfBounds,
            radius
        ) - center,
        liveCellRoundedBoxDistance(
            point + float3(0.0, 0.0, epsilon),
            halfBounds,
            radius
        ) - center
    ));
}

vertex LiveCellNormalVertexOut liveCellNormalVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    device const LiveCellGPUInstance* instances [[buffer(0)]],
    constant LiveCellFrameUniforms& uniforms [[buffer(1)]]
) {
    constexpr float2 corners[6] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 0.0),
        float2(1.0, 1.0),
        float2(0.0, 1.0)
    };
    LiveCellGPUInstance instance = instances[instanceID];
    float2 uv = corners[vertexID];
    float2 point = instance.rect.xy + uv * instance.rect.zw;
    LiveCellNormalVertexOut out;
    out.position = float4(
        liveCellViewportPosition(point, uniforms),
        0.0,
        1.0
    );
    out.uv = uv;
    out.instanceIndex = instanceID;
    return out;
}

fragment float4 liveCellNormalFragment(
    LiveCellNormalVertexOut in [[stage_in]],
    device const LiveCellGPUInstance* instances [[buffer(0)]],
    constant LiveCellFrameUniforms& uniforms [[buffer(1)]]
) {
    LiveCellGPUInstance instance = instances[in.instanceIndex];
    float alpha = liveCellRoundedRectAlpha(
        in.uv,
        instance.rect.zw,
        instance.cornerRadii
    );
    if (alpha <= 0.001) {
        discard_fragment();
    }

    float time = uniforms.viewportTimeHeadroom.z;
    float phase = instance.motion.x;
    constexpr float cycleDuration = 13.75;
    constexpr float turnDuration = 1.5;
    float localTime = fmod(time + phase * cycleDuration, cycleDuration);
    float turnProgress = clamp(localTime / turnDuration, 0.0, 1.0);
    float turnEnvelope = localTime < turnDuration
        ? sin(kPi * turnProgress)
        : 0.0;
    float turnAngle = 0.5 * kPi * turnEnvelope;
    float slowPhase = time * 0.19 + phase * 2.0 * kPi;
    float scale = 1.0 + sin(slowPhase * 0.73 + 0.7) * 0.007;
    float zRoll = sin(slowPhase * 0.41 + 1.3) * 0.007;
    float zHover = sin(slowPhase) * 0.018;

    float aspect = max(instance.rect.z / max(instance.rect.w, 1.0), 0.1);
    float2 local = (in.uv * 2.0 - 1.0) * float2(aspect, 1.0);
    local = liveCellRotate2D(local / scale, -zRoll);
    float3 rayOrigin = float3(local, 3.0 - zHover);
    float3 rayDirection = float3(0.0, 0.0, -1.0);
    if (instance.motion.y < 0.5) {
        rayOrigin = liveCellRotateX(rayOrigin, -turnAngle);
        rayDirection = liveCellRotateX(rayDirection, -turnAngle);
    } else {
        rayOrigin = liveCellRotateY(rayOrigin, -turnAngle);
        rayDirection = liveCellRotateY(rayDirection, -turnAngle);
    }

    float depth = clamp(
        instance.colorDepth.w / max(instance.rect.w, 1.0) * 2.0,
        0.10,
        0.42
    );
    float3 halfBounds = float3(aspect, 1.0, depth);
    float averageRadius = dot(instance.cornerRadii, float4(0.25));
    float radius = clamp(
        averageRadius / max(instance.rect.w, 1.0) * 2.0,
        0.035,
        min(halfBounds.x, halfBounds.y) * 0.42
    );

    float travel = 0.0;
    float distance = 1.0;
    float3 hitPoint = float3(0.0);
    bool hit = false;
    for (uint step = 0; step < 40; ++step) {
        hitPoint = rayOrigin + rayDirection * travel;
        distance = liveCellRoundedBoxDistance(
            hitPoint,
            halfBounds,
            radius
        );
        if (distance < 0.0015) {
            hit = true;
            break;
        }
        travel += max(distance * 0.76, 0.004);
        if (travel > 6.0) {
            break;
        }
    }
    if (!hit) {
        discard_fragment();
    }

    float3 normal = liveCellRoundedBoxNormal(
        hitPoint,
        halfBounds,
        radius
    );
    float3 lightDirection = normalize(float3(-0.38, -0.52, 0.76));
    float3 viewDirection = normalize(-rayDirection);
    float diffuse = saturate(dot(normal, lightDirection));
    float specular = pow(
        saturate(dot(reflect(-lightDirection, normal), viewDirection)),
        34.0
    );
    float rim = pow(
        1.0 - saturate(dot(normal, viewDirection)),
        3.2
    );
    float grain = 0.965 + 0.035 * sin(
        hitPoint.x * 47.0 + hitPoint.y * 29.0 + phase * 17.0
    );
    float3 base = max(instance.colorDepth.xyz, float3(0.0));
    float3 body = base * grain * (0.70 + 0.30 * diffuse);
    float3 localHighlights = float3(
        0.16 * specular + 0.075 * rim
    );
    float headroom = max(uniforms.viewportTimeHeadroom.w, 1.0);
    float3 color = min(body + localHighlights, float3(headroom));
    return float4(color, alpha);
}

struct LiveCellVIPWave {
    float height;
    float derivativeX;
    float derivativeY;
};

LiveCellVIPWave liveCellVIPWave(
    float2 point,
    float time,
    float phase
) {
    float argumentA = point.x * 2.45 + time * 1.06 + phase;
    float argumentB = point.y * 2.10 - time * 0.86 + phase * 0.73;
    float argumentC = (point.x + point.y) * 3.25 + time * 0.61 + phase * 1.31;
    float wrinkleA = (point.x * 10.5 - point.y * 7.5) + time * 1.72 + phase;
    float wrinkleB = (point.x * 6.0 + point.y * 12.0) - time * 1.38 + phase * 0.43;

    LiveCellVIPWave wave;
    wave.height =
        sin(argumentA) * 0.075
        + cos(argumentB) * 0.064
        + sin(argumentC) * 0.044
        + sin(wrinkleA) * 0.011
        + cos(wrinkleB) * 0.009;
    wave.derivativeX =
        cos(argumentA) * 2.45 * 0.075
        + cos(argumentC) * 3.25 * 0.044
        + cos(wrinkleA) * 10.5 * 0.011
        - sin(wrinkleB) * 6.0 * 0.009;
    wave.derivativeY =
        -sin(argumentB) * 2.10 * 0.064
        + cos(argumentC) * 3.25 * 0.044
        - cos(wrinkleA) * 7.5 * 0.011
        - sin(wrinkleB) * 12.0 * 0.009;
    return wave;
}

vertex LiveCellVIPVertexOut liveCellVIPVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    device const float2* meshUV [[buffer(0)]],
    device const LiveCellGPUInstance* instances [[buffer(1)]],
    constant LiveCellFrameUniforms& uniforms [[buffer(2)]]
) {
    LiveCellGPUInstance instance = instances[instanceID];
    float2 uv = meshUV[vertexID];
    float2 point = uv * 2.0 - 1.0;
    float time = uniforms.viewportTimeHeadroom.z;
    float phase = instance.motion.x * 2.0 * kPi;
    LiveCellVIPWave wave = liveCellVIPWave(point, time, phase);

    float edge = smoothstep(
        0.42,
        1.0,
        max(abs(point.x), abs(point.y))
    );
    float contourWave =
        sin(point.y * 3.4 + time * 0.83 + phase) * 0.016
        + cos(point.x * 4.1 - time * 0.71 + phase * 0.7) * 0.012;
    float2 radial = normalize(point + float2(0.0001));
    float2 deformedPoint = point + radial * contourWave * edge;
    float2 screenPoint = instance.rect.xy
        + (deformedPoint * 0.5 + 0.5) * instance.rect.zw;
    screenPoint.y -= wave.height * instance.rect.w * 0.032;

    LiveCellVIPVertexOut out;
    out.position = float4(
        liveCellViewportPosition(screenPoint, uniforms),
        0.0,
        1.0
    );
    out.uv = uv;
    out.normal = normalize(float3(
        -wave.derivativeX,
        -wave.derivativeY,
        1.0
    ));
    out.height = wave.height;
    out.instanceIndex = instanceID;
    return out;
}

fragment float4 liveCellVIPFragment(
    LiveCellVIPVertexOut in [[stage_in]],
    device const LiveCellGPUInstance* instances [[buffer(0)]],
    constant LiveCellFrameUniforms& uniforms [[buffer(1)]]
) {
    LiveCellGPUInstance instance = instances[in.instanceIndex];
    float alpha = liveCellRoundedRectAlpha(
        in.uv,
        instance.rect.zw,
        instance.cornerRadii
    );
    if (alpha <= 0.001) {
        discard_fragment();
    }

    float3 normal = normalize(in.normal);
    float3 lightDirection = normalize(float3(-0.31, -0.44, 0.84));
    float3 viewDirection = float3(0.0, 0.0, 1.0);
    float diffuse = saturate(dot(normal, lightDirection));
    float specular = pow(
        saturate(dot(reflect(-lightDirection, normal), viewDirection)),
        24.0
    );
    float rim = pow(
        1.0 - saturate(dot(normal, viewDirection)),
        2.4
    );
    float crest = smoothstep(0.035, 0.155, in.height);
    float3 base = max(instance.colorDepth.xyz, float3(0.0));
    float3 body = base * (0.68 + 0.32 * diffuse);
    float localHighlight = 0.17 * specular + 0.085 * rim + 0.075 * crest;
    float headroom = max(uniforms.viewportTimeHeadroom.w, 1.0);
    float3 color = min(body + float3(localHighlight), float3(headroom));
    return float4(color, alpha);
}
