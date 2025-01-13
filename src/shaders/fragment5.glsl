#version 330
precision highp float;

uniform vec2 u_resolution;
uniform float u_info;
uniform vec3 u_origin;
uniform vec3 u_direction;
uniform int u_time;
uniform int u_mode;

out vec4 colorOut;

#define PI 3.14159265359

float timeSin = sin(u_time / 300.0);

vec3 colors[12] = vec3[12](
vec3(1.0, 0.0, 0.0),
vec3(0.0, 1.0, 0.0),
vec3(0.0, 0.0, 1.0),
vec3(1.0, 1.0, 0.0),
vec3(1.0, 0.0, 1.0),
vec3(0.0, 1.0, 1.0),
vec3(1.0, 0.0, 0.0),
vec3(0.0, 1.0, 0.0),
vec3(0.0, 0.0, 1.0),
vec3(1.0, 1.0, 0.0),
vec3(1.0, 0.0, 1.0),
vec3(0.0, 1.0, 1.0)
);

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

//expanded functions
vec4 qsin(vec4 q){
    float a = q.x;
    vec3 v = vec3(q.yzw);
    float vabs = length(v);
    return vec4(sin(a)*cosh(vabs), cos(a)*sinh((vabs))*v/vabs);
}
vec4 qcos(vec4 q){
    float a = q.x;
    vec3 v = vec3(q.yzw);
    float vabs = length(v);
    return vec4(cos(a)*cosh(vabs), -sin(a)*sinh((vabs))*v/vabs);
}
vec4 qexp(vec4 q){
    float expA = exp(q.x);
    vec3 v = vec3(q.yzw);
    float vabs = length(v);
    return vec4(expA*cos(vabs), expA*(v/vabs*sin(vabs)));
}
vec4 qpow(vec4 c, float p) {
    vec4 sum = c;
    for (int i = 1; i < p; i++) {
        sum = qmul(sum, c);
    }
    return sum;
}



//quantum function function
const float n = 3;
vec4 roots[int(n)];

// Function to calculate roots of unity
void calculateRootsOfUnity(int m, out vec4 roots[int(n)]) {
    for (int i = 0; i < m; i++) {
        float angle = 2.0 * PI * float(i) / float(m);
        roots[i] = vec4(cos(angle), sin(angle),0,0);
    }
}


//NewtonFractal funktion in Form von f(q) = q-a(function(q)/derivative(q)), q und a quantoren
vec4 qFunctionNewton(vec4 q) {
    return q - qmul(vec4(1,timeSin*2,timeSin,timeSin),qdiv(qpow(q, n) - vec4(1, 0, 0, 0), n*qpow(q,n-1)));
}
vec4 qFunctionNewton2(vec4 q) {
    return q - qmul(vec4(1, 0, 0, 0),qdiv(qpow(q, n) - vec4(1, 0, 0, 0), n * qpow(q, n-1)));
}


//NewtonFractal with exp functions
vec4 qFunctionExp(vec4 q) {
    return q - qmul(vec4(1, 0, 0, 0), (qdiv(qexp(q) - vec4(1, 0, 0, 0), qexp(q))));
}
vec4 qFunctionExp2(vec4 q) {
    return q - qmul(vec4(1, 0, 0, 0), (qdiv(qmul(qpow(q,n),qexp(q)) + vec4(1, 0, 0, 0), n*qmul(q,qexp(q))+qmul(qpow(q,n),qexp(q)))));
}




//ratioanl Function
vec4 qfunctionRational(vec4 q){
    return qmul(vec4(1,0,0,0),qdiv(vec4(1,0,0,0),qpow(q,3)+qmul(q,vec4(-3,-3,0,0))));
}


//Mandelbrot Function, c = pixel Coordinates for Mandelbrot, c = Constant for Julia set equivalent
vec4 qMandelbrotJulia(vec4 q, vec4 c){
    return qmul(q,q)+c;
}



//make Newton Intersection
vec3 newtonMethod(in vec4 c) {
    vec4 z = c;
    vec4 zNudge = c + 0.0001;
    int maxIteration = 30;
    for (int iteration = 0; iteration < maxIteration; iteration++) {
        z = qFunctionNewton(z);
        zNudge = qFunctionNewton(zNudge);
        if (length(z - zNudge) > 0.1) return vec3(1 - iteration / float(maxIteration + 10));
    }
    return vec3(0.0);
}



//make color set
vec3 newtonFractal(in vec4 c) {
    float tolerance = 0.1;
    vec4 z = c;
    int maxIteration = 50;
    for (int iteration = 0; iteration < maxIteration; iteration++) {
        z = qFunctionNewton(z);
        for (int i = 0; i < n; i++) {
            if (length(z - roots[i]) < tolerance) {
                return colors[i] * (1 - iteration / float(maxIteration + 10));
            }
        }
    }
    return vec3(0.0);
}



//rendering from camera
vec3 rayMarch(vec3 origin, vec3 dir) {
    float t = 0.0;
    for (int i = 0; i < 200; i++) {
        vec3 pos = origin + t * dir;
        t +=  0.025 + i*0.001;

        //if (pos.z > 0) continue;
        //if (pos.z < -0.1) continue;
        //if (pos.y >0 ) continue;
        //if (pos.x >0 ) continue;

        vec3 color;
        if(u_mode==0) color = newtonMethod(vec4(pos.xyz, 0));
        else color = newtonFractal(vec4(pos.xyz, 0));

        if (color != vec3(0.0)) return color;
    }
    return vec3(0, 0, 0.2);
}



//camera function
vec3 rotateByVec3(in vec3 vector, in vec3 axis, in float angle) {
    axis = normalize(axis);
    float cosAngle = cos(angle);
    return vector * cosAngle + (cross(axis, vector)) * sin(angle) + axis * (dot(axis, vector)) * (1 - cosAngle);
}

void main() {
    //make necessary variables
    calculateRootsOfUnity(int(n), roots);

    float aspectRatio = u_resolution.x / u_resolution.y;
    vec2 uv = vec2(((gl_FragCoord.x / u_resolution.y) - (aspectRatio) * 0.5), ((gl_FragCoord.y / u_resolution.y) - 0.5));

    vec3 ro = u_origin;
    vec3 rd = u_direction;

    vec3 camLeftNormal = cross(u_direction, vec3(0.0, 0.0, 1.0));
    vec3 camUpNormal = cross(u_direction, camLeftNormal);

    //rotate up or down
    rd = rotateByVec3(rd, camUpNormal, uv.x);
    //roate left or right
    rd = rotateByVec3(rd, camLeftNormal, uv.y);

    vec3 color = rayMarch(ro, rd);
    colorOut = vec4(color, 1.0);
}