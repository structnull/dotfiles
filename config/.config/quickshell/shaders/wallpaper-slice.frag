#version 440

// qsb --qt6 --qsbversion 64 -o wallpaper-slice.frag.qsb wallpaper-slice.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 qt_SubRect_previewImage;
    vec4 backgroundColor;
    vec4 borderColor;
    vec2 tileSize;
    float imageAspect;
    float skew;
    float expansion;
} u;

layout(binding = 1) uniform sampler2D previewImage;

float edgeDistance(vec2 pixel)
{
    float slope = u.skew / u.tileSize.y;
    float left = max(u.skew, 0.0) - pixel.y * slope;
    float side = min(pixel.x - left, left + u.tileSize.x - abs(u.skew) - pixel.x);
    return min(side * inversesqrt(1.0 + slope * slope), min(pixel.y, u.tileSize.y - pixel.y));
}

float coverage(float distance)
{
    float halfPixel = max(fwidth(distance) * 0.5, 0.001);
    return smoothstep(-halfPixel, halfPixel, distance);
}

void main()
{
    vec2 pixel = qt_TexCoord0 * (u.tileSize + vec2(8.0, 14.0)) - vec2(2.0);
    float distance = edgeDistance(pixel);
    float tileAlpha = coverage(distance);

    vec2 shadowOffset = vec2(2.0, 5.0) * (1.0 + u.expansion);
    float shadowAlpha = coverage(edgeDistance(pixel - shadowOffset)) * mix(0.32, 0.5, u.expansion);
    float borderAlpha = 1.0 - coverage(distance - mix(1.0, 3.0, u.expansion));

    vec4 artwork = u.backgroundColor;
    if (u.imageAspect > 0.0) {
        float ratio = (u.tileSize.x / u.tileSize.y) / u.imageAspect;
        vec2 crop = min(vec2(ratio, 1.0 / ratio), vec2(1.0));
        vec2 uv = clamp((pixel / u.tileSize - 0.5) * crop + 0.5, 0.0, 1.0);
        vec4 photo = texture(previewImage, u.qt_SubRect_previewImage.xy + uv * u.qt_SubRect_previewImage.zw);
        artwork = photo + artwork * (1.0 - photo.a);
        artwork = mix(artwork, u.backgroundColor, 0.42 * (1.0 - u.expansion));
    }

    vec4 border = u.borderColor * borderAlpha;
    vec4 tile = (border + artwork * (1.0 - border.a)) * tileAlpha;
    fragColor = (tile + u.backgroundColor * shadowAlpha * (1.0 - tile.a)) * u.qt_Opacity;
}
