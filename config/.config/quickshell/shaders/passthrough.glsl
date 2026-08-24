#version 300 es

// Identity shader - renders the screen unchanged. Used as the "off" state
// because clearing decoration:screen_shader to empty and setting a path
// again can silently fail; toggling between two real shaders always works.

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    fragColor = texture(tex, v_texcoord);
}
