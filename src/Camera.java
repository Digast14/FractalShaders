

public class Camera {
    public Vector3 origin;
    public Vector3 pointing;
    private final Vector3 upOne = new Vector3(0, 0, 1);


    Camera(Vector3 _origin) {
        origin = _origin;
        pointing = new Vector3(1, 0, 0);
    }

    public void rotateLeftRight(double degree) {
        pointing = pointing.rotateXY(degree);

    }

    public void rotateUpDown(double degree) {
        Vector3 rotation = pointing.rotationByVector(pointing.cross(upOne), degree);
        if (rotation.dot(new Vector3(pointing.x, pointing.y, 0)) > 0) {
            pointing = rotation;
        }
    }

    public void moveCamera(Vector3 moveVector) {
        if (moveVector.z == 0) {
            origin = origin.plus(moveVector.rotateXY(pointing.getRotationXY()));
        }else origin = origin.plus(moveVector);
    }
}



