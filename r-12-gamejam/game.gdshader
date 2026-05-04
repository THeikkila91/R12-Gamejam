shader_type canvas_item;

void fragment() {
    // kertoo gridin koon
    vec2 grid_size = vec2(32.0, 32.0);
    // logiikka bordering piirtämiseen
    vec2 grid = mod(UV * vec2(320.0, 640.0), grid_size);
    bool line = grid.x < 1.0 || grid.y < 1.0;

    if (line) {
        COLOR = vec4(0.2, 0.2, 0.2, 1.0); // tumman harmaat borderit
    } else {
        COLOR = vec4(0.01, 0.06, 0.07, 1.0); // This is your BACKGROUND color (Dark Blue)
    }
}