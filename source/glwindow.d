import std.stdio;
import derelict.sdl2.sdl;

struct window_size {
  int w;
  int h;
};

class GLWindow {
  SDL_Window* window;
  SDL_GLContext context;

  this(const char* title, int w, int h) {
    window = SDL_CreateWindow(title,
             SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
             w, h, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);

    if(!window) perror("Window didn't get created");

    // Create our opengl context and attach it to our window
    context = SDL_GL_CreateContext(window);
  }

  ~this() {
    // Delete our opengl context, destroy our window, and shutdown SDL
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
  }

  // Swap buffers
  void swap() {
    SDL_GL_SwapWindow(window);
  }

  // Get window size (using this for viewport)
  window_size get_size() {
    int w, h;
    SDL_GetWindowSize(window, &w, &h);

    return window_size(w, h);
  }
};
