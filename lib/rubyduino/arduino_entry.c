#include <stdlib.h>

int sp_arduino_user_main(int argc, char **argv);

int main(void) {
  char arg0[] = "sketch";
  char *argv[] = { arg0, NULL };
  return sp_arduino_user_main(1, argv);
}
