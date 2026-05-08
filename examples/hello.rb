system("pin13:output")

loop do
  duration = 0.1
  system("pin13:high")
  sleep duration
  system("pin13:low")
  sleep duration
end
