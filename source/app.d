import std.stdio;
import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

import gfm.math;
import std.math;

import glwindow;
import files;
import obj_parser;

// Hashmap containing currently pressed keys
bool[char] keys_pressed;

class Mesh
{
    // This will identify our vertex buffer
    GLuint vertexbuffer;
    GLuint uvbuffer;

    int number_of_verts = 0;

    this(const GLfloat[] mesh_data, const GLfloat[] uv_data) {
        // gen vertex buffer
        glGenBuffers(1, &vertexbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);

        number_of_verts = cast(int)mesh_data.length/3;

        // Give our vertices to OpenGL.
        glBufferData(GL_ARRAY_BUFFER, 
            cast(long)(mesh_data.sizeof*mesh_data.length), 
            cast(const(void)*)mesh_data, 
            GL_STATIC_DRAW);

        // gen uv buffer
        glGenBuffers(1, &uvbuffer);
        glBindBuffer(GL_ARRAY_BUFFER, uvbuffer);    

        // Give our vertices to OpenGL.
        glBufferData(GL_ARRAY_BUFFER, 
            cast(long)(uv_data.sizeof*uv_data.length), 
            cast(const(void)*)uv_data, 
            GL_STATIC_DRAW);
    }

    void draw() {
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);

        // 1st attribute buffer : vertices
        glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
        glVertexAttribPointer(
            0,            // attribute 0
            3,            // size
            GL_FLOAT,     // type
            GL_FALSE,     // normalized?
            0,            // stride
            cast(void*)0  // array buffer offset
        );

        // 2nd attribute buffer : uv coordinates
        glBindBuffer(GL_ARRAY_BUFFER, uvbuffer);
        glVertexAttribPointer(
            1,
            2,
            GL_FLOAT,
            GL_FALSE,
            0,
            cast(void*)0
        );

        // Draw the triangle!
        glDrawArrays(GL_TRIANGLES, 0, number_of_verts); 
        glDisableVertexAttribArray(0);
    }
}

int main()
{   
    /*====================
    SETUP
    ====================*/
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Image.load();

    // Init SDL
    if(SDL_Init(SDL_INIT_VIDEO) != 0) {
        perror("SDL didn't initialise!");
        return -1;
    }
    // Init SDL image
    if(!IMG_Init(IMG_INIT_PNG))
        printf("Can't init! %s\n", IMG_GetError());

    // Create SDL window and OpenGL context */ 
    GLWindow glwindow = new GLWindow("Ayyy lmao", 320*2, 240*2);

    // Must reload OpenGL once context is created
    DerelictGL3.reload();

    /*====================
    GL SETUPS
    ====================*/
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_TEXTURE_2D);
    glDisable(GL_CULL_FACE);
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    // Create VAO and set as current
    GLuint VertexArrayID;
    glGenVertexArrays(1, &VertexArrayID);
    glBindVertexArray(VertexArrayID);

    /*====================
    CREATE A TRIANGLE
    ====================*/
    // OBJ PARSING TEST
    MeshData mesh_data = obj_to_meshdata("malon.obj");
    writeln("==> Parsed OBJ");

    Mesh mesh = new Mesh(
        mesh_data.g_vertex_buffer_data,
        mesh_data.g_uv_buffer_data
    );
    writeln("==> Created mesh");

    GLuint main_default_shader = load_shaders("shaders/vert", "shaders/frag");
    glUseProgram(main_default_shader);
    writeln("==> Loaded Shader");


    /*====================
    LOAD IN TEXTURE (using SDL)
    ====================*/
    GLuint main_object_texture = load_texture("malon_texture.png");

    // set current texture
    glBindTexture(GL_TEXTURE_2D, main_object_texture);
    writeln("==> Loaded texture");

    /*====================
    EVENTLOOP
    ====================*/
    // Camera coordinates (default to infront of Malon)
    float x = 0, y = 129.0, z = 177.0;

    writeln("==> Running event loop");
    for(;;) {
        // Event handling
        bool quit = false;
        SDL_Event e;
        while(SDL_PollEvent(&e)) {
            if(e.type == SDL_QUIT) {
                quit = true;
            }

            if(e.type == SDL_KEYDOWN && e.key.repeat == 0) {
                const char* name = SDL_GetKeyName(e.key.keysym.sym);
                keys_pressed[name[0]] = true;
            }
            if(e.type == SDL_KEYUP) {
                const char* name = SDL_GetKeyName(e.key.keysym.sym);
                keys_pressed[name[0]] = false;
            }
        }
        if(quit) break;

        // Set viewport size
        window_size winsize = glwindow.get_size();
        glViewport(0, 0, winsize.w, winsize.h);

        // Clear our buffer with a red background
        glClearColor( 1.0, 0.8, 0.8, 1.0 );
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // not-very-good camera movement. could be 1000x better!
        if('A' in keys_pressed && keys_pressed['A'] == true) x -= 1.1;
        if('D' in keys_pressed && keys_pressed['D'] == true) x += 1.1;
        if('W' in keys_pressed && keys_pressed['W'] == true) z -= 1.1;
        if('S' in keys_pressed && keys_pressed['S'] == true) z += 1.1;
        if('Q' in keys_pressed && keys_pressed['Q'] == true) y += 1.1;
        if('E' in keys_pressed && keys_pressed['E'] == true) y -= 1.1;

        if('T' in keys_pressed && keys_pressed['T'] == true) 
            printf("%f %f %f", x, y, z);

        /*====================
        MATRICES SETUP
        ====================*/
        auto viewMatrix = mat4!float().lookAt(
            vec3!float(x,y,z),
            vec3!float(x,y,z - 1), // Camera looks directly forward
            vec3!float(0,1,0)
        );

        auto projectionMatrix = mat4!float().perspective(PI/4, 1, 1, 100000000);

        // model identity matrix
        // Apply rotations & stuff to this in future
        auto modelMatrix = mat4!float().identity();

        // Combine them all
        auto modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix;

        // send to glsl
        GLuint MatrixID = glGetUniformLocation(main_default_shader, "MVP");

        // note that transposing matrix because math's 
        // matrices are in row-major order. (gl is col-major)
        glUniformMatrix4fv(MatrixID, 1, GL_TRUE, &modelViewProjectionMatrix.c[0][0]);


        /*====================
        DRAW TRIANGLE
        ====================*/
        mesh.draw();

        // Swap buffers
        glwindow.swap();
    }
    
    // Destroy all windows etc and quit
    glwindow.destroy();
    SDL_Quit();

    return 0;
}

