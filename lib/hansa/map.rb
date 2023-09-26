require 'hansa/city'
require 'hansa/city_names'
require 'matrix'
require 'set'

module Hansa
  class Position
    class OutOfBounds < RuntimeError; end

    def self.quadrant(vec)
      ary = []
      if vec[1] > 0.5
        ary[0] = :north
        ary[2] = 'N'
      else
        ary[0] = :south
        ary[2] = 'S'
      end
      if vec[0] > 0.5
        ary[1] = :east
        ary[2] << 'E'
      else
        ary[1] = :west
        ary[2] << 'W'
      end
      ary
    end

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

    attr_reader :vec, :r3, :r2, :ns, :we, :quadrant

    def initialize(x, y, z)
      unless self.class.valid?(x, y, z)
        raise(OutOfBounds, format("%.2f %.2f %.2f", x, y, z))
      end
      @vec = Vector[x, y, z]
      @r3 = self.radial(3)
      @r2 = self.radial(2)
      @ns, @we, @quadrant = *Position.quadrant(@vec)
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

    def radial(dim = 3)
      c = Vector[0.5, 0.5, 0.5]
      case dim
      when 2
        c - Vector[@vec[0], @vec[1], 0.5]
      when 3
        c - @vec
      else
        raise "unexpected dim: #{dim.inspect}"
      end
    end

    def distance(pos2)
      self.class.distance(self, pos2)
    end

    def midpoint(pos2)
      self.class.midpoint(self, pos2)
    end

    def central
      if @r2.r < 0.2
        :inner
      elsif @r2.r < 0.4
        :core
      else
        :outer
      end
    end
  end

  class Map
    WEST_ISLES = 0.05
    WEST_COAST = 0.10
    WEST_DELTA = 0.15

    EAST_DELTA = 0.85
    EAST_COAST = 0.90
    EAST_ISLES = 0.95

    # magic constant governs when to stop looking for a midpoint: 1.0 - 2.0?
    RIVER_MIDPOINT = 1.5

    def self.west_isles?(pos)
      pos.x <= WEST_ISLES
    end

    def self.west_coast?(pos)
      WEST_ISLES < pos.x and pos.x <= WEST_COAST
    end

    def self.west_delta?(pos)
      WEST_COAST < pos.x and pos.x <= WEST_DELTA
    end

    def self.east_delta?(pos)
      EAST_DELTA <= pos.x and pos.x < EAST_COAST
    end

    def self.east_coast?(pos)
      EAST_COAST <= pos.x and pos.x < EAST_ISLES
    end

    def self.east_isles?(pos)
      EAST_ISLES <= pos.x
    end

    def self.delta?(pos)
      self.west_delta?(pos) or self.east_delta?(pos)
    end

    def self.coast?(pos)
      self.west_coast?(pos) or self.east_coast?(pos)
    end

    def self.isles?(pos)
      self.west_isles?(pos) or self.east_isles?(pos)
    end

    def self.coastal?(pos)
      pos.x <= WEST_DELTA or EAST_DELTA < pos.x
    end

    attr_accessor :scale, :units
    attr_reader :cities, :positions,
                :east_isles, :west_isles,
                :east_coast, :west_coast,
                :east_delta, :west_delta, :river

    def initialize(scale: Vector[1000, 1000, 10_000],
                   units: Vector[:miles, :miles, :feet])
      @scale = scale
      @units = units

      @cities = {}    # name => city
      @positions = {} # name => pos

      # track positions (via city name) that are connected by water
      @east_delta = Set[]
      @west_delta = Set[]
      @east_coast = Set[]
      @west_coast = Set[]
      @east_isles = Set[]
      @west_isles = Set[]
      @river = Set[]
    end

    def to_s
      [self.render,
       self.city_report,
       self.water_report].join($/ * 2)
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

    def navigable_delta?
      terminus = self.river_path.last
      terminus if Map.coastal?(@positions.fetch(terminus))
    end

    def water_report
      ary = []
      ary << format("West isles: %s", self.west_isles.join(', '))
      ary << format("West coast: %s", self.west_coast.join(', '))

      delta = self.navigable_delta?
      if delta
        if @west_delta.include? delta
          ary << format("West navigable delta: %s", delta)
        elsif @east_delta.include? delta
          ary << format("East navigable delta: %s", delta)
        end
      end

      ary << format("River: %s", self.river_path.join(' > '))
      ary << format("East coast: %s", self.east_coast.join(', '))
      ary << format("East isles: %s", self.east_isles.join(', '))
      ary << ''
      ary << "Delta, presumed non-navigable:"
      ary << '---'
      ary << format("West: %s", self.west_delta.join(', '))
      ary << format("East: %s", self.east_delta.join(', '))
      ary.join($/)
    end

    # from outermost to innermost:
    # islands
    # coastal / delta
    # inland (anything except coastal)
    def generate(cities = 25)
      cities.times { |i|
        sym = (97 + i).chr.to_sym
        pos = Position.random

        if Map.isles?(pos)
          # island, add to _coast and _isles
          pos.vec[2] /= 2.0 # halve the altitude
          type = :island
          name = City::COASTAL_NAMES.fetch(sym).sample
          (Map.east_isles?(pos) ? @east_isles : @west_isles).add name
        elsif Map.coast?(pos)
          # coast, add to _coast
          pos.vec[2] /= 10.0 # crush the altitude
          type = :coastal
          name = City::COASTAL_NAMES.fetch(sym).sample
          (Map.east_coast?(pos) ? @east_coast : @west_coast).add name
        elsif Map.delta?(pos)
          # delta, not part of _coast
          pos.vec[2] /= 20.0 # demolish the altitude
          type = :delta
          name = City::DELTA_NAMES.fetch(sym).sample
          (Map.east_delta?(pos) ? @east_delta : @west_delta).add name
        else
          # inland
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

      # try to connect with nearest coast
      closest = nil
      shortest_dist = 9**9
      (@east_coast + @west_coast +
       @east_delta + @west_delta).each { |name|
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

    def river?(name1, name2)
      @river if @river.include?(name1) and @river.include?(name2)
    end

    def river_path
      @river.sort_by { |name| -1 * @positions[name].z }
    end

    def land_cost(name1, name2)
      puts "land_cost(#{name1}, #{name2})"
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
      puts "river_cost(#{name1}, #{name2})"
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

    def east_sea?(name)
      @east_coast.include?(name) or @east_isles.include?(name)
    end

    def west_sea?(name)
      @west_coast.include?(name) or @west_isles.include?(name)
    end

    def sea_cost(name1, name2)
      puts "sea_cost(#{name1}, #{name2})"
      if (self.east_sea?(name1) and self.east_sea?(name2)) or
        (self.west_sea?(name1) and self.west_sea?(name2))
        self.distance(name1, name2) / 10.0
      else
        raise "no sea route from #{name1} to #{name2}"
      end
    end

    def transport_cost(name1, name2)
      # consider: self.navigable_delta?
      delta = self.river_path.last

      if self.east_sea?(name1)
        if self.east_sea?(name2)
          self.sea_cost(name1, name2)
        elsif @river.include?(name2) and
              (@east_coast + @east_delta).include?(delta)
          self.sea_cost(name1, delta) + self.river_cost(delta, name2)
        else
          port = self.east_port(name2)
          self.sea_cost(name1, port) + self.land_cost(port, name2)
        end
      elsif self.west_sea?(name1)
        if self.west_sea?(name2)
          self.sea_cost(name1, name2)
        elsif @river.include?(name2) and
              (@west_coast + @west_delta).include?(delta)
          self.sea_cost(name1, delta) + self.river_cost(delta, name2)
        else
          port = self.west_port(name2)
          self.sea_cost(name1, port) + self.land_cost(port, name2)
        end
      elsif @river.include?(name1)
        if @river.include?(name2)
          self.river_cost(name1, name2)
        elsif self.east_sea?(name2) and
             (@east_coast + @east_delta).include?(delta)
          self.river_cost(name1, delta) + self.sea_cost(delta, name2)
        elsif self.west_sea?(name2) and
             (@west_coast + @west_delta).include?(delta)
          self.river_cost(name1, delta) + self.sea_cost(delta, name2)
        else
          port = self.river_port(name2)
          self.river_cost(name1, port) + self.land_cost(port, name2)
        end
      else
        if self.west_sea?(name2)
          port = self.west_port(name1)
          self.land_cost(name1, port) + self.sea_cost(port, name2)
        elsif self.east_sea?(name2)
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
      @west_coast.sort_by { |port| self.distance(city_name, port) }.first
    end

    def east_port(city_name)
      @east_coast.sort_by { |port| self.distance(city_name, port) }.first
    end

    def river_port(city_name)
      @river.sort_by { |port| self.distance(city_name, port) }.first
    end
  end
end
