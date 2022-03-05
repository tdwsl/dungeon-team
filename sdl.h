#ifndef DTEAMSDL_H
#define DTEAMSDL_H

extern SDL_Window *window;
extern SDL_Renderer *renderer;

void initSDL();
void endSDL();
SDL_Texture *loadTexture(const char *filename);
void updateDisplay();

#endif