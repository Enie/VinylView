//
//  radialBlur.metal
//  VinylView
//
//  Created by Enie Weiß on 01.10.22.
//

#include <metal_stdlib>
using namespace metal;

struct RadialBlurOptions {
    float2 origin;
    float width;
};

struct Seed {
    float value;
};

kernel void radialBlur(
                       texture2d<float,access::sample>  in     [[ texture(0) ]],
                       texture2d<float,access::write>  out     [[ texture(1) ]],
                       constant float &samplingRadius [[ buffer(0) ]],
                       uint2    id     [[ thread_position_in_grid ]]
                       )
{
    const float inWidth = in.get_width();
    const float outWidth = out.get_width();
    const float outHeight = out.get_height();
    const float radiusW = outWidth/2;
    const float radiusH = outHeight/2;
    const float ratio = float(outWidth)/float(inWidth);

    constexpr sampler sampler(coord::pixel, filter::bicubic, address::clamp_to_edge);

    float4 sampled = float4(0,0,0,0);
    float samples = 0;
    int sampleSteps = float(inWidth)*0.125*samplingRadius;
    for(int i = -sampleSteps; i <= sampleSteps; i++) {
        float i_f = (float(i)/360*M_PI_F*2)/samplingRadius;
        float weight = (cos(float(i)/float(sampleSteps)*M_PI_F) + 1.0)/2.0 ;
        float2x2 rotationMatrix = float2x2(cos(i_f),sin(i_f),-sin(i_f),cos(i_f));
        float2 rotatedId = rotationMatrix * float2(id.x-radiusW,id.y-radiusH);
        rotatedId.x = rotatedId.x+radiusW;
        rotatedId.y = rotatedId.y+radiusH;
        sampled += in.sample(sampler, rotatedId / ratio)*weight*ratio;
        samples += weight;
    }
    sampled = sampled/samples;

    out.write( sampled, uint2(id) );
}

kernel void fit(
                       texture2d<float,access::sample>  in     [[ texture(0) ]],
                       texture2d<float,access::write>  out     [[ texture(1) ]],
                       uint2    id     [[ thread_position_in_grid ]]
                       )
{
    const float inWidth = in.get_width();
    const float outWidth = out.get_width();
    const float ratio = float(outWidth)/float(inWidth);
    
    constexpr sampler sampler(coord::pixel, filter::bicubic, address::clamp_to_edge);
    
    float4 sampled = in.sample(sampler, float2(id)/ratio);
    out.write( sampled, uint2(id) );
}

kernel void generateNoiseLine(
                          texture2d<float,access::read_write>  inout     [[ texture(0) ]],
                          constant Seed &seed [[ buffer(0) ]],
                          uint2    id     [[ thread_position_in_grid ]]
                          )
{
    const float width = inout.get_width();
    const float height = inout.get_height();
    const float noiseHeight = width*0.015;

    float4 imageColor = float4(0,0,0,1.0);
    
    float offset = M_2_PI_F * seed.value/2;
    float ratio = width/400.0; // noise looks good at 400px wide, so lets try to scale all other sizes to that.

    if (id.y > height/2 - noiseHeight && id.y < height/2 + noiseHeight) {
        float value = (
                       + (sin(id.x/width*1923 + offset)+1.0)/4.0 * ratio
                       + (cos(id.x/width*M_2_PI_F+id.x/width*6327 + 0.81 + offset)+.6)/2.0 * ratio
                       ) / 2.0;
        imageColor = float4(value,value,value,1.0);
    }

    inout.write( imageColor, uint2(id) );
}

float t(float2 center, uint2 point) {
    float2 d = float2(point) - center;
    float angle = atan2(d.y, d.x);
    if (angle < 0) {
        angle += 2 * M_PI_F;
    }
    float t_value = angle / (2 * M_PI_F);
    return t_value;
}

float2 sinus_circle(float2 center, float r, float f, float t) {
    float angle = 2 * M_PI_F * t;
    float sine_value = sin(f * angle);
    float2 coord = center + r * (1 + sine_value) * float2(cos(angle), sin(angle));
    return coord;
}

kernel void generateNoise(
                              texture2d<float,access::read_write>  inout     [[ texture(0) ]],
                              constant Seed &seed [[ buffer(0) ]],
                              uint2    id     [[ thread_position_in_grid ]]
                              )
{
    const float width = inout.get_width();
    const float height = inout.get_height();
    const float2 center = float2(width/2, height/2);
    
    float4 imageColor = float4(0,0,0,1.0);
    
    float time = M_2_PI_F * seed.value/2;
    float radius = length(float2(id) - center);
    float circumference = 2*M_2_PI_F*radius;
    float ratio = width/400.0; // noise looks good at 400px wide, so lets try to scale all other sizes to that.
    
    float t_xy = t(center, id);
    float f = 20;
    float offset = M_2_PI_F * float(radius) * (float(radius) - 1.0);
    
    // draw spiral
    float value = sin((radius + t_xy*M_PI_F*2) * 2);
    // add movement to highlighted grooves
    if (value > 0.0) {
        value *= sin(time*3 + offset + f * (t_xy * circumference) * M_PI_F*2 * ratio) * 0.5 + 0.25;
    }
    // scale from [-1,1] to [0,1]
    value = (value * 0.5  + 0.5);
    
    // only show grooves in highlighted area
    value *= pow(sin(sin(time/2 * M_PI_F)/30.0 + M_PI_F + t_xy*M_PI_F*4), 3) * 0.25;
    
    // write image color into texture
    imageColor = float4(value,value,value,1.0);
    inout.write( imageColor, uint2(id) );
}

