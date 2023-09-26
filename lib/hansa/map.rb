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

    # magic constant
    RIVER_MIDPOINT = 1.5

    def self.west_isles?(pos)
      pos.x <= WEST_ISLES
    end

    def self.west_coast?(pos)
      pos.x <= WEST_COAST
    end

    def self.east_coast?(pos)
      pos.x >= EAST_COAST
    end

    def self.east_isles?(pos)
      pos.x >= EAST_ISLES
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
      @east_isles = Set[]
      @west_isles = Set[]
      @river = Set[]
    end

    def to_s
      [self.render,
       self.city_report,
       self.water_report].join($/)
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

        if Map.east_coast?(pos) or Map.west_coast?(pos)
          # coastal
          if Map.east_isles?(pos) or Map.west_isles?(pos)
            # island
            pos.vec[2] /= 2.0 # halve the altitude
            type = :island
            name = City::COASTAL_NAMES.fetch(sym).sample
            (Map.east_isles?(pos) ? @east_isles : @west_isles).add name
          else
            # mainland
            pos.vec[2] /= 10.0 # crush the altitude
            if rand(2) == 0
              pos.vec[2] /= 2.0 # a little lower now
              type = :coastal
              name = City::COASTAL_NAMES.fetch(sym).sample
            else
              type = :delta
              name = City::DELTA_NAMES.fetch(sym).sample
            end
          end
          # all coastal cities, mainland and islands
          (Map.east_coast?(pos) ? @east_coast : @west_coast).add name
        else
          type = (City::TYPES.keys - [:coastal, :island, :delta]).sample
          name = City::NAMES.fetch(sym).sample
        end

        @cities[name] = City.new(name: name, type: type)
        @positions[name] = pos
      }
      self.add_river
      @cities.keys
    end

    def find_river_midpoint(name1, name2)
      pos1 = @positions.fetch(name1)
      pos2 = @positions.fetch(name2)
      dist = pos1.distance(pos2)
      mp = pos1.midpoint(pos2)
      shortest_dist = 99**99
      closest = nil

      @positions.each { |name, pos|
        next if name == name1 or name == name2
        next if pos.z > pos1.z and pos.z > pos2.z
        next if pos.z < pos1.z and pos.z < pos2.z
        next if @east_coast.include?(name) or @west_coast.include?(name)
        mp_dist = mp.distance(pos)
        next if mp_dist > dist / RIVER_MIDPOINT
        if mp_dist < shortest_dist
          closest = name
          shortest_dist = mp_dist
        end
      }
      closest
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


      # keep looking for midpoints
      nothing_added = true
      loop {
        self.river_path.each_cons(2) { |a, b|
          mp = self.find_river_midpoint(a, b)
          if mp
            nothing_added = false
            @river.add(mp)
            break
          end
        }
        break if nothing_added
        nothing_added = true
      }

      # connect with nearest coast
      closest = nil
      shortest_dist = 9**9
      (@east_coast + @west_coast).each { |name|
        next if name == gulch_name
        pos = @positions.fetch(name)
        next if pos.z > gulch.z
        dist = pos.distance(gulch)
        if dist < shortest_dist
          shortest_dist = dist
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
      terminus = self.river_path.last
      if @east_coast.include?(terminus)
        waterway = @east_coast + @river
      elsif @west_coast.include?(terminus)
        waterway = @west_coast + @river
      else
        return false
      end
      waterway if waterway.include?(name1) and waterway.include?(name2)
    end

    def river?(name1, name2)
      @river if @river.include?(name1) and @river.include?(name2)
    end

    def river_path
      @river.sort_by { |name| -1 * @positions[name].z }
    end

    def land_cost(name1, name2)
      c1 = @cities.fetch(name1)
      c2 = @cities.fetch(name2)
      if c1.type == :island or c2.type == :island
        raise "no land route from #{name1} to #{name2}"
      else
        pos1 = @positions.fetch(name1)
        pos2 = @positions.fetch(name2)
        alt = pos2.z - pos1.z
        d = self.distance(name1, name2)
        d + d * alt * 0.5
      end
    end

    def river_cost(name1, name2)
      if @river.include?(name1) and @river.include?(name2)
        # do the river thing, upstream, etc
        rp = self.river_path
        start = rp.index(name1)
        finish = rp.index(name2)
        if start > finish # going upstream
          path = rp[finish, start - finish + 1].reverse
          river_mult = 8.5
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
        raise "no river route from #{name1} to #{name2}"
      end
    end

    def sea_cost(name1, name2)
      if (@east_coast.include?(name1) and @east_coast.include?(name2)) or
        (@west_coast.include?(name1) and @west_coast.include?(name2))
        self.distance(name1, name2) / 10.0
      else
        raise "no sea route from #{name1} to #{name2}"
      end
    end

    def transport_cost(name1, name2)
      delta = self.river_path.last
      if @east_coast.include?(name1)
        if @east_coast.include?(name2)
          self.sea_cost(name1, name2)
        elsif @river.include?(name2) and @east_coast.include?(delta)
          self.sea_cost(name1, delta) + self.river_cost(delta, name2)
        else
          port = self.east_port(name2)
          self.sea_cost(name1, port) + self.land_cost(port, name2)
        end
      elsif @west_coast.include?(name1)
        if @west_coast.include?(name2)
          self.sea_cost(name1, name2)
        elsif @river.include?(name2) and @west_coast.include?(delta)
          self.sea_cost(name1, delta) + self.river_cost(delta, name2)
        else
          port = self.west_port(name2)
          self.sea_cost(name1, port) + self.land_cost(port, name2)
        end
      elsif @river.include?(name1)
        if @river.include?(name2)
          self.river_cost(name1, name2)
        elsif @east_coast.include?(name2) and @east_coast.include?(delta)
          self.river_cost(name1, delta) + self.sea_cost(delta, name2)
        elsif @west_coast.include?(name2) and @west_coast.include?(delta)
          self.river_cost(name1, delta) + self.sea_cost(delta, name2)
        else
          port = self.river_port(name2)
          self.river_cost(name1, port) + self.land_cost(port, name2)
        end
      else
        if @west_coast.include?(name2)
          port = self.west_port(name1)
          self.land_cost(name1, port) + self.sea_cost(port, name2)
        elsif @east_coast.include?(name2)
          port = self.east_port(name1)
          self.land_cost(name1, port) + self.sea_cost(port, name2)
        elsif @river.include?(name2)
          port = self.river_port(name1)
          self.land_cost(name1, port) + self.river_cost(port, name2)
        else
          self.land_cost(name1, name2)
        end
      end
    end

    def west_port(city_name)
      (@west_coast - @west_isles).sort_by { |port|
        self.distance(city_name, port)
      }.first
    end

    def east_port(city_name)
      (@east_coast - @east_isles).sort_by { |port|
        self.distance(city_name, port)
      }.first
    end

    def river_port(city_name)
      @river.sort_by { |port|
        self.distance(city_name, port)
      }.first
    end
  end
end
