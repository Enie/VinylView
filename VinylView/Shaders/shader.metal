//
//  shader.metal
//  VinylView
//
//  Created by Enie Weiß on 12.04.23.
//

#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>

using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOut {
    float2 texCoords [[user(texturecoords)]];
    float4 position [[position]];
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoords = float2(in.texCoords.x, 1.0 - (in.texCoords.y));
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d_array<float> imageArray [[texture(0)]],
                              sampler samplerState [[sampler(0)]],
                              constant int &frame [[buffer(0)]]) {
    constexpr sampler defaultSampler(mag_filter::linear,
                                     min_filter::linear);

    return imageArray.sample(defaultSampler, in.texCoords, frame);
}
