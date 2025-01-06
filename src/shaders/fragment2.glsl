#version 330 core
precision highp float;

uniform vec2 u_resolution;
uniform float u_info;
uniform vec3 u_origin;
uniform vec3 u_direction;
out vec4 colorOut;

float mandelbrot(in vec3 v, float quality) {
    vec2 z = vec2(0, 0);
    for (int d = 0; ; d++) {
        z = vec2(pow(z.x, 2) - pow(z.y, 2) + v.x / u_info, (z.x + z.x) * z.y + v.y / u_info);
        if (length(z) > 2.1) {
            //return d;
            return d - log(log(length(z))/log(2.0))/log(2.0);
        } else if (d > quality) {
            break;
        }
    }
    return quality;
}


float sdfPlane(in vec3 point, in vec3 normal, float h) {
    return dot(point, normalize(normal));
}


float mapTheWorld(in vec3 pos) {
    float res = 512;
    float mandelbrotHeight = mandelbrot(pos, res);
    float plane0 = sdfPlane(pos, vec3(0.0, 0.0, 1.0), 0) - pow(mandelbrotHeight / res,0.05)*0.2;
    return plane0;
}


vec3 calculateNormal(in vec3 p)
{
    const vec3 small_step = vec3(0.001, 0.0, 0.0);
    float gradient_x = mapTheWorld(p + small_step.xyy) - mapTheWorld(p - small_step.xyy);
    float gradient_y = mapTheWorld(p + small_step.yxy) - mapTheWorld(p - small_step.yxy);
    vec3 normal = vec3(gradient_x, gradient_y, 0.0);
    return normalize(normal);
}


vec3 ray_march(in vec3 ro, in vec3 rd) {
    float distanceTravelled = 0.0;
    const float maxSteps = 256.0;
    const float minDistance = 0.001;
    const float maxDistance = 10000.0;
    vec3 light = vec3(0.0, 1.0, -1.0);

    for (int i = 0; i < maxSteps && distanceTravelled < maxDistance; i++) {
        vec3 currentPos = ro + (distanceTravelled * rd);
        float st = mapTheWorld(currentPos);
        if (st < minDistance) {
            vec3 normal =  calculateNormal(currentPos);
            vec3 ambientOcclusion = vec3(i / maxSteps);
            float lighting = dot(normal,light);
            return vec3(normal-ambientOcclusion);
        }
        distanceTravelled += st;
    }
    float skyAngle = 1.0 - normalize(rd).z;
    skyAngle *= 0.5;
    return vec3(skyAngle, 0.0, skyAngle + 0.2);
}

vec3 rotateByVec3(in vec3 vector, in vec3 axis, in float angle) {
    axis = normalize(axis);
    float cosAngle = cos(angle);
    return vector * cosAngle + (cross(axis, vector)) * sin(angle) + axis * (dot(axis, vector)) * (1 - cosAngle);
}



void main() {
    //make necessary variables
    float aspectRatio = u_resolution.x / u_resolution.y;
    vec2 uv = vec2(((gl_FragCoord.x / u_resolution.y) - (aspectRatio) * 0.5), ((gl_FragCoord.y / u_resolution.y)-0.5));
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
    vec3 color = ray_march(ro, rd);
    colorOut = vec4(color, 1.0);
}
