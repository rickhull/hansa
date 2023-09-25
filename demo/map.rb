require 'hansa/map'

m = Hansa::Map.new
m.generate

puts m.report
puts
puts m.render
puts
puts format("River: %s", m.river_path.join(' -> '))
puts format("West coast: %s", m.west_coast.join(', '))
puts format("East coast: %s", m.east_coast.join(', '))
