//
//  Light.metal
//  X3D
//
//  Created by Douglas McNamara on 2/17/23.
//

#include <metal_stdlib>
#include <metal_raytracing>
using namespace metal;
using namespace metal::raytracing;

#define MAX_LIGHTS 16

struct VertexInput {
    float2 coord;
    float3 position;
    float3 normal;
    float4 ambientColor;
    float4 diffuseColor;
};

struct FragmentInput {
    float4 position [[position]];
    float3 modelPosition;
    float3 normal;
    float4 ambientColor;
    float4 diffuseColor;
};

struct Light {
    float3 position;
    float4 color;
    float radius;
};

struct Uniforms {
    float sampleRadius;
    float aoLength;
    float aoStrength;
    uint8_t sampleCount;
    uint8_t lightCount;
    Light lights[MAX_LIGHTS];
};

vertex FragmentInput lightVertexShader(uint vertexID [[vertex_id]],
                                       const device VertexInput* vertices,
                                       constant float4x4& transform) {
    FragmentInput output;
    VertexInput input = vertices[vertexID];
    
    output.position = transform * float4(input.coord, 0, 1);
    output.modelPosition = input.position;
    output.normal = normalize(input.normal);
    output.ambientColor = input.ambientColor;
    output.diffuseColor = input.diffuseColor;
    
    return output;
}

fragment float4 lightFragmentShader(FragmentInput input [[stage_in]],
                                    primitive_acceleration_structure accel,
                                    const device float3* samples,
                                    constant Uniforms& uniforms) {
    float4 color = input.ambientColor;
    float3 position = input.modelPosition;
    float3 normal = normalize(input.normal);
    
    for(int i = 0; i != uniforms.lightCount; i++) {
        Light light = uniforms.lights[i];
        float3 offset = light.position - position;
        float3 lNormal = normalize(offset);
        float lDotN = dot(lNormal, normal);
        if(lDotN > 0) {
            float atten = 1.0 - clamp(length(offset) / light.radius, 0.0, 1.0);
            if(atten > 0) {
                float shadow = 0;
                
                for(int j = 0; j != uniforms.sampleCount; j++) {
                    float3 s = samples[j];
                    ray r;
                    intersector<triangle_data> isector;
                    intersection_result<triangle_data> result;
                    
                    r.origin = position + lNormal * 0.1;
                    r.direction = light.position + s * uniforms.sampleRadius - r.origin;
                    r.max_distance = length(r.direction);
                    r.direction = normalize(r.direction);
                    r.min_distance = 0;
                    result = isector.intersect(r, accel);
                    if(result.type == intersection_type::none) {
                        shadow += 1.0f / float(uniforms.sampleCount);
                    }
                }
                for(int j = 0; j != uniforms.sampleCount; j++) {
                    float3 s = samples[j];
                    
                    if(dot(s, normal) > 0.1) {
                        ray r;
                        intersector<triangle_data> isector;
                        intersection_result<triangle_data> result;
                        
                        r.origin = position + normal * 0.1;
                        r.direction = s;
                        r.max_distance = uniforms.aoLength;
                        r.min_distance = 0;
                        result = isector.intersect(r, accel);
                        if(result.type != intersection_type::none) {
                            shadow = clamp(shadow - uniforms.aoStrength / float(uniforms.sampleCount), 0.0, 1.0);
                        }
                    }
                }
                color += lDotN * atten * shadow * light.color * input.diffuseColor;
            }
        }
    }
    return color;
}


