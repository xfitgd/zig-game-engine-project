#version 450

layout(binding = 3) uniform UniformBufferObject3 {
    mat4 mat;
} colormat;
layout(binding = 4) uniform sampler2D texSampler;

layout(location = 0) in vec2 fragTexCoord;
layout(location = 0) out vec4 outColor;

void main() {
    outColor = colormat.mat * texture(texSampler, fragTexCoord);
}