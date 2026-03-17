// Live2DShaders.metal — Metal shaders for Live2D Cubism 2.x rendering
// Ported from live2d-v2/live2d/core/graphics/draw_param_opengl.py GLSL shaders

#include <metal_stdlib>
using namespace metal;

// Vertex data from CPU
struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

// Passed from vertex to fragment shader
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Uniforms shared between vertex and fragment
struct Uniforms {
    float4x4 projectionMatrix;
    float opacity;
    int compositionType;  // 0=normal, 1=screen, 2=multiply
    float4 multiplyColor;
    float4 screenColor;
    int useClipMask;
    float2 padding;
};

// Clip mask uniforms (for mask rendering and clipped drawing)
struct ClipUniforms {
    float4x4 clipMatrix;    // matrixForDraw (clipped drawing)
    float4 channelFlag;     // RGBA channel selector
    float4 clipBounds;      // NDC bounds for isInside test (mask rendering)
};

// MARK: - Vertex Shader (Normal / unclipped)

vertex VertexOut live2d_vertex(const device VertexIn* vertices [[buffer(0)]],
                               constant Uniforms& uniforms [[buffer(1)]],
                               uint vid [[vertex_id]]) {
    VertexOut out;
    float4 pos = float4(vertices[vid].position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * pos;
    out.texCoord = vertices[vid].texCoord;
    return out;
}

// MARK: - Fragment Shader (Normal blend)

fragment float4 live2d_fragment_normal(VertexOut in [[stage_in]],
                                       constant Uniforms& uniforms [[buffer(0)]],
                                       texture2d<float> tex [[texture(0)]]) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear,
                                  address::clamp_to_edge);
    float4 color = tex.sample(texSampler, in.texCoord);

    // Step 1: Premultiply alpha (straight → premultiplied)
    // Matches Python GLSL: smpColor.rgb = smpColor.rgb * smpColor.a
    color.rgb *= color.a;

    // Step 2: Apply multiply color
    color.rgb *= uniforms.multiplyColor.rgb;

    // Step 3: Apply screen color
    color.rgb = color.rgb + uniforms.screenColor.rgb - color.rgb * uniforms.screenColor.rgb;

    // Step 4: Apply opacity to all channels (premultiplied convention)
    // Matches Python GLSL: smpColor = smpColor * u_baseColor
    color *= uniforms.opacity;

    return color;
}

// MARK: - Fragment Shader (Screen blend)

fragment float4 live2d_fragment_screen(VertexOut in [[stage_in]],
                                        constant Uniforms& uniforms [[buffer(0)]],
                                        texture2d<float> tex [[texture(0)]]) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear,
                                  address::clamp_to_edge);
    float4 color = tex.sample(texSampler, in.texCoord);
    color.rgb *= color.a;       // Premultiply alpha
    color *= uniforms.opacity;  // Apply opacity
    return color;
}

// MARK: - Fragment Shader (Multiply blend)

fragment float4 live2d_fragment_multiply(VertexOut in [[stage_in]],
                                          constant Uniforms& uniforms [[buffer(0)]],
                                          texture2d<float> tex [[texture(0)]]) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear,
                                  address::clamp_to_edge);
    float4 color = tex.sample(texSampler, in.texCoord);
    color.rgb *= color.a;       // Premultiply alpha
    color *= uniforms.opacity;  // Apply opacity
    return color;
}

// MARK: - Clip Mask Rendering (renders mask meshes into offscreen texture)

struct MaskVertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 clipPos;
};

vertex MaskVertexOut live2d_vertex_mask(const device VertexIn* vertices [[buffer(0)]],
                                         constant Uniforms& uniforms [[buffer(1)]],
                                         uint vid [[vertex_id]]) {
    MaskVertexOut out;
    float4 pos = float4(vertices[vid].position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * pos;  // matrixForMask as projection
    out.clipPos = out.position;
    out.texCoord = vertices[vid].texCoord;
    return out;
}

fragment float4 live2d_fragment_mask(MaskVertexOut in [[stage_in]],
                                      constant ClipUniforms& clipUniforms [[buffer(0)]],
                                      texture2d<float> tex [[texture(0)]]) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear,
                                  address::clamp_to_edge);

    // isInside test: ensure fragment is within the tile bounds (prevents bleed)
    float2 ndc = in.clipPos.xy / in.clipPos.w;
    float isInside = step(clipUniforms.clipBounds.x, ndc.x) *
                     step(clipUniforms.clipBounds.y, ndc.y) *
                     step(ndc.x, clipUniforms.clipBounds.z) *
                     step(ndc.y, clipUniforms.clipBounds.w);

    float texAlpha = tex.sample(texSampler, in.texCoord).a;
    return clipUniforms.channelFlag * texAlpha * isInside;
}

// MARK: - Clipped Drawing (meshes that sample from clip mask texture)

struct ClippedVertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 clipPos;
};

vertex ClippedVertexOut live2d_vertex_clipped(const device VertexIn* vertices [[buffer(0)]],
                                               constant Uniforms& uniforms [[buffer(1)]],
                                               constant ClipUniforms& clipUniforms [[buffer(2)]],
                                               uint vid [[vertex_id]]) {
    ClippedVertexOut out;
    float4 pos = float4(vertices[vid].position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * pos;    // screen position
    out.clipPos = clipUniforms.clipMatrix * pos;        // mask texture UV position
    out.texCoord = vertices[vid].texCoord;
    return out;
}

fragment float4 live2d_fragment_clipped(ClippedVertexOut in [[stage_in]],
                                         constant Uniforms& uniforms [[buffer(0)]],
                                         constant ClipUniforms& clipUniforms [[buffer(1)]],
                                         texture2d<float> tex [[texture(0)]],
                                         texture2d<float> maskTex [[texture(1)]]) {
    constexpr sampler texSampler(mag_filter::linear, min_filter::linear,
                                  address::clamp_to_edge);

    // Sample model texture
    float4 color = tex.sample(texSampler, in.texCoord);

    // Step 1: Premultiply alpha (straight → premultiplied)
    color.rgb *= color.a;

    // Step 2: Apply multiply color
    color.rgb *= uniforms.multiplyColor.rgb;

    // Step 3: Apply screen color
    color.rgb = color.rgb + uniforms.screenColor.rgb - color.rgb * uniforms.screenColor.rgb;

    // Step 4: Apply opacity
    color *= uniforms.opacity;

    // Sample mask texture and extract the relevant channel
    // Metal Y-flip: In Metal, texture UV (0,0) is top-left but NDC (-1,-1) is bottom-left.
    // The mask was rendered in NDC space, so we must flip Y when sampling with UV coordinates.
    float2 maskUV = in.clipPos.xy / in.clipPos.w;
    maskUV.y = 1.0 - maskUV.y;
    float4 maskSample = maskTex.sample(texSampler, maskUV) * clipUniforms.channelFlag;
    float maskVal = maskSample.r + maskSample.g + maskSample.b + maskSample.a;

    return color * maskVal;
}
