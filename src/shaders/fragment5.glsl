#version 330
precision highp float;

uniform vec2 u_resolution;
uniform float u_info;
uniform vec3 u_origin;
uniform vec3 u_direction;
uniform int u_time;
out vec4 colorOut;

float timeSin(float x){
    return abs(sin(u_time / (100.0*x)));
}

vec3 colors[6] = vec3[6](
vec3(1.0, 0.0, 0.0),
vec3(0.0, 1.0, 0.0),
vec3(0.0, 0.0, 1.0),
vec3(1.0, 1.0, 0.0),
vec3(1.0, 0.0, 1.0),
vec3(0.0, 1.0, 1.0)
);

//quaternion math functions
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

    vec4 bConjugate = vec4(b.x, -b.y, -b.z, -b.w);

    return vec4(
    (a.x * bConjugate.x - a.y * bConjugate.y - a.z * bConjugate.z - a.w * bConjugate.w) / normSquared,
    (a.x * bConjugate.y + a.y * bConjugate.x + a.z * bConjugate.w - a.w * bConjugate.z) / normSquared,
    (a.x * bConjugate.z - a.y * bConjugate.w + a.z * bConjugate.x + a.w * bConjugate.y) / normSquared,
    (a.x * bConjugate.w + a.y * bConjugate.z - a.z * bConjugate.y + a.w * bConjugate.x) / normSquared
    );
}

vec4 qpow(vec4 c, float p) {
    vec4 sum = vec4(1, timeSin(1), 0, 0);
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



//fuction one
int n = 4;

vec4 func(vec4 c) {
    return qpowExact(c, n) - vec4(1, 0, 0, 0);
}
vec4 deriv(vec4 c) {
    return n * qpowExact(c, n - 1);
}
vec4 qFunction(in vec4 q) {
    return q - qdiv(func(q), deriv(q));
}


//function 2
vec4 qFunction2(vec4 q) {
    return q - qdiv(qpow(q, n) - vec4(1, 0, 0, 0), n * qpowExact(q, n-1));;
}
vec4 qFunction3(vec4 q, vec4 c) {
    return qpow(q, 2) - vec4(1, 0, 0, 0);
}



//make julia set
vec3 julia(in vec4 c) {
    vec4 z = c;
    for (int d = 0; d < 30; d++) {
        z = qmul(z, z) + (0.185, 0.478, 0.125, -0.392);
        if (length(z) > 2.1) return vec3(0);
    }
    return vec3(1.0);
}


//make mandelbrotSet
vec3 mandelbrot(in vec4 c) {
    vec4 z = vec4(0);
    for (int d = 0; d < 30; d++) {
        z = qpow(z, 3) + c;
        if (length(z) > 2.1) {
            return vec3(0);
        }
    }
    return vec3(1);
}


//make Newton Intersection
vec3 newtonMethod(in vec4 c) {
    vec4 z = c;
    vec4 zNudge = c + 0.0001;
    int maxIteration = 30;
    for (int iteration = 0; iteration < maxIteration; iteration++) {
        z = qFunction2(z);
        zNudge = qFunction2(zNudge);
        if (length(z - zNudge) > 0.1) return vec3(1 - iteration / float(maxIteration + 10));
    }
    return vec3(0.0);
}


//arrays need for coloring
vec4 roots[3] = vec4[3](
vec4(1, 0, 0, 0),
vec4(-0.5, sqrt(3.0) / 2.0, 0, 0),
vec4(-0.5, -sqrt(3.0) / 2.0, 0, 0)
);



//make color set
vec3 newtonFractal(in vec4 c) {
    float tolerance = 0.1;
    vec4 z = c;
    int maxIteration = 50;
    for (int iteration = 0; iteration < maxIteration; iteration++) {
        z = qFunction2(z);
        for (int i = 0; i < roots.length; i++) {
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
        //t +=  0.01 + i/400.0;
        t +=  0.025;

        //if (pos.z > 0) continue;
        //if (pos.z < -0.1) continue;
        //if (pos.y >0 ) continue;
        //if (pos.x >0 ) continue;

        vec3 color = newtonFractal(vec4(pos.xyz, 0));
        if (color != vec3(0.0)) return  color * ((1- clamp(length(pos - origin)/5.0, 0, 1))) ;
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