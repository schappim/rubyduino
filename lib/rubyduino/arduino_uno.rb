module ArduinoUNO
  LOW = 0
  HIGH = 1

  INPUT = 0
  OUTPUT = 1
  INPUT_PULLUP = 2

  A0 = 14
  A1 = 15
  A2 = 16
  A3 = 17
  A4 = 18
  A5 = 19

  LED_BUILTIN = 13

  ffi_func :pin_mode, [:uint8, :uint8], :int
  ffi_func :digital_write, [:uint8, :uint8], :int
  ffi_func :digital_read, [:uint8], :int
  ffi_func :analog_read, [:uint8], :int
  ffi_func :delay_ms, [:uint32], :void
end

def pin_mode(pin, mode)
  ArduinoUNO.pin_mode(pin, mode)
end

def digital_write(pin, value)
  ArduinoUNO.digital_write(pin, value)
end

def digital_read(pin)
  ArduinoUNO.digital_read(pin)
end

def analog_read(pin)
  ArduinoUNO.analog_read(pin)
end

def delay_ms(ms)
  ArduinoUNO.delay_ms(ms)
end
