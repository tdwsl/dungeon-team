mingw=i686-w64-mingw32
sdldir=~/SDL2-2.0.20/$mingw
luadir=~/Downloads/lua-5.4.4/src

$mingw-gcc -I$sdldir/include -L$sdldir/lib -I$luadir -L$luadir engine.c sdl.c -lmingw32 -lSDL2main -lSDL2 -llua -lm -o dteam_sdl.exe

cp $sdldir/bin/*.dll .
