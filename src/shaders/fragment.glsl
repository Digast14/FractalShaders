#version 330 core
precision highp float;
uniform vec2 u_resolution;

uniform vec3 u_origin;
uniform vec3 u_direction;
out vec4 colorOut;


//sdf
float sdfSphere(in vec3 p, in vec3 c, float r) {
    return length(p - c) - r;
}
float sdfPlane(in vec3 point, in vec3 normal, float h) {
    return dot(point, normalize(normal)) + h;
}
float maxComp(vec3 v) {
    return max(v.x, max(v.y, v.z));
}
float sdfBox(vec3 point, vec3 boxCenter, vec3 boxSize) {
    vec3 q = abs(point - boxCenter) - boxSize;
    return length(max(q, 0.0)) + min(maxComp(q), 0.0);
}


float mapTheWorld(in vec3 pos) {
    float box0 = sdfBox(pos, vec3(0, 0, 0.5), vec3(0.5, 0.5, 0.5));
    float plane0 = sdfPlane(pos, vec3(0.0, 0.0, 1.0), 0);
    float sphere0 = sdfSphere(pos, vec3(1, 5, 2), 0.5);
    return min(plane0, min(box0, sphere0));
}

vec3 calculateNormal(in vec3 p)
{
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    float gradient_x = mapTheWorld(p + small_step.xyy) - mapTheWorld(p - small_step.xyy);
    float gradient_y = mapTheWorld(p + small_step.yxy) - mapTheWorld(p - small_step.yxy);
    float gradient_z = mapTheWorld(p + small_step.yyx) - mapTheWorld(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}


float shadow( in vec3 ro, in vec3 rd , float maxt, float w )
{
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = mapTheWorld(ro + t*rd);
        res = min( res, h/(w*t) );
        t += clamp(h, 0.005, 0.50);
        if( res<-1.0 || t>maxt ) break;
    }
    res = max(res,-1.0);
    return 0.25*(1.0+res)*(1.0+res)*(2.0-res);
}


vec3 ray_march(in vec3 ro, in vec3 rd) {
    float distanceTravelled = 0.0;
    const float maxSteps = 256.0;
    const float minDistance = 0.001;
    const float maxDistance = 10000.0;
    vec3 light = vec3(10.0, 10.0, 10.0);

    for (int i = 0; i < maxSteps && distanceTravelled < maxDistance; i++) {
        vec3 currentPos = ro + (distanceTravelled * rd);
        float st = mapTheWorld(currentPos);
        if (st < minDistance) {
            vec3 lightRayDirection = light - currentPos;
            float shadow = shadow(currentPos, normalize(lightRayDirection), length(lightRayDirection), 0.1);
            float ambientOcclusion = i / maxSteps;
            float lightNormal = dot(normalize(lightRayDirection), calculateNormal(currentPos));

            return vec3(lightNormal * shadow - ambientOcclusion);
        }
        distanceTravelled += st;
    }
    float skyAngle = 1.0 - normalize(rd).z * 0.8;
    return vec3(0.0, 0.0, skyAngle + 0.2);
}


vec3 rotateByVec3(in vec3 vector, in vec3 axis, in float angle) {
    axis = normalize(axis);
    float cosAngle = cos(angle);
    return vector * cosAngle + (cross(axis, vector)) * sin(angle) + axis * (dot(axis, vector)) * (1 - cosAngle);
}


void main() {
    //make necessary variables
    float aspectRatio = u_resolution.x / u_resolution.y;
    vec2 uv = vec2(((gl_FragCoord.x / u_resolution.y) - (aspectRatio) * 0.5), ((gl_FragCoord.y / u_resolution.y)-0.5));;
    vec3 ro = u_origin;
    vec3 rd = u_direction;

    vec3 camLeftNormal = cross(u_direction, vec3(0.0, 0.0, 1.0));
    vec3 camUpNormal = cross(u_direction, camLeftNormal);

    //rotate up or down
    rd = rotateByVec3(rd, camUpNormal, uv.x);
    //roate left or right
    rd = rotateByVec3(rd, camLeftNormal, uv.y);

    //raymarching
    vec3 color = ray_march(ro, rd);
    colorOut = vec4(color, 1.0);
}