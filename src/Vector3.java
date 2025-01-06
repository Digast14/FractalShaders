

import static java.lang.Math.*;

public class Vector3 {
    public static void main(String[] args) {
        Vector3 testA = new Vector3(1, 1, 0.5);
        Vector3 testB = testA.cross(new Vector3(0,0,1));
        Vector3.printVector(testA.rotationByVector(testB, PI/10));
    }


    //constructor
    public Vector3(double x, double y, double z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    final double x;
    final double y;
    final double z;


    //make special Vector
    public static Vector3 max(Vector3 a, Vector3 b) {
        return new Vector3(Math.max(a.x, b.x), Math.max(a.y, b.y), Math.max(a.z, b.z));
    }

    public Vector3 abs() {
        return new Vector3(Math.max(this.x, this.x * -1), Math.max(this.y, this.y * -1), Math.max(this.z, this.z * -1));
    }

    public Vector3 normalize() {

        double magnitude = this.length();
        return new Vector3(x / magnitude, y / magnitude, z / magnitude);
    }

    public Vector3 negate() {
        return new Vector3(-x , -y, -z);
    }

    public Vector3 mod(double m) {
        double modX = x%m;
        double modY = y%m;
        double modZ = z%m;
//        if(x<0) modX +=m;
//        if(y<0) modY +=m;
//        if(z<0) modZ +=m;
        return new Vector3(modX, modY, modZ);
    }


    //get information
    public double maxComp() {
        return Math.max(x, Math.max(y, z));
    }

    public static double length(Vector3 v) {
        return sqrt(Math.pow(v.x, 2) + Math.pow(v.y, 2) + Math.pow(v.z, 2));
    }

    public double length() {
        return sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    }

    public double getRotationXY() {
        double alpha = atan(y / x);
        if (x < 0) alpha += Math.PI;
        if (y < 0 && x >= 0) alpha += Math.PI * 2;
        return alpha;
    }

    public static double smoothMin(double min1, double min2, double smoothnessConstant) {
        smoothnessConstant *= 4.0;
        double h = Math.max(smoothnessConstant - Math.abs(min1 - min2), 0.0) / smoothnessConstant;
        return Math.min(min1, min2) - h * h * smoothnessConstant * (1.0 / 4.0);
    }


    //calculations between Vectors
    public double dot(Vector3 k) {
        return x * k.x + y * k.y + z * k.z;
    }

    public Vector3 cross(Vector3 k) {
        return new Vector3(y * k.z - z * k.y, z * k.x - x * k.z, x * k.y - y* k.x);
    }

    public Vector3 minus(Vector3 v) {
        return new Vector3(x - v.x, y - v.y, z - v.z);
    }

    public Vector3 plus(Vector3 v) {
        return new Vector3(x + v.x, y + v.y, z + v.z);
    }

    public Vector3 times(double multi) {
        return new Vector3(x * multi, y * multi, z * multi);
    }


    //rotation
    public Vector3 rotationByVector(Vector3 k, double d) {
        k = k.normalize();
        double cosD = cos(d);
        return this.times(cosD).plus((k.cross(this)).times(sin(d))).plus((k.times(k.dot(this))).times(1 - cosD));
    }

    public Vector3 setRotationXY(double degree) {
        double magnitudeXY = sqrt(Math.pow(x, 2) + Math.pow(y, 2));
        double xValue = Math.cos(degree) * magnitudeXY;
        double yValue = Math.sin(degree) * magnitudeXY;
        return new Vector3(xValue, yValue, z);
    }

    public Vector3 rotateXY(double degree) {
        double alpha = this.getRotationXY();
        alpha += degree;
        return this.setRotationXY(alpha);
    }


    //Vector Output
    public static void printVector(Vector3 v) {
        System.out.println(Math.round(v.x*10) + ", " + Math.round(v.y*10) + ", " + Math.round(v.z*10));

    }
}
