
require 'hansa/map'

m = Hansa::Map.new
m.generate

puts m.render
puts
puts m.city_report
puts
puts m.water_report
