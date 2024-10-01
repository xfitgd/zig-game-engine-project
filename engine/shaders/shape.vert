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

//#extension GL_EXT_debug_printf : enable
layout(location = 0) in vec2 inPosition;


void main() {
    gl_Position = proj.proj * view.view * model.model * vec4(inPosition, 0.0, 1.0);
}