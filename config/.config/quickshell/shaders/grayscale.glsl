#version 300 es

// Systemwide True Tone grayscale screen shader.
// - Linear-light ITU-R BT.709 luminance
// - Gentle paper-temperature white balance
// - Domain-safe sRGB transfer functions

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// The screen texture is SDR sRGB. Clamp before the piecewise transfer
// functions: GLSL is allowed to evaluate both arguments of mix(), and pow()
// with a negative base would otherwise create NaNs for malformed samples.
vec3 sRGBToLinear(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    return mix(
        c / 12.92,
        pow((c + 0.055) / 1.055, vec3(2.4)),
        step(0.04045, c)
    );
}

vec3 linearTosRGB(vec3 c) {
    c = max(c, 0.0);
    return mix(
        c * 12.92,
        1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055,
        step(0.0031308, c)
    );
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Convert to linear light before using the BT.709 / sRGB luminance
    // coefficients. Weighting gamma-encoded values makes saturated colours
    // noticeably too dark or too bright.
    vec3 linearColor = sRGBToLinear(pixColor.rgb);

    // 2. Exact ITU-R BT.709 luminance
    float linearLum = dot(linearColor, vec3(0.2126, 0.7152, 0.0722));

    // Convert the resulting linear-light gray back to display sRGB.
    vec3 gray = linearTosRGB(vec3(linearLum));

    // A subtle paper-like white balance. Normalize the tint to unit BT.709
    // luminance so it changes chromaticity without changing overall exposure.
    const vec3 trueToneTint = vec3(1.01, 0.98, 0.93);
    const float tintLuminance = dot(trueToneTint, vec3(0.2126, 0.7152, 0.0722));
    vec3 finalColor = clamp(gray * (trueToneTint / tintLuminance), 0.0, 1.0);

    fragColor = vec4(finalColor, pixColor.a);
}
