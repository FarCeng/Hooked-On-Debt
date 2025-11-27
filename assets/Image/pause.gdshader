shader_type canvas_item;

uniform float blur_size : hint_range(0.0, 20.0) = 6.0;

// Tambahkan uniform ini sesuai error Godot 4
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 sum = vec4(0.0);
    vec2 pixel = TEXTURE_PIXEL_SIZE * blur_size;

    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-pixel.x, 0.0));
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(pixel.x, 0.0));
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -pixel.y));
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, pixel.y));

    COLOR = sum * 0.25;
}
