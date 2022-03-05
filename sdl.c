#include <SDL2/SDL.h>
#include <assert.h>
#include "sdl.h"

SDL_Window *window;
SDL_Renderer *renderer;

SDL_Texture *screen;

SDL_Texture *textures[20];
int numTextures = 0;

void initSDL() {
  assert(SDL_Init(SDL_INIT_EVERYTHING) >= 0);

  window = SDL_CreateWindow("Dungeon Team",
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      640, 480, SDL_WINDOW_RESIZABLE);
  assert(window != NULL);

  renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
  assert(renderer != NULL);

  /* create screen texture */
  screen = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888,
      SDL_TEXTUREACCESS_TARGET, WIDTH, HEIGHT);
  textures[numTextures++] = screen;
  SDL_SetRenderTarget(renderer, screen);
}

void endSDL() {
  for(int i = 0; i < numTextures; i++)
    SDL_DestroyTexture(textures[i]);
  numTextures = 0;

  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
}

SDL_Texture *loadTexture(const char *filename) {
  SDL_Surface *surf = SDL_LoadBMP(filename);
  assert(surf != NULL);
  SDL_SetColorKey(surf, SDL_TRUE,
      SDL_MapRGB(surf->format, 0, 0xFF, 0xFF));
  SDL_Texture *tex = SDL_CreateTextureFromSurface(renderer, surf);
  SDL_FreeSurface(surf);
  assert(tex != NULL);

  textures[numTextures++] = tex;
  return tex;
}

SDL_Rect getDisplayRect() {
  int w, h;
  SDL_GetWindowSize(window, &w, &h);
  float xs = (float)w/(float)WIDTH, ys = (float)h/(float)HEIGHT;
  float s = (xs > ys) ? ys : xs;
  if(s > 1)
    s = (int)s;
  SDL_Rect r = {w/2-(WIDTH/2)*s, h/2-(HEIGHT/2)*s, WIDTH*s, HEIGHT*s};
  return r;
}

void updateDisplay() {
  SDL_Rect r = getDisplayRect();
  SDL_SetRenderTarget(renderer, NULL);
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0xFF);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, screen, NULL, &r);
  SDL_RenderPresent(renderer);
  SDL_SetRenderTarget(renderer, screen);
}
