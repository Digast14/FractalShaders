#version 330
precision highp float;

uniform vec2 u_resolution;
uniform float u_info;
uniform vec3 u_origin;
uniform vec3 u_direction;
uniform int u_time;
out vec4 colorOut;

#define PI 3.14159265359

float timeSin = sin(u_time / 300.0);
const int MAX_ROOTS = 64; // Maximum number of roots of unity


//math function
vec4 qmul(in vec4 a, in vec4 b) {
    return vec4(
    a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
    a.x * b.y + a.y * b.x + a.z * b.w - a.w * b.z,
    a.x * b.z - a.y * b.w + a.z * b.x + a.w * b.y,
    a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x
    );
}

vec4 qdiv(in vec4 a, in vec4 b) {
    float normSquared = b.x * b.x + b.y * b.y + b.z * b.z + b.w * b.w;
    if (normSquared == 0.0) return vec4(0.0);

    vec4 bConjugate = vec4(b.x, -b.yzw);

    return vec4(
    (a.x * bConjugate.x - a.y * bConjugate.y - a.z * bConjugate.z - a.w * bConjugate.w) / normSquared,
    (a.x * bConjugate.y + a.y * bConjugate.x + a.z * bConjugate.w - a.w * bConjugate.z) / normSquared,
    (a.x * bConjugate.z - a.y * bConjugate.w + a.z * bConjugate.x + a.w * bConjugate.y) / normSquared,
    (a.x * bConjugate.w + a.y * bConjugate.z - a.z * bConjugate.y + a.w * bConjugate.x) / normSquared
    );
}


vec4 qpow(vec4 c, float p) {
    vec4 sum = vec4(1, timeSin,timeSin, timeSin);
    for (int i = 1; i < p; i++) {
        sum = qmul(sum, c);
    }
    return sum;
}

vec4 qpowExact(vec4 c, float p) {
    vec4 sum = c;
    for (int i = 1; i < p; i++) {
        sum = qmul(sum, c);
    }
    return sum;
}


//quantum function function
float n = 2;

vec4 qFunction(vec4 q) {
    return q - qdiv(qpow(q, n + 1) - vec4(1, 0, 0, 0), n * qpowExact(q, n-1));;
}

vec4 qFunctionNewton(vec4 q) {
    return q - qdiv(qpowExact(q, n) - vec4(1, 0, 0, 0), n * qpowExact(q, n-1));;
}


vec4 roots[MAX_ROOTS];

// Function to calculate roots of unity
void calculateRootsOfUnity(int m, out vec4 roots[MAX_ROOTS]) {
    for (int i = 0; i < m; i++) {
        float angle = 2.0 * PI * float(i) / float(m);
        roots[i] = vec4(cos(angle), sin(angle),0,0);
    }
}

vec3 colors[6] = vec3[6](
vec3(1.0, 0.0, 0.0),
vec3(0.0, 1.0, 0.0),
vec3(0.0, 0.0, 1.0),
vec3(1.0, 1.0, 0.0),
vec3(1.0, 0.0, 1.0),
vec3(0.0, 1.0, 1.0)
);

vec3 NewtonFractalQuaternion(in vec4 c) {
    float tolerance = 0.1;
    vec4 z = c;
    int maxIteration = 200;
    for (int iteration = 0; iteration < maxIteration; iteration++) {
        z = qFunction(z);
        for (int i = 0; i < roots.length; i++) {
            if (length(z - roots[i]) < tolerance) {
                return colors[i] * 1;
            }
        }
    }
    return vec3(0.0);
}

vec3 NewtonMethod(in vec4 c) {
    vec4 z = c;
    vec4 zNudge = c + 0.000001;
    int maxIteration = 100;
    for (int iteration = 0; iteration < maxIteration; iteration++) {
        z = qFunction(z);
        zNudge = qFunction(zNudge);
        if(length(z-zNudge) > 0.1) return vec3(1);
    }
    return vec3(0.0);
}

vec3 mandelbrot(in vec4 c) {
    vec4 z = vec4(0, 0, 0, 0);
    for (int d = 0; d < 100; d++) {
        z = qpow(z, 3) + c;
        if (length(z) > 2.1) {
            return vec3(0);
        }
    }
    return vec3(1);
}

void main() {
     calculateRootsOfUnity(int(n), roots);

    float aspectRatio = u_resolution.x / u_resolution.y;
    vec2 uv = vec2(((gl_FragCoord.x / u_resolution.y) - (aspectRatio) * 0.5), ((gl_FragCoord.y / u_resolution.y) - 0.5));
    vec2 ro = vec2(-u_origin.y, u_origin.x);
    vec3 color = NewtonMethod(vec4(uv / u_info + ro, 0,0));
    colorOut = vec4(vec3(color), 1.0);
}
