//
//  shaders.metal
//  X3D
//
//  Created by Douglas McNamara on 5/15/23.
//

#include <metal_stdlib>
using namespace metal;

#define MAX_LIGHTS 16
#define LINEAR_CLAMP_TO_EDGE 1
#define LINEAR_REPEAT 2
#define NEAREST_CLAMP_TO_EDGE 3
#define NEAREST_REPEAT 4


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
    float radius;
};

struct VertexUniforms {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
    float4x4 modelIT;
    float4 ambientColor;
    float4 diffuseColor;
    float4 color;
    uint8_t lightingEnabled;
    uint8_t vertexColorEnabled;
    uint8_t lightCount;
    float3 warpAmplitudes;
    float warpFrequency;
    float warpTime;
    float warpSpeed;
    uint8_t warpEnabled;
    Light lights[MAX_LIGHTS];
};

struct FragmentUniforms {
    uint8_t textureEnabled;
    uint8_t textureSampler;
    uint8_t texture2Enabled;
    uint8_t texture2Sampler;
};

vertex FragmentInput vertexShader(uint id [[vertex_id]],
                                  const device VertexInput* vertices,
                                  constant VertexUniforms& uniforms) {
    FragmentInput output;
    VertexInput input = vertices[id];
    float4 color = uniforms.color;
    float3 objPos = input.position;
    
    if(uniforms.warpEnabled != 0) {
        float f = uniforms.warpFrequency;
        float t = uniforms.warpTime * uniforms.warpSpeed;
        
        objPos = float3(objPos.x + uniforms.warpAmplitudes.x * sin(f * objPos.z + t) * cos(f * objPos.y + t),
                        objPos.y + uniforms.warpAmplitudes.y * cos(f * objPos.x + t) * cos(f * objPos.z + t),
                        objPos.z + uniforms.warpAmplitudes.z * cos(f * objPos.y + t) * sin(f * objPos.x + t)
                        );
    }
    
    if(uniforms.vertexColorEnabled != 0) {
        color = input.color;
    }
    if(uniforms.lightingEnabled != 0) {
        float3 position = (uniforms.model * float4(objPos, 1)).xyz;
        float3 normal = normalize((uniforms.modelIT * float4(input.normal, 0)).xyz);
        float4 diffuseColor = uniforms.diffuseColor;
        
        color = uniforms.ambientColor;
        if(uniforms.vertexColorEnabled != 0) {
            color *= input.color;
            diffuseColor *= input.color;
        }
        for(int i = 0; i != uniforms.lightCount; i++) {
            float3 lightOffset = uniforms.lights[i].position - position;
            float3 lightNormal = normalize(lightOffset);
            float diffI = clamp(dot(lightNormal, normal), 0.0, 1.0);
            float atten = 1.0 - clamp(length(lightOffset) / uniforms.lights[i].radius, 0.0, 1.0);
            
            color += atten * diffI * diffuseColor * uniforms.lights[i].color;
        }
    }
    output.position = uniforms.projection * uniforms.view * uniforms.model * float4(objPos, 1.0);
    output.textureCoordinate = input.textureCoordinate;
    output.textureCoordinate2 = input.textureCoordinate2;
    output.color = color;
    
    return output;
}

fragment float4 fragmentShader(FragmentInput input [[stage_in]],
                               texture2d<half> texture,
                               texture2d<half> texture2,
                               constant FragmentUniforms& uniforms) {
    float4 color = input.color;
    
    constexpr sampler snc = sampler(min_filter::nearest, mag_filter::nearest, s_address::clamp_to_edge, t_address::clamp_to_edge);
    constexpr sampler snr = sampler(min_filter::nearest, mag_filter::nearest, s_address::repeat, t_address::repeat);
    constexpr sampler slc = sampler(min_filter::linear, mag_filter::linear, s_address::clamp_to_edge, t_address::clamp_to_edge);
    constexpr sampler slr = sampler(min_filter::linear, mag_filter::linear, s_address::repeat, t_address::repeat);
    
    if(uniforms.textureEnabled != 0) {
        if(uniforms.textureSampler == LINEAR_CLAMP_TO_EDGE) {
            color *= float4(texture.sample(slc, input.textureCoordinate));
        } else if(uniforms.textureSampler == LINEAR_REPEAT) {
            color *= float4(texture.sample(slr, input.textureCoordinate));
        } else if(uniforms.textureSampler == NEAREST_CLAMP_TO_EDGE) {
            color *= float4(texture.sample(snc, input.textureCoordinate));
        } else {
            color *= float4(texture.sample(snr, input.textureCoordinate));
        }
    }
    if(uniforms.texture2Enabled != 0) {
        if(uniforms.texture2Sampler == LINEAR_CLAMP_TO_EDGE) {
            color *= float4(texture2.sample(slc, input.textureCoordinate2));
        } else if(uniforms.texture2Sampler == LINEAR_REPEAT) {
            color *= float4(texture2.sample(slr, input.textureCoordinate2));
        } else if(uniforms.texture2Sampler == NEAREST_CLAMP_TO_EDGE) {
            color *= float4(texture2.sample(snc, input.textureCoordinate2));
        } else {
            color *= float4(texture2.sample(snr, input.textureCoordinate2));
        }
    }
    return  color;
}


