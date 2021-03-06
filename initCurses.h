#ifndef INITCURSES_H
#define INITCURSES_H

#define WIDTH 79
#define HEIGHT 23

#define BLUE_BLACK 1
#define RED_BLACK 2
#define GREEN_BLACK 3
#define YELLOW_BLACK 4

#define initCurses() {\
  initscr(); keypad(stdscr, 1); noecho();\
  start_color();\
  init_pair(1, COLOR_CYAN, COLOR_BLACK);\
  init_pair(2, COLOR_RED, COLOR_BLACK);\
  init_pair(3, COLOR_GREEN, COLOR_BLACK);\
  init_pair(4, COLOR_YELLOW, COLOR_BLACK);\
}
#define endCurses() {curs_set(1); keypad(stdscr, 0); echo(); endwin();}

#endif
