//
//  shader.metal
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

#include <metal_stdlib>
using namespace metal;

#define MAX_LIGHTS 16

struct VertexInput {
    float3 position;
    float2 textureCoordinate;
    float2 textureCoordinate2;
    float3 normal;
    float4 color;
};

struct FragmentInput {
    float4 position [[position]];
    float2 textureCoordinate;
    float2 textureCoordinate2;
    float4 color;
};

struct Light {
    float3 position;
    float4 color;
    float range;
};

struct VertexData {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
    float4x4 modelIT;
    float4 ambientColor;
    float4 diffuseColor;
    float4 color;
    uint8_t vertexColorEnabled;
    uint8_t lightingEnabled;
    uint8_t lightCount;
};

struct FragmentData {
    uint8_t textureEnabled;
    uint8_t texture2Enabled;
    uint8_t texture2Linear;
};

vertex FragmentInput vertexShader(uint id [[vertex_id]],
                                  const device VertexInput* vertices,
                                  constant VertexData& data,
                                  constant Light * lights) {
    VertexInput input = vertices[id];
    float4 color = data.color;
    float4 position = data.model * float4(input.position, 1);
    
    if(data.vertexColorEnabled != 0) {
        color = input.color;
    }
    
    if(data.lightingEnabled != 0) {
        float3 normal = normalize((data.modelIT * float4(input.normal, 0)).xyz);
        
        color = data.ambientColor;
        
        for(int i = 0; i != data.lightCount; i++) {
            Light light = lights[i];
            float3 lightOffset = light.position - position.xyz;
            float3 lightNormal = normalize(lightOffset);
            float lDotN = clamp(dot(lightNormal, normal), 0.0, 1.0);
            float atten = 1.0 - clamp(length(lightOffset) / light.range, 0.0, 1.0);
            
            color += lDotN * atten * data.diffuseColor * light.color;
        }
    }
    
    FragmentInput output;
    
    output.position = data.projection * data.view * position;
    output.textureCoordinate = input.textureCoordinate;
    output.textureCoordinate2 = input.textureCoordinate2;
    output.color = color;
    
    return output;
}

fragment float4 fragmentShader(FragmentInput input [[stage_in]],
                               texture2d<half> texture,
                               texture2d<half> texture2,
                               constant FragmentData& data) {
    constexpr sampler tex = sampler(min_filter::nearest, mag_filter::nearest, s_address::repeat, t_address::repeat);
    constexpr sampler tex2Linear = sampler(min_filter::linear, mag_filter::linear, s_address::clamp_to_edge, t_address::clamp_to_edge);
    constexpr sampler tex2Nearest = sampler(min_filter::nearest, mag_filter::nearest, s_address::clamp_to_edge, t_address::clamp_to_edge);
    
    float4 color = input.color;
    
    if(data.textureEnabled != 0) {
        color *= float4(texture.sample(tex, input.textureCoordinate));
    }
    if(data.texture2Enabled != 0) {
        if(data.texture2Linear != 0) {
            color *= float4(texture2.sample(tex2Linear, input.textureCoordinate2));
        } else {
            color *= float4(texture2.sample(tex2Nearest, input.textureCoordinate2));
        }
    }
    return color;
}

