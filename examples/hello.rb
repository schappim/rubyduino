pin_mode(ArduinoUNO::LED_BUILTIN, ArduinoUNO::OUTPUT)

loop do
  digital_write(ArduinoUNO::LED_BUILTIN, ArduinoUNO::HIGH)
  delay_ms(100)
  digital_write(ArduinoUNO::LED_BUILTIN, ArduinoUNO::LOW)
  delay_ms(100)
end
