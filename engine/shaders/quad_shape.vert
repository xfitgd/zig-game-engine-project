#version 450

layout(binding = 0) uniform UniformBufferObject0 {
    mat4 model;
} model;
layout(binding = 1) uniform UniformBufferObject1 {
    mat4 view;
} view;
layout(binding = 2) uniform UniformBufferObject2 {
    mat4 proj;
} proj;
vec2 quad[6] = {vec2(-1,1),vec2(1,1),vec2(-1,-1),vec2(1,1),vec2(1,-1),vec2(-1,-1)};

void main() {
    gl_Position = proj.proj * view.view * model.model * vec4(quad[gl_VertexIndex], 0.0, 1.0);
}