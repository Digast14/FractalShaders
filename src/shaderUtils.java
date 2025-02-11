import org.lwjgl.glfw.GLFWErrorCallback;
import org.lwjgl.glfw.GLFWVidMode;
import org.lwjgl.opengl.GL;
import org.lwjgl.system.MemoryStack;

import java.io.IOException;
import java.io.InputStream;
import java.nio.IntBuffer;

import static org.lwjgl.glfw.Callbacks.glfwFreeCallbacks;
import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.ARBVertexArrayObject.*;
import static org.lwjgl.opengl.GL20.*;
import static org.lwjgl.system.MemoryStack.stackPush;
import static org.lwjgl.system.MemoryUtil.NULL;

//Behind the Scenes um Shader zu kompilieren, screen zu machen etc.

public class shaderUtils {
    public static long window;
    public static int shaderProgram;
    private static int vao;
    private static int vbo;
    private static int ebo;
    private static int resX = 720;
    private static int resY = 720 ;

    public static void init(int _resX, int _resY) {

        System.out.println("Hello to this Shader test!");

        GLFWErrorCallback.createPrint(System.err).set();
        if (!glfwInit()) throw new IllegalStateException("Unable to initialize GLFW");

        // Initialize GLFW
        resX =_resX;
        resY = _resY;

        glfwDefaultWindowHints();
        window = glfwCreateWindow(resX, resY, "just Works!", NULL, NULL);

        try (MemoryStack stack = stackPush()) {
            IntBuffer pWidth = stack.mallocInt(1); // int*
            IntBuffer pHeight = stack.mallocInt(1); // int*

            // Get the window size passed to glfwCreateWindow
            glfwGetWindowSize(window, pWidth, pHeight);

            // Get the resolution of the primary monitor
            GLFWVidMode vidmode = glfwGetVideoMode(glfwGetPrimaryMonitor());

            // Center the window
            glfwSetWindowPos(
                    window,
                    (vidmode.width() - pWidth.get(0)) / 2,
                    (vidmode.height() - pHeight.get(0)) / 2
            );
        } // the stack frame is popped automatically

        // Make OpenGL context current
        glfwMakeContextCurrent(window);
        GL.createCapabilities(); // Initialize OpenGL bindings
    }


    public static void initShaders(String shaderPath, String javaFunction){

        // Set up shaders
        String fragmentShaderSource = shaderLoadSource(shaderPath);
        fragmentShaderSource = fragmentShaderSource.replace("__FUNCTION_PLACEHOLDER__", javaFunction);

        int fragmentShader = createShaderFromSource(fragmentShaderSource, GL_FRAGMENT_SHADER);
        int vertexShader = createShaderFromSource(shaderLoadSource("/shaders/vertex.glsl"), GL_VERTEX_SHADER);
        shaderProgram = createProgram(fragmentShader, vertexShader);
        glUseProgram(shaderProgram);


        //clean up shaders
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);

        // Set up vertex data
        float[] vertices = {
                -1.0f, -1.0f, // Bottom-left
                1.0f, -1.0f, // Bottom-right
                1.0f, 1.0f, // Top-right
                -1.0f, 1.0f  // Top-left
        };
        int[] indices = {
                0, 1, 2, // First triangle
                2, 3, 0  // Second triangle
        };

        //make Vertex Array Object
        vao = glGenVertexArrays();
        glBindVertexArray(vao);

        //make Vertex Buffer Object
        vbo = glGenBuffers();
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW);

        //make Element Buffer Object
        ebo = glGenBuffers();
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices, GL_STATIC_DRAW);

        glVertexAttribPointer(0, 2, GL_FLOAT, false, 2 * Float.BYTES, 0);
        glEnableVertexAttribArray(0);

        //parse resolution to shader
        int resolutionUniform = glGetUniformLocation(shaderProgram, "u_resolution");
        glUniform2f(resolutionUniform, resX, resY);
    }



    private static int createShaderFromSource(String source, int type) {
        int shader = glCreateShader(type);
        glShaderSource(shader, source);
        glCompileShader(shader);
        if (glGetShaderi(shader, GL_COMPILE_STATUS) == GL_FALSE) {
            throw new RuntimeException("Failed to compile shader: " + glGetShaderInfoLog(shader));
        }
        return shader;
    }

    private static int createProgram(int fragmentShader, int vertexShader) {
        int shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vertexShader);
        glAttachShader(shaderProgram, fragmentShader);
        glLinkProgram(shaderProgram);
        if (glGetProgrami(shaderProgram, GL_LINK_STATUS) == GL_FALSE) {
            throw new RuntimeException("Shader program linking failed: " + glGetProgramInfoLog(shaderProgram));
        }
        return shaderProgram;
    }


    public static void render() {
        //clear screen
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        //execute and draw Program
        glUseProgram(shaderProgram);
        glBindVertexArray(vao);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    public static void cleanUp() {
        glDeleteProgram(shaderProgram);
        glDeleteBuffers(vbo);
        glDeleteBuffers(ebo);
        glDeleteVertexArrays(vao);

        glfwFreeCallbacks(window);
        glfwDestroyWindow(window);
        glfwTerminate();
        glfwSetErrorCallback(null).free();
    }


    private static String shaderLoadSource(String filePath){
        String source;
        try (InputStream inputStream = Main.class.getResourceAsStream(filePath)) {
            if (inputStream == null) {
                throw new IllegalArgumentException("Shader file not found: " + filePath);
            }
            source = new String(inputStream.readAllBytes());
        } catch (IOException e) {
            throw new RuntimeException("Failed to load shader: " + filePath, e);
        }
        return source;
    }
}
