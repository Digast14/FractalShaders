#version 330 core
precision highp float;
#define PI 3.14159265359


uniform vec2 u_resolution;
uniform float u_info;
uniform vec3 u_origin;
uniform vec3 u_direction;
out vec4 colorOut;

float ITERATIONS = 30.0;
float THRESHOLD = 10.0;

float MAX_DIST = 10.0;
int MAX_STEPS = 1500;

float SURF_THRESHOLD = 0.001;

float ROT_SPEED = 0.1;

vec4 quatsqr(vec4 z) {
    float a = z.r;
    float b = z.g;
    float c = z.b;
    float d = z.a;

    float r = a * a - b * b - c * c - d * d;
    float i = 2.0 * a * b + 2.0 * d * c;
    float j = 2.0 * a * c - 2.0 * b * d;
    float k = 2.0 * a * d + 2.0 * b * c;

    return vec4(r, i, j, k);
}


float fractal(vec4 c) {
    vec4 z = vec4(0);
    float l = 0.0;
    for (int i = 0;i < int(ITERATIONS); i++) {
        z = quatsqr(z) + c;
        if (dot(z, z) > THRESHOLD) break;
        l += 1.0;
    }
    if (l > ITERATIONS - 1.0)return 0.0;
    float sl = l - log2(log2(dot(z, z))) + 4.0;
    l = 1.0 - sl / ITERATIONS;
    return l;
}


float mapTheWorld(vec4 point) {
    return fractal(point);
}


vec3 getNormal(vec3 point) {
    float d = 0.02;

    vec4 p = vec4(point, 0.0);
    vec4 dx = vec4(vec3(d, 0, 0), 0.0);
    vec4 dy = vec4(vec3(0, d, 0), 0.0);

    float dist = mapTheWorld(p);
    float DX = dist - mapTheWorld(p + dx);
    float DY = dist - mapTheWorld(p + dy);

    return normalize(vec3(DX, DY, 0));
}

vec3 raymarch(vec3 rayOrigin, vec3 rayDirection){
    vec4 pointer = vec4(rayOrigin, 0.0);
    vec4 direction = vec4(rayDirection, 0.0);

    float dist = mapTheWorld(pointer);
    float steps = 0.0;

    float minDist = dist;

    for(int i = 0; i < MAX_STEPS; i++){
        if(dist <= SURF_THRESHOLD) break;
        if(dist >= MAX_DIST) break;
        pointer += direction*dist*0.03;
        dist = mapTheWorld(pointer);
        minDist = (dist < minDist)?dist:minDist;
        steps += 1.0;
    }



    return vec3(minDist, steps, length(pointer.xyz-rayOrigin));
}


vec3 rotateByVec3(in vec3 vector, in vec3 axis, in float angle) {
    axis = normalize(axis);
    float cosAngle = cos(angle);
    return vector * cosAngle + (cross(axis, vector)) * sin(angle) + axis * (dot(axis, vector)) * (1 - cosAngle);
}

void main() {
    //make necessary variables
    float aspectRatio = u_resolution.x / u_resolution.y;
    vec2 uv = vec2(((gl_FragCoord.x / u_resolution.y) - (aspectRatio) * 0.5), ((gl_FragCoord.y / u_resolution.y) - 0.5));
    vec3 ro = vec3(u_origin.x * u_info, u_origin.y * u_info, u_origin.z * u_info);
    vec3 rd = u_direction;
    vec3 camLeftNormal = cross(u_direction, vec3(0.0, 0.0, 1.0));
    vec3 camUpNormal = cross(u_direction, camLeftNormal);

    float test = 0;

    //rotate up or down
    rd = rotateByVec3(rd, camUpNormal, uv.x);
    //roate left or right
    rd = rotateByVec3(rd, camLeftNormal, uv.y);

    //raymarching
    vec3 march = raymarch(ro, rd);

    vec3 col = vec3(0.0);

    float l = march.x;
    float steps = march.y;
    float depth = march.z;

    if(l < SURF_THRESHOLD) {
        vec3 normal = getNormal(ro + rd*depth);
        col = vec3(1.0);
        vec3 shadowCol = col * dot(normal,-normalize(vec3(1.0,1.0,0.0)));
        col = mix(col, shadowCol, 0.9);
        col = mix(col, abs(normal), 0.5);
    }else{
        col += vec3(0.2)/l;
        col *= col;
    }
    colorOut = vec4(col,1.0);
}
