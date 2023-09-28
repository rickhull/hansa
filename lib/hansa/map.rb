require 'hansa/position'
require 'hansa/city'
require 'hansa/city_names'
require 'set'

module Hansa
  class Map
    WEST_ISLES = 0.040
    WEST_COAST = 0.100
    WEST_DELTA = 0.140

    EAST_DELTA = 0.860
    EAST_COAST = 0.900
    EAST_ISLES = 0.960

    # magic constant governs when to stop looking for a midpoint: 1.0 - 2.0?
    RIVER_MIDPOINT = 1.5

    # west isles only
    def self.west_isles?(pos)
      pos.x <= WEST_ISLES
    end

    # west coast only
    def self.west_coast?(pos)
      WEST_ISLES < pos.x and pos.x <= WEST_COAST
    end

    # west delta only
    def self.west_delta?(pos)
      WEST_COAST < pos.x and pos.x <= WEST_DELTA
    end

    # east delta only
    def self.east_delta?(pos)
      EAST_DELTA <= pos.x and pos.x < EAST_COAST
    end

    # east coast only
    def self.east_coast?(pos)
      EAST_COAST <= pos.x and pos.x < EAST_ISLES
    end

    # east isles only
    def self.east_isles?(pos)
      EAST_ISLES <= pos.x
    end

    # deltas only
    def self.delta?(pos)
      self.west_delta?(pos) or self.east_delta?(pos)
    end

    # coasts only
    def self.coast?(pos)
      self.west_coast?(pos) or self.east_coast?(pos)
    end

    # isles only
    def self.isles?(pos)
      self.west_isles?(pos) or self.east_isles?(pos)
    end

    # includes delta, coast, and isles
    def self.coastal?(pos)
      pos.x <= WEST_DELTA or EAST_DELTA < pos.x
    end

    # rows[0][0]   top left
    # rows[0][79]  top right
    # rows[49][0]  bottom left
    # rows[49][79] bottom right
    def self.draw_line(rows, pos1, pos2)
      # temporary
      return

      # x = rows[0].count
      # y = rows.count

      # rownum = y - (pos.y * y).floor - 1
      # colnum = (pos.x * x).floor

      # x1, y1 = pos1.x, pos1.y
      # x2, y2 = pos2.x, pos2.y

      # y = mx + b
      # y1 = m * x1 + b
      # b = y1 - m * x1
      # m = (y2 - y1) / (x2 - x1).to_f
      # b = y1 - m * x1

      # xrow, xcol =

      # a = 2 * (y2 - y1).abs
      # b = a - 2 * (x2 - x1).abs
      # p = a - (x2 - x1).abs

      # wut
      # return false
    end

    # cities is a hash of positions keyed by a name
    # river is an (ordered) array of positions
    def self.render(x: 80, y: 50, cities:, river:)
      # rows[0][0]   top left
      # rows[0][79]  top right
      # rows[49][0]  bottom left
      # rows[49][79] bottom right
      rows = Array.new(y) { Array.new(x) { ' ' } }

      # place a letter for each city into the correct row & column
      cities.each { |name, pos|
        rownum = y - (pos.y * y).floor - 1
        colnum = (pos.x * x).floor
        rows[rownum][colnum] = name[0]
      }

      # add river, drawing lines between points, pairwise
      river.each_cons(2) { |a, b| self.draw_line(rows, a, b) }
      rows.map { |row| row.join }.join($/)
    end

    attr_accessor :scale, :units
    attr_reader :cities, :positions,
                :east_isles, :west_isles,
                :east_coast, :west_coast,
                :east_delta, :west_delta

    def initialize(scale: [1000, 1000, 10_000],
                   units: [:miles, :miles, :feet])
      @scale = scale
      @units = units

      @cities = {}    # name => city
      @positions = {} # name => pos

      # track positions (via city name) that are connected by water
      @west_isles = Set[]
      @west_coast = Set[]
      @west_delta = Set[]
      @river = Set[]
      @river_path = []
      @east_delta = Set[]
      @east_coast = Set[]
      @east_isles = Set[]
    end

    def to_s
      [self.render,
       self.city_report,
       self.water_report].join($/ * 2)
    end

    def city_report
      rpt = []
      @cities.each { |name, city|
        pos = @positions.fetch(name)
        altitude = (pos.z * @scale[2]).round
        rpt << format("%s   %s %s %s %s %s",
                      name.to_s.rjust(16, ' '),
                      pos.centrality.to_s.rjust(5, ' '),
                      pos.quadrant,
                      city.type.to_s.rjust(12, ' '),
                      altitude.to_s.rjust(4, ' '), @units[2])
      }
      rpt.join($/)
    end

    def coastal_river?
      delta = self.river.last
      (@east_coast.include?(delta) or
       @west_coast.include?(delta)) ? delta : false
    end

    def water_report
      river_path = self.river.clone
      west_coast = @west_coast.to_a
      east_coast = @east_coast.to_a
      cr = self.coastal_river?
      if cr
        # put brackets on last item in river
        river_path[-1] = format("[%s]", river_path[-1])

        # if coast, put brackets on coast city
        if @west_coast.include? cr
          west_coast = west_coast.map { |c|
            c == cr ? format("[%s]", c) : c
          }
        elsif @east_coast.include? cr
          east_coast = east_coast.map { |c|
            c == cr ? format("[%s]", c) : c
          }
        else
          raise("wut: #{cr}")
        end
      end

      ary = []
      ary << format("West isles: %s", @west_isles.join(', '))
      ary << format("West coast: %s", west_coast.join(', '))
      ary << ''
      ary << format("River: %s", river_path.join(' > '))
      ary << ''
      ary << format("East coast: %s", east_coast.join(', '))
      ary << format("East isles: %s", @east_isles.join(', '))
      ary.join($/)
    end

    # from outermost to innermost:
    # islands
    # coastal
    # delta
    # inland (anything except coastal)
    def generate(cities = 25)
      cities.times { |i|
        sym = (97 + i).chr.to_sym
        pos = Position.generate

        if Map.isles?(pos)
          type = :island
          pos.vec[2] /= 2.0 # halve the altitude
          name = Hansa.city_name(sym: sym, locale: type, scope: :usa)
          (Map.east_isles?(pos) ? @east_isles : @west_isles).add name
        elsif Map.coast?(pos)
          type = :coastal
          pos.vec[2] /= 10.0 # crush the altitude
          name = Hansa.city_name(sym: sym, locale: type, scope: :usa)
          (Map.east_coast?(pos) ? @east_coast : @west_coast).add name
        elsif Map.delta?(pos)
          type = :delta
          pos.vec[2] /= 20.0 # demolish the altitude
          name = Hansa.city_name(sym: sym, locale: type, scope: :usa)
          (Map.east_delta?(pos) ? @east_delta : @west_delta).add name
        else
          if pos.vec[2] > 0.5
            # mountain
            type = (City::TYPES.keys -
                    [:coastal, :island, :delta, :farming]).sample
            name = Hansa.city_name(sym: sym, locale: :mountain, scope: :usa)
          else
            # inland
            type = (City::TYPES.keys - [:coastal, :island, :delta]).sample
            name = Hansa.city_name(sym: sym, locale: :inland, scope: :usa)
          end
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
        next if self.east_sea?(name) or self.west_sea?(name)
        next if @east_delta.include?(name) or @west_delta.include?(name)
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
        self.river(cached: false).each_cons(2) { |a, b|
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
      if closest
        # add to river
        @river.add(closest)
        # add to coast
        pos = @positions.fetch(closest)
        if pos.we == :east
          @east_coast.add closest
        else
          @west_coast.add closest
        end
      end
      self.river(cached: false)
    end

    def river(cached: true)
      if !cached or !@river_path or @river_path.empty?
        @river_path = @river.sort_by { |name|
          -1 * @positions.fetch(name).z
        }
      end
      @river_path
    end

    def render(x: 80, y: 50)
      self.class.render(x: x, y: y,
                        cities: @positions,
                        river: self.river.map { |n| @positions.fetch(n) })
    end

    def distance(name1, name2)
      Position.distance(@positions.fetch(name1), @positions.fetch(name2))
    end

    def midpoint(name1, name2)
      Position.midpoint(@positions.fetch(name1), @positions.fetch(name2))
    end

    def river?(name1, name2)
      @river.include?(name1) and @river.include?(name2)
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
        start = @river.index(name1)
        finish = @river.index(name2)
        if start > finish # going upstream
          path = @river[finish, start - finish + 1].reverse
          river_mult = 8.5
        else
          path = @river[start, finish - start + 1]
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
      delta = self.river.last

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
