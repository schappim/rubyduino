#ifndef SP_ARDUINO_RUNTIME_H
#define SP_ARDUINO_RUNTIME_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <avr/io.h>
#include <util/delay.h>
#include <util/delay_basic.h>

typedef int32_t mrb_int;
typedef double mrb_float;
typedef mrb_int sp_sym;
typedef uint8_t mrb_bool;

typedef struct {
  mrb_int first;
  mrb_int last;
} sp_Range;

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

static int sp_last_status = 0;

#define time(value) ((mrb_int)1)

#define SP_GC_SAVE() ((void)0)
#define SP_GC_ROOT(value) ((void)0)
#define SP_GC_RESTORE() ((void)0)

typedef void (*sp_gc_scan_func)(void *);

static void *sp_gc_alloc(size_t size, void (*free_func)(void *), sp_gc_scan_func scan_func) {
  (void)free_func;
  (void)scan_func;
  return malloc(size);
}

static void sp_gc_mark(void *ptr) {
  (void)ptr;
}

typedef struct {
  mrb_int *data;
  mrb_int start;
  mrb_int len;
  mrb_int cap;
} sp_IntArray;

typedef struct {
  mrb_float *data;
  mrb_int len;
  mrb_int cap;
} sp_FloatArray;

static const char *sp_str_dup_external(const char *s) {
  return s;
}

static sp_Range sp_range_new(mrb_int first, mrb_int last) {
  sp_Range range;
  range.first = first;
  range.last = last;
  return range;
}

static sp_IntArray *sp_IntArray_new(void) {
  sp_IntArray *array = (sp_IntArray *)malloc(sizeof(sp_IntArray));
  array->start = 0;
  array->len = 0;
  array->cap = 4;
  array->data = (mrb_int *)malloc(sizeof(mrb_int) * array->cap);
  return array;
}

static void sp_IntArray_push(sp_IntArray *array, mrb_int value) {
  if (array->len >= array->cap) {
    array->cap *= 2;
    array->data = (mrb_int *)realloc(array->data, sizeof(mrb_int) * array->cap);
  }
  array->data[array->start + array->len] = value;
  array->len++;
}

static mrb_int sp_IntArray_length(sp_IntArray *array) {
  return array->len;
}

static mrb_int sp_IntArray_get(sp_IntArray *array, mrb_int index) {
  return array->data[array->start + index];
}

static sp_FloatArray *sp_FloatArray_new(void) {
  sp_FloatArray *array = (sp_FloatArray *)malloc(sizeof(sp_FloatArray));
  array->len = 0;
  array->cap = 4;
  array->data = (mrb_float *)malloc(sizeof(mrb_float) * array->cap);
  return array;
}

static void sp_FloatArray_push(sp_FloatArray *array, mrb_float value) {
  if (array->len >= array->cap) {
    array->cap *= 2;
    array->data = (mrb_float *)realloc(array->data, sizeof(mrb_float) * array->cap);
  }
  array->data[array->len] = value;
  array->len++;
}

static mrb_int sp_FloatArray_length(sp_FloatArray *array) {
  return array->len;
}

static mrb_float sp_FloatArray_get(sp_FloatArray *array, mrb_int index) {
  return array->data[index];
}

static int rd_uno_valid_pin(uint8_t pin) {
  return pin <= 19;
}

static volatile uint8_t *rd_uno_ddr(uint8_t pin) {
  if (pin <= 7) {
    return &DDRD;
  }
  if (pin <= 13) {
    return &DDRB;
  }
  if (pin <= 19) {
    return &DDRC;
  }
  return NULL;
}

static volatile uint8_t *rd_uno_port(uint8_t pin) {
  if (pin <= 7) {
    return &PORTD;
  }
  if (pin <= 13) {
    return &PORTB;
  }
  if (pin <= 19) {
    return &PORTC;
  }
  return NULL;
}

static volatile uint8_t *rd_uno_pin_reg(uint8_t pin) {
  if (pin <= 7) {
    return &PIND;
  }
  if (pin <= 13) {
    return &PINB;
  }
  if (pin <= 19) {
    return &PINC;
  }
  return NULL;
}

static uint8_t rd_uno_bit(uint8_t pin) {
  if (pin <= 7) {
    return pin;
  }
  if (pin <= 13) {
    return pin - 8;
  }
  return pin - 14;
}

int pin_mode(uint8_t pin, uint8_t mode) {
  volatile uint8_t *ddr = rd_uno_ddr(pin);
  volatile uint8_t *port = rd_uno_port(pin);
  uint8_t mask;

  if (!ddr || !port) {
    return 1;
  }

  mask = (uint8_t)(1 << rd_uno_bit(pin));

  if (mode == 1) {
    *ddr |= mask;
    return 0;
  }

  if (mode == 0) {
    *ddr &= (uint8_t)~mask;
    *port &= (uint8_t)~mask;
    return 0;
  }

  if (mode == 2) {
    *ddr &= (uint8_t)~mask;
    *port |= mask;
    return 0;
  }

  return 1;
}

int digital_write(uint8_t pin, uint8_t value) {
  volatile uint8_t *port = rd_uno_port(pin);
  uint8_t mask;

  if (!port) {
    return 1;
  }

  mask = (uint8_t)(1 << rd_uno_bit(pin));

  if (value) {
    *port |= mask;
  } else {
    *port &= (uint8_t)~mask;
  }

  return 0;
}

int digital_read(uint8_t pin) {
  volatile uint8_t *reg = rd_uno_pin_reg(pin);

  if (!reg) {
    return -1;
  }

  return ((*reg & (uint8_t)(1 << rd_uno_bit(pin))) != 0) ? 1 : 0;
}

int analog_read(uint8_t pin) {
  uint8_t channel = pin;

  if (pin >= 14 && pin <= 19) {
    channel = pin - 14;
  }

  if (channel > 5 || !rd_uno_valid_pin(pin)) {
    return -1;
  }

  ADMUX = (uint8_t)((1 << REFS0) | channel);
  ADCSRA = (uint8_t)((1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0));
  ADCSRA |= (uint8_t)(1 << ADSC);

  while (ADCSRA & (uint8_t)(1 << ADSC)) {
  }

  return ADC;
}

static void sp_arduino_delay_ms(unsigned long ms) {
  while (ms > 0) {
    _delay_loop_2((uint16_t)(F_CPU / 4000UL));
    ms--;
  }
}

void delay_ms(uint32_t ms) {
  sp_arduino_delay_ms(ms);
}

#define fflush(stream) ((void)0)

#endif