GLuint load_texture(string filepath) {
    SDL_Surface* loadedSurface = IMG_Load(cast(const char*)filepath);
    if(!loadedSurface) 
        writeln("Coudn't load image!");

    GLuint new_texture_id;
    glGenTextures(1, &new_texture_id);
    glBindTexture(GL_TEXTURE_2D, new_texture_id);
    glTexImage2D(GL_TEXTURE_2D, 0, 
        GL_RGBA, 
        loadedSurface.w, 
        loadedSurface.h, 
        0, GL_RGBA,
        GL_UNSIGNED_BYTE, 
        loadedSurface.pixels);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
    SDL_FreeSurface(loadedSurface);

    return new_texture_id;
}

GLuint load_shaders(string vertex_file_path, string fragment_file_path){
    // create shaders
    GLuint vertexShaderObject = glCreateShader(GL_VERTEX_SHADER);
    GLuint fragmentShaderObject = glCreateShader(GL_FRAGMENT_SHADER);

    GLint Result = GL_FALSE;
    int InfoLogLength;

    // read shader files
    const char* VertexShaderSource = cast(const(char*))read_file(vertex_file_path);
    const char* FragmentShaderSource = cast(const(char*))read_file(fragment_file_path);

    printf("[load_shaders] compiling vertex shader\n");
    // compile vertex shader
    glShaderSource(vertexShaderObject, 1, &VertexShaderSource, null);
    glCompileShader(vertexShaderObject);
    // check vertex shader
    glGetShaderiv(vertexShaderObject, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(vertexShaderObject, GL_INFO_LOG_LENGTH, &InfoLogLength);
    if ( InfoLogLength > 0 ){
        char[] VertexShaderErrorMessage = new char[InfoLogLength + 1];
        glGetShaderInfoLog(vertexShaderObject, InfoLogLength, null, &VertexShaderErrorMessage[0]);
        printf("%s\n", &VertexShaderErrorMessage[0]);
    }

    printf("[load_shaders] compiling fragment shader\n");
    // compile fragment shader
    glShaderSource(fragmentShaderObject, 1, &FragmentShaderSource, null);
    glCompileShader(fragmentShaderObject);
    // check fragment shader
    glGetShaderiv(fragmentShaderObject, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(fragmentShaderObject, GL_INFO_LOG_LENGTH, &InfoLogLength);
    if ( InfoLogLength > 0 ){
        char[] VertexShaderErrorMessage = new char[InfoLogLength + 1];
        glGetShaderInfoLog(fragmentShaderObject, InfoLogLength, null, &VertexShaderErrorMessage[0]);
        printf("%s\n", &VertexShaderErrorMessage[0]);
    }

    printf("[load_shaders] Linking program\n");

    // link program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShaderObject);
    glAttachShader(program, fragmentShaderObject);
    glLinkProgram(program);


    // Check the program
    glGetProgramiv(program, GL_LINK_STATUS, &Result);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &InfoLogLength);
    if ( InfoLogLength > 0 ){
        char[] ProgramErrorMessage = new char[InfoLogLength + 1];
        glGetProgramInfoLog(program, InfoLogLength, null, &ProgramErrorMessage[0]);
        printf("%s\n", &ProgramErrorMessage[0]);
    }

    // detach, delete
    glDetachShader(program, vertexShaderObject);
    glDetachShader(program, fragmentShaderObject);
    glDeleteShader(vertexShaderObject);
    glDeleteShader(fragmentShaderObject);

    return program;
}


