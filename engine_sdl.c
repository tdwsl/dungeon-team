#include <SDL2/SDL.h>
#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>
#include <stdbool.h>
#include "sdl.h"

#define UI_W (WIDTH/4)
#define UI_H (HEIGHT/6)

int uicursorXY=0;
char uichars[UI_W*UI_H] = {0};
bool uicursoron = false;
bool mapDrawn;
int cursorX=0;
int cursorY=0;
int getchdelay = -1;
int fov[300*300];
int mapW, mapH;

SDL_Texture *tileset, *actorsheet, *charset, *cursortex;

int l_uigotoxy(lua_State *l) {
  int x = lua_tointeger(l, 1), y = lua_tointeger(l, 2);
  uicursorXY = y*UI_W+x;
  lua_pop(l, -1);

  return 0;
}

void uiputch(char c) {
  uichars[uicursorXY] = c;
  if(uicursorXY < UI_W*UI_H-1)
    uicursorXY++;
}

int l_uiputch(lua_State *l) {
  uiputch(lua_tointeger(l, -1));
  lua_pop(l, -1);

  return 0;
}

int l_uiputstr(lua_State *l) {
  for(const char *c = lua_tostring(l, -1); *c; c++)
    uiputch(*c);
  lua_pop(l, -1);

  return 0;
}

int l_uiclear(lua_State *l) {
  for(int i = 0; i < UI_W*UI_H; i++)
    uichars[i] = 0;

  return 0;
}

int l_uiwh(lua_State *l) {
  lua_pushinteger(l, UI_W);
  lua_pushinteger(l, UI_H);

  return 2;
}

int l_uicursor(lua_State *l) {
  uicursoron = lua_toboolean(l, 1);
  lua_pop(l, -1);

  return 0;
}

int l_cursor(lua_State *l) {
  cursorX = lua_tointeger(l, 1);
  cursorY = lua_tointeger(l, 2);
  lua_pop(l, -1);

  return 0;
}

int l_loadTileset(lua_State *l) {
  tileset = loadTexture(lua_tostring(l, 1));
  lua_pop(l, -1);

  return 0;
}

int l_loadActorsheet(lua_State *l) {
  actorsheet = loadTexture(lua_tostring(l, 1));
  lua_pop(l, -1);

  return 0;
}

int l_loadCharset(lua_State *l) {
  charset = loadTexture(lua_tostring(l, 1));
  lua_pop(l, -1);

  return 0;
}

void drawUI() {
  for(int i = 0; i < UI_W*UI_H; i++) {
    SDL_Rect dst = {(i%UI_W)*4, (i/UI_W)*6, 4, 6};
    SDL_Rect src = {(uichars[i]%32)*4, (uichars[i]/32)*6, 4, 6};
    if(uicursoron && i == uicursorXY)
      src.y += 24;

    SDL_RenderCopy(renderer, charset, &src, &dst);
  }
}

/* parameters: map:map, fov:map */
int l_drawMap(lua_State *l) {
  mapDrawn = true;

  lua_getfield(l, 1, "w");
  lua_getfield(l, 1, "h");

  int w = lua_tointeger(l, 3), h = lua_tointeger(l, 4);
  mapW = w;
  mapH = h;
  lua_pop(l, 2);

  /* get x and y offsets */
  int xo = -cursorX*8 + WIDTH/2, yo = -cursorY*8 + HEIGHT/2;

  lua_getfield(l, 1, "map"); /* map */
  lua_getfield(l, 2, "map"); /* fov */

  for(int i = 0; i < w*h; i++) {
    lua_geti(l, 3, i);
    lua_geti(l, 4, i);
    int t = lua_tointeger(l, 5);
    int visible = lua_tointeger(l, 6);
    fov[i] = visible;
    lua_pop(l, 2);
    if(!visible)
      continue;
    if(t == 0)
      continue;

    if(visible == 2)
      SDL_SetTextureColorMod(tileset, 0xFF, 0xFF, 0xFF);
    else
      SDL_SetTextureColorMod(tileset, 0x88, 0x88, 0x88);

    if(t == 4)
      if(i/w+1 < h) {
        lua_geti(l, 3, i+w);
        if(lua_tointeger(l, 5) != 4)
          t = 5;
        lua_pop(l, 1);
      }

    SDL_Rect src = {(t%8)*8, (t/8)*8, 8, 8};
    SDL_Rect dst = {(i%w)*8+xo, (i/w)*8+yo, 8, 8};

    SDL_RenderCopy(renderer, tileset, &src, &dst);
  }

  lua_pop(l, -1);

  return 0;
}

