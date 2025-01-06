#version 330 core

layout(location = 0) in vec2 position; // Position of the vertex in 2D

void main() {
    gl_Position = vec4(position, 0.0, 1.0); // Pass through to clip space
}