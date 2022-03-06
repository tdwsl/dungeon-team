#ifndef INITCURSES_H
#define INITCURSES_H

#define WIDTH 80
#define HEIGHT 24

#define BLUE_BLACK 1
#define RED_BLACK 2
#define GREEN_BLACK 3

#define initCurses() {\
  initscr(); keypad(stdscr, 1); noecho();\
  start_color();\
  init_pair(1, COLOR_CYAN, COLOR_BLACK);\
  init_pair(2, COLOR_RED, COLOR_BLACK);\
  init_pair(3, COLOR_GREEN, COLOR_BLACK);\
}
#define endCurses() {keypad(stdscr, 0); echo(); endwin();}

#endif
