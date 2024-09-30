#version 450

layout(location = 0) out vec4 outColor;

layout(binding = 3) uniform UniformBufferObject0 {
    vec4 fragColor;
} color;


void main() {
    outColor = color.fragColor;
}