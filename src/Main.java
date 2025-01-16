import org.lwjgl.opengl.GL;

import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL20.*;

//Mit w,a,s,d kann man sich bewegen, wenn's 3D ist, kann man mite SPACE und SHIFT nach oben und nach unten,
//Mit Q und E zoomen rein und raus, bzw. in 3D macht einen schneller und langsamer
//Mit ENTER kann man manchmal ein Parameter zwischen -1 und 1 inkrementieren
//Mit LEFT SHIFT kann man manchmal zwischen Schwarz weiß und Farbe wechseln
//Funktion sind recht intuitiv zum Eingeben: Sin, Cos, Exp, /, *, ^, -, + sind die möglichen Operatoren
//Zu beachten, nach ^ kommen nur natürliche Zahlen
//quaternions haben immer die Form von quant(r,i,j,k) wobei r, i, j, k immer reele Zahlen sein müssen, rechnung mit reelen Zahlen sind aber erlaubt
//Die unbekannte der Funktion ist q, also in echt wäre die Funktion f(q) = ..., q ist ein Quaternion
// t ist immer eine reelle Zahl die zwischen -1 und 1 wandert (durch eine Sinus Funktion berechnet)
//Beispiele für Funktionen wären:
//  q/(q^2-q^3)+quant(t*0.2,t,0,0)
//  q-quant(1,t,0,0)*(sin(q)-1/cos(q))
//  q-quant(1,t,0,0)*((q^3)-1)/(3*q^2)
//  q^2+quant(-0.835, -0.2321,0,0)
//  1/(quant(t,t,0,0)* q^5 + q^3 + quant(-3,-3,0,0)*q)
//  (exp(q))-quant(0,t*0.5,0,0)



public class Main {
    public static void main(String[] args) {
        run();
    }

    public static void run() {
        //hier Resolution bestimmen
        shaderUtils.init(1920,1080);
        //make Camera
        cam = new Camera(new Vector3(0,0,2));
        //startLoop
        loop();
        // Clean up when closed
        shaderUtils.cleanUp();
    }


    private static Camera cam;
    private static double xPos = 0;
    private static double yPos = 0;
    private static float info = 1;
    private static int time = 0;
    private static boolean playTime = false;
    private static int mode = 0;


    public static void loop( ) {
        double frameRate = 1.0d / 30.0d;
        double previous = glfwGetTime();
        double steps = 0.0;

        //hier functionen eingeben
        glslFunctionMaker test = new glslFunctionMaker("q-quant(1,t*2,t,t)*((q^3)-1)/(3*q^2)");
        String code = test.code;
        System.out.println(code);


        // hier kann man den Fragment shader bestimmen,
        // fragment.glsl = Einfache 3D szene mittels Raymarching
        // fragment2.glsl = 3D Mandelbrot durch Höhen Versetzung
        // fragment3.glsl = Quaternion Mandelbrot (nicht mein Code)
        // fragment4.glsl = Quaternion funktion Julia Set zeichner 2D
        // fragment5.glsl = Quaternion funktion Julia Set zeichner 3D   !Sehr intensiv!

        shaderUtils.initShaders("/shaders/fragment4.glsl",code);

        int originUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_origin");
        int directionUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_direction");
        int infoUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_info");
        int timeUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_time");
        int modeUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_mode");

        GL.createCapabilities();

        while (!glfwWindowShouldClose(shaderUtils.window)) {
            double current = glfwGetTime();
            double elapsed = current - previous;
            previous = current;
            steps += elapsed;
            if(playTime) time++;
            while (steps >= frameRate) {
                steps -= frameRate;
            }

            getInputs();
            parseCamInputs(originUniform, directionUniform,infoUniform,timeUniform, modeUniform);
            shaderUtils.render();
            sync(current);
        }
    }

    private static void sync(double loopStartTime) {
        float loopSlot = 1f / 50;
        double endTime = loopStartTime + loopSlot;
        while (glfwGetTime() < endTime) {
            try {
                Thread.sleep(1);
            } catch (InterruptedException _) {
            }
        }
    }
    public static void getInputs(){
        glfwSetInputMode(shaderUtils.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
        playTime = glfwGetKey(shaderUtils.window, GLFW_KEY_ENTER) == GLFW_PRESS;
        mode = (glfwGetKey(shaderUtils.window, GLFW_KEY_RIGHT_SHIFT) == GLFW_PRESS) ? 1 : 0;
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS) cam.moveCamera(new Vector3(0,0,-0.01).times(1/info));
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_SPACE) == GLFW_PRESS) cam.moveCamera(new Vector3(0,0,0.01).times(1/info));
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_W) == GLFW_PRESS) cam.moveCamera(new Vector3(0.01,0,0).times(1/info));
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_A) == GLFW_PRESS) cam.moveCamera(new Vector3(0,0.01,0).times(1/info));
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_S) == GLFW_PRESS) cam.moveCamera(new Vector3(-0.01,0,0).times(1/info));
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_D) == GLFW_PRESS) cam.moveCamera(new Vector3(0,-0.01,0).times(1/info));
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_Q) == GLFW_PRESS) info*= 1.2F;
        if (glfwGetKey(shaderUtils.window, GLFW_KEY_E) == GLFW_PRESS) info/= 1.2F;

        double[] nextXPos = new double[1];
        double[] nextYPos = new double[1];


        //getCursorPos kommentieren bei 2D fragment shaders, um camera drehung auszuschalten
        glfwGetCursorPos(shaderUtils.window, nextXPos, nextYPos);
        cam.rotateLeftRight((xPos - nextXPos[0]) / 360.0);
        cam.rotateUpDown((yPos - nextYPos[0]) / 360.0);
        xPos = nextXPos[0];
        yPos = nextYPos[0];
    }

    public static void parseCamInputs(int originUniform, int directionUniform, int infoUniform, int timeUniform, int modeUniform){
        glUniform3f(originUniform, (float) cam.origin.x, (float) cam.origin.y, (float) cam.origin.z);
        glUniform3f(directionUniform, (float) cam.pointing.x, (float) cam.pointing.y, (float) cam.pointing.z);
        glUniform1f(infoUniform,info);
        glUniform1i(timeUniform, time);
        glUniform1i(modeUniform,mode);
    }
}