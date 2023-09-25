require 'hansa/city'
require 'hansa/city_names'
require 'matrix'
require 'set'

module Hansa
  class Position
    class OutOfBounds < RuntimeError; end

    def self.distance(pos1, pos2)
      (pos1.vec - pos2.vec).magnitude
    end

    def self.midpoint(pos1, pos2)
      Position.new((pos1.x + pos2.x) / 2.0,
                   (pos1.y + pos2.y) / 2.0,
                   (pos1.z + pos2.z) / 2.0)
    end

    def self.random
      Position.new(rand(0), rand(0), rand(0))
    end

    def self.valid?(x, y, z)
      0 <= x and x <= 1 and 0 <= y and y <= 1 and 0 <= z and z <= 1
    end

    attr_reader :vec

    def initialize(x, y, z)
      unless self.class.valid?(x, y, z)
        raise(OutOfBounds, format("%.2f %.2f %.2f", x, y, z))
      end
      @vec = Vector[x, y, z]
    end

    def x
      @vec[0]
    end

    def y
      @vec[1]
    end

    def z
      @vec[2]
    end

    def flatten
      Position.new(@vec[0], @vec[1], 0)
    end

    def distance(pos2)
      self.class.distance(self, pos2)
    end

    def midpoint(pos2)
      self.class.midpoint(self, pos2)
    end

    def north?
      @vec[1] > 0.5
    end

    def east?
      @vec[0] > 0.5
    end

    def quadrant
      (self.north? ? 'N' : 'S') + (self.east? ? 'E' : 'W')
    end

    def central
      r = self.radius
      if r < 0.2
        :inner
      elsif r < 0.4
        :core
      else
        :outer
      end
    end

    def radius
      Position.new(0.5, 0.5, 0).distance(self.flatten)
    end
  end

  class Map
    WEST_ISLES = 0.05
    WEST_COAST = 0.15
    EAST_COAST = 0.85
    EAST_ISLES = 0.95

    def self.west_coast?(pos)
      pos.x <= WEST_COAST
    end

    def self.east_coast?(pos)
      pos.x >= EAST_COAST
    end

    attr_accessor :scale, :units
    attr_reader :cities, :positions, :east_coast, :west_coast, :river

    def initialize(scale: Vector[1000, 1000, 10_000],
                   units: Vector[:miles, :miles, :feet])
      @scale = scale
      @units = units

      @cities = {}    # name => city
      @positions = {} # name => pos

      # track positions (via city name) that are connected by water
      @east_coast = Set[]
      @west_coast = Set[]
      @river = Set[]
    end


    # from outermost to innermost:
    # islands (TODO, coastal)
    # coast (coastal, altitude limited)
    # delta (farming, altitude limited)
    # inland (anything except coastal)
    def generate(cities = 25)
      cities.times { |i|
        sym = (97 + i).chr.to_sym
        pos = Position.random

        if pos.x <= WEST_COAST or pos.x >= EAST_COAST
          if pos.x <= WEST_ISLES or pos.x >= EAST_ISLES
            pos.vec[2] /= 2.0 # halve the altitude
            type = :island
            name = City::COASTAL_NAMES.fetch(sym).sample
          else
            pos.vec[2] /= 10.0 # crush the altitude
            if rand(2) == 0
              pos.vec[2] /= 2.0 # a little lower now
              type = :coastal
              name = City::COASTAL_NAMES.fetch(sym).sample
            else
              type = :farming
              name = City::DELTA_NAMES.fetch(sym).sample
            end
          end
        else
          type = (City::TYPES.keys - [:coastal, :island, :delta]).sample
          name = City::NAMES.fetch(sym).sample
        end

        @cities[name] = City.new(name: name, type: type)
        @positions[name] = pos
      }
      self.update_coasts
      self.add_river
      @cities.keys
    end

    def update_coasts
      @positions.each { |name, pos|
        if self.class.east_coast?(pos)
          @east_coast.add name
        elsif self.class.west_coast?(pos)
          @west_coast.add name
        end
      }
    end

    def add_river
      # find the highest pos and lowest pos
      apex_name, gulch_name = @positions.first[0], @positions.first[0]
      apex, gulch = @positions.first[1], @positions.first[1]

      @positions.each { |name, pos|
        next if @east_coast.include?(name) or @west_coast.include?(name)
        if pos.z >= apex.z
          apex_name = name
          apex = pos
        elsif pos.z <= gulch.z
          gulch_name = name
          gulch = pos
        end
      }
      @river.add apex_name
      @river.add gulch_name

      # move one step down from apex, something close
      # ideally in the direction of gulch
      high_score, low_score = {}, {}
      @positions.each { |name, pos|
        next if @river.include? name
        high_score[name] = pos.z
        high_score[name] /= apex.distance(pos)
        low_score[name] = 1 - pos.z
        low_score[name] /= gulch.distance(pos)
      }

      @river.add high_score.sort_by { |name, score| -1 * score }.first[0]
      @river.add low_score.sort_by { |name, score| -1 * score }.first[0]

      # now find a middle point
      # ideally halfway between apex and gulch and mid altitude
      midpoint = apex.midpoint(gulch)
      mid_score = {}

      @positions.each { |name, pos|
        next if @river.include? name
        mid_score[name] = midpoint.distance(pos)
      }
      @river.add mid_score.sort_by { |name, score| score }.first[0]

      # now dump to the nearest coastal city if it's lower than gulch
      closest = nil
      dist = 99**99
      (@east_coast + @west_coast).each { |name|
        closest ||= name
        pos = @positions[name]
        next if pos.z > gulch.z
        measure = gulch.distance(pos)
        if measure < dist
          dist = measure
          closest = name
        end
      }
      @river.add(closest) if closest
      @river
    end

    def city_report
      rpt = []
      @cities.each { |name, city|
        pos = @positions[name]
        altitude = (pos.z * @scale[2]).round
        rpt << format("%s   %s %s %s %s %s",
                      name.to_s.rjust(16, ' '),
                      pos.central.to_s.rjust(5, ' '),
                      pos.quadrant,
                      city.type.to_s.rjust(12, ' '),
                      altitude.to_s.rjust(4, ' '), @units[2])
      }
      rpt.join($/)
    end

    def water_report
      [format("River: %s", self.river_path.join(' -> ')),
       format("West coast: %s", self.west_coast.join(', ')),
       format("East coast: %s", self.east_coast.join(', '))].join($/)
    end

    def render(x: 80, y: 50)
      rows = Array.new(y) { Array.new(x) { ' ' } }
      # rows[0][0]   top left
      # rows[0][79]  top right
      # rows[49][0]  bottom left
      # rows[49][79] bottom right
      @positions.each { |name, pos|
        rownum = y - (pos.y * y).floor - 1
        colnum = (pos.x * x).floor
        rows[rownum][colnum] = name[0]
      }
      rows.map { |row| row.join }.join($/)
    end

    def distance(name1, name2)
      Position.distance(@positions.fetch(name1), @positions.fetch(name2))
    end

    def midpoint(name1, name2)
      Position.midpoint(@positions.fetch(name1), @positions.fetch(name2))
    end

    def water_route?(name1, name2)
      [@east_coast, @west_coast, @river].each { |water|
        return water if water.include?(name1) and water.include?(name2)
      }
      false
    end

    def river_path
      @river.sort_by { |name| -1 * @positions[name].z }
    end

    def transport_cost(name1, name2)
      # is there a water route?
      water = self.water_route?(name1, name2)
      if water
        # if a river, going downstream?
        if water == @river
          river_path = self.river_path
          start = river_path.index(name1)
          finish = river_path.index(name2)
          if start > finish # going upstream
            path = river_path[finish, start - finish + 1].reverse
            river_mult = 8.0
          else
            path = river_path[start, finish - start + 1]
            river_mult = 12.0
          end
          cost = 0
          path.each_cons(2) { |a, b|
            cost += self.distance(a, b) / river_mult
          }
          cost
        else
          # ocean: simple distance / 10
          self.distance(name1, name2) / 10.0
        end
      else
        # land: simple distance, as the crow flies
        self.distance(name1, name2)
      end
    end
  end
end