int l_drawActor(lua_State *l) {
  lua_getfield(l, 1, "x");
  lua_getfield(l, 1, "y");
  lua_getfield(l, 1, "graphic");
  int x = lua_tointeger(l, 2);
  int y = lua_tointeger(l, 3);
  int t = lua_tointeger(l, 4);
  lua_pop(l, -1);

  if(fov[y*mapW+x] != 2)
    return 0;

  int xo = -cursorX*8 + WIDTH/2, yo = -cursorY*8 + HEIGHT/2;

  SDL_Rect src = {(t%8)*8, (t/8)*8, 8, 8};
  SDL_Rect dst = {x*8+xo, y*8+yo, 8, 8};

  SDL_RenderCopy(renderer, actorsheet, &src, &dst);

  return 0;
}

void draw(lua_State *l) {
  mapDrawn = false;
  SDL_SetRenderDrawColor(renderer, 20, 20, 20, 0xff);
  SDL_RenderClear(renderer);

  lua_getglobal(l, "draw");
  if(lua_isfunction(l, 1))
    lua_call(l, 0, 0);
  lua_pop(l, -1);

  /* draw cursor */
  if(mapDrawn) {
    SDL_Rect src = {0, 0, 8, 8};
    SDL_Rect dst = {WIDTH/2, HEIGHT/2, 8, 8};
    SDL_RenderCopy(renderer, cursortex, &src, &dst);
  }

  drawUI();
  updateDisplay();
}

int l_getchDelay(lua_State *l) {
  getchdelay = lua_tointeger(l, 1);
  lua_pop(l, -1);

  return 0;
}

int l_getch(lua_State *l) {
  int c = -1;
  bool quit = false;

  SDL_StartTextInput();
  while(!quit && c == -1) {
    SDL_Event ev;

    while(SDL_PollEvent(&ev))
      switch(ev.type) {
      case SDL_QUIT:
        quit = true;
        break;
      case SDL_TEXTINPUT:
        c = *ev.text.text;
        break;
      case SDL_KEYDOWN:
        c = ev.key.keysym.sym;
        break;
      }

    draw(l);
  }
  SDL_StopTextInput();

  if(quit) {
    luaL_error(l, "quit");
  }

  lua_pushinteger(l, c);

  return 1;
}

void addLibrary(lua_State *l) {
  lua_newtable(l);

  lua_newtable(l);
  lua_pushcfunction(l, l_uigotoxy);
  lua_setfield(l, 2, "gotoxy");
  lua_pushcfunction(l, l_uiputch);
  lua_setfield(l, 2, "putch");
  lua_pushcfunction(l, l_uiputstr);
  lua_setfield(l, 2, "putstr");
  lua_pushcfunction(l, l_uiclear);
  lua_setfield(l, 2, "clear");
  lua_pushcfunction(l, l_uiwh);
  lua_setfield(l, 2, "wh");
  lua_pushcfunction(l, l_uicursor);
  lua_setfield(l, 2, "cursor");
  lua_setfield(l, 1, "ui");

  /* add keys */

  lua_newtable(l);
  char cs[2];
  cs[1] = 0;
  for(char c = ' '; c <= '~'; c++) {
    lua_pushinteger(l, c);
    cs[0] = c;
    lua_setfield(l, 2, cs);
  }

  const int syms[] = {
    SDLK_UP, SDLK_DOWN,
    SDLK_LEFT, SDLK_RIGHT,
    SDLK_RETURN, SDLK_BACKSPACE,
    SDLK_ESCAPE, SDLK_TAB,
  };
  const char *strs[] = {
    "up", "down",
    "left", "right",
    "return", "backspace",
    "escape", "tab",
  };

  for(int i = 0; i < 8; i++) {
    lua_pushinteger(l, syms[i]);
    lua_setfield(l, 2, strs[i]);
  }

  lua_setfield(l, 1, "keys");

  lua_pushcfunction(l, l_drawMap);
  lua_setfield(l, 1, "draw_map");
  lua_pushcfunction(l, l_drawActor);
  lua_setfield(l, 1, "draw_actor");

  lua_pushcfunction(l, l_getch);
  lua_setfield(l, 1, "getch");
  lua_pushcfunction(l, l_getchDelay);
  lua_setfield(l, 1, "getch_delay");

  lua_pushcfunction(l, l_cursor);
  lua_setfield(l, 1, "cursor");

  lua_setglobal(l, "engine");
}

int main(int argc, char *argv[]) {
  initSDL();

  actorsheet = loadTexture("img/actor.bmp");
  tileset = loadTexture("img/tileset.bmp");
  charset = loadTexture("img/font.bmp");
  cursortex = loadTexture("img/cursor.bmp");
  SDL_SetTextureAlphaMod(cursortex, 0x88);

  lua_State *l = luaL_newstate();
  luaL_openlibs(l);
  addLibrary(l);

  if(luaL_dofile(l, "scripts/main.lua"))
    printf("%s\n", lua_tostring(l, -1));

  endSDL();

  return 0;
}
