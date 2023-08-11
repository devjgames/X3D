//
//  sprite.metal
//  X3D
//
//  Created by Douglas McNamara on 8/9/23.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float2 position;
    float2 textureCoordinate;
    float4 color;
};

struct FragmentInput {
    float4 position [[position]];
    float2 textureCoordinate;
    float4 color;
};

vertex FragmentInput spriteVertexShader(uint id [[vertex_id]],
                                        const device VertexInput* vertices,
                                        constant float4x4& projection) {
    FragmentInput output;
    VertexInput input = vertices[id];
    
    output.position = projection * float4(input.position, 0, 1);
    output.textureCoordinate = input.textureCoordinate;
    output.color = input.color;
    
    return output;
}

fragment float4 spriteFragmentShader(FragmentInput input [[stage_in]],
                                     texture2d<half> texture) {
    constexpr sampler s = sampler(min_filter::nearest, mag_filter::nearest, s_address::clamp_to_edge, t_address::clamp_to_edge);
    
    return input.color * float4(texture.sample(s, input.textureCoordinate));
}


