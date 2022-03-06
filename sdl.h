#ifndef DTEAMSDL_H
#define DTEAMSDL_H

extern SDL_Window *window;
extern SDL_Renderer *renderer;

#define WIDTH 240
#define HEIGHT 180

void initSDL();
void endSDL();
SDL_Texture *loadTexture(const char *filename);
void updateDisplay();

#endif