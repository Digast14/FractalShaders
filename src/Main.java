

import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL.*;
import static org.lwjgl.opengl.GL20.*;


public class Main {
    public static void main(String[] args) {
        run();
    }

    private static Camera cam;


    public static void run() {
        shaderUtils.init("/shaders/fragment4.glsl");
        //make Camera
        cam = new Camera(new Vector3(0,0,2));
        //startLoop
        loop();
        // Clean up when closed
        shaderUtils.cleanUp();
    }


    public static void getInputs(){
        glfwSetInputMode(shaderUtils.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
        playTime = glfwGetKey(shaderUtils.window, GLFW_KEY_ENTER) == GLFW_PRESS;
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
        glfwGetCursorPos(shaderUtils.window, nextXPos, nextYPos);
        cam.rotateLeftRight((xPos - nextXPos[0]) / 360.0);
        cam.rotateUpDown((yPos - nextYPos[0]) / 360.0);
        xPos = nextXPos[0];
        yPos = nextYPos[0];
    }

    public static void parseCamInputs(int originUniform, int directionUniform, int infoUniform, int timeUniform){
        //System.out.println(cam.origin.x + " " + cam.origin.y + " " + cam.origin.z);

        glUniform3f(originUniform, (float) cam.origin.x, (float) cam.origin.y, (float) cam.origin.z);
        glUniform3f(directionUniform, (float) cam.pointing.x, (float) cam.pointing.y, (float) cam.pointing.z);
        glUniform1f(infoUniform,info);
        glUniform1i(timeUniform, time);
    }


    private static double xPos = 0;
    private static double yPos = 0;
    private static float info = 1;
    private static int time = 0;
    private static boolean playTime = false;


    public static void loop( ) {
        double frameRate = 1.0d / 30.0d;
        double previous = glfwGetTime();
        double steps = 0.0;

        int originUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_origin");
        int directionUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_direction");
        int infoUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_info");
        int timeUniform = glGetUniformLocation(shaderUtils.shaderProgram, "u_time");

        createCapabilities();

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
            parseCamInputs(originUniform, directionUniform,infoUniform,timeUniform);
            glfwPollEvents();
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

}