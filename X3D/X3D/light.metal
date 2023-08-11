//
//  shaders.metal
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#include <metal_stdlib>
using namespace metal;

#define MAX_LIGHTS 16

#define AMBIENT 0
#define DIRECTIONAL 1
#define POINT 2


struct VertexInput {
    float3 position;
    float2 textureCoordinate;
    float3 normal;
};

struct FragmentInput {
    float4 position [[position]];
    float2 textureCoordinate;
    float4 color;
};

struct Light {
    uint8_t type;
    float3 vector;
    float4 color;
    float range;
};

struct VertexData {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
    float4x4 modelIT;
    float4 color;
    uint8_t lightCount;
    Light lights[MAX_LIGHTS];
};

struct FragmentData {
    uint8_t textureEnabled;
    uint8_t linear;
};

vertex FragmentInput lightVertexShader(uint id [[vertex_id]],
                                       const device VertexInput* vertices,
                                       constant VertexData& data) {
    FragmentInput output;
    VertexInput input = vertices[id];
    float4 position = data.model * float4(input.position, 1);
    float3 normal = normalize((data.modelIT * float4(input.normal, 0)).xyz);
    
    output.color = float4(0, 0, 0, 1);
    
    for(int i = 0; i != data.lightCount; i++) {
        Light light = data.lights[i];
        
        if(light.type == AMBIENT) {
            output.color += light.color;
        } else if(light.type == DIRECTIONAL) {
            float3 lightNormal = normalize(-light.vector);
            float lDotN = clamp(dot(lightNormal, normal), 0.0, 1.0);
            
            output.color += lDotN * data.color * light.color;
        } else {
            float3 lightOffset = light.vector - position.xyz;
            float3 lightNormal = normalize((lightOffset));
            float lDotN = clamp(dot(lightNormal, normal), 0.0, 1.0);
            float atten = 1.0 - clamp(length(lightOffset) / light.range, 0.0, 1.0);
            
            output.color += atten * lDotN * data.color * light.color;
        }
    }
    output.textureCoordinate = input.textureCoordinate;
    output.position = data.projection * data.view * position;
    
    return output;
}

fragment float4 lightFragmentShader(FragmentInput input [[stage_in]],
                                    texture2d<half> texture,
                                    constant FragmentData& data) {
    float4 color = input.color;

    constexpr sampler sn = sampler(min_filter::nearest, mag_filter::nearest, s_address::repeat, t_address::repeat);
    constexpr sampler sl = sampler(min_filter::linear, mag_filter::linear, s_address::repeat, t_address::repeat);
    
    if(data.textureEnabled != 0) {
        if(data.linear != 0) {
            color *= float4(texture.sample(sl, input.textureCoordinate));
        } else {
            color *= float4(texture.sample(sn, input.textureCoordinate));
        }
    }
    return  color;
}


