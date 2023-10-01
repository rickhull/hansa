require 'hansa/position'
require 'hansa/city'
require 'hansa/city_names'
require 'set'

module Hansa
  class Island
    REGION_WIDTH = 0.030
  end

  class Coast
    REGION_WIDTH = 0.065
  end

  class Delta
    REGION_WIDTH = 0.055
  end

  class Inland
  end

  class Highland < Inland
  end

  class Lowland < Inland
  end

  class Map
    # regions defined on the x-axis
    WEST_ISLES = Island::REGION_WIDTH
    WEST_COAST = WEST_ISLES + Coast::REGION_WIDTH
    WEST_DELTA = WEST_COAST + Delta::REGION_WIDTH

    # etc
    EAST_ISLES = 1 - Island::REGION_WIDTH
    EAST_COAST = EAST_ISLES - Coast::REGION_WIDTH
    EAST_DELTA = EAST_COAST - Delta::REGION_WIDTH

    # defaults, character grid on terminal
    RENDER_X = 80
    RENDER_Y = 40

    # magic constant governs when to stop looking for a midpoint: 1.0 - 2.0?
    RIVER_MIDPOINT = 1.7

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

    # excludes delta, coast, and isles
    def self.inland?(pos)
      WEST_DELTA <= pos.x and pos.x <=  EAST_DELTA
    end

    # rows[0][0]   top left
    # rows[0][79]  top right
    # rows[49][0]  bottom left
    # rows[49][79] bottom right
    def self.draw_line(rows, pos1, pos2)
      xdim = rows[0].count
      ydim = rows.count

      rownum = -> (y) { ydim - (y * ydim).floor - 1 }
      colnum = -> (x) { (x * xdim).floor }

      x1, y1 = colnum.call(pos1.x), rownum.call(pos1.y)
      x2, y2 = colnum.call(pos2.x), rownum.call(pos2.y)

      dy = y2 - y1
      dx = x2 - x1

      # y = mx + b
      # x = (y-b)/m
      # b = y - mx
      m = dy / dx.to_f
      b = y1 - m * x1

      if dy.abs > dx.abs
        # steep: iterate over y pixels
        low_y = y2 > y1 ? y1 : y2
        dy.abs.times { |i|
          next if i == 0
          y = low_y + i
          # handle vertical
          x = (dx == 0) ? x1 : ((y - b) / m).round
          rows[y][x] = '*'
        }
      else
        # shallow: iterate over x pixels
        low_x = x2 > x1 ? x1 : x2
        dx.abs.times { |i|
          next if i == 0
          x = low_x + i
          # handle horizontal
          y = (dy == 0) ? y1 : (m * x + b).round
          rows[y][x] = '*'
        }
      end
      rows
    end

    # cities is a hash of positions keyed by a name
    # river is an (ordered) array of positions
    def self.render(x: RENDER_X, y: RENDER_Y, cities:, river:)
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

      self.reset!(true)
    end

    def reset!(button_pushed = false)
      if button_pushed
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
      else
        warn "not resetting, button_pushed = #{button_pushed}"
      end
    end

    def to_s
      [self.render,
       self.city_report,
       self.water_report].join($/ * 2)
    end

    def render(x: RENDER_X, y: RENDER_Y)
      self.class.render(x: x, y: y,
                        cities: @positions,
                        river: self.river.map { |n| @positions.fetch(n) })
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
      ary << format("     River: %s", river_path.join(' > '))
      ary << format("East coast: %s", east_coast.join(', '))
      ary << format("East isles: %s", @east_isles.join(', '))
      ary.join($/)
    end

    def coastal_river?
      delta = self.river.last
      (@east_coast.include?(delta) or
       @west_coast.include?(delta)) ? delta : false
    end

    # from outermost to innermost:
    # islands
    # coastal
    # delta
    # inland (anything except above)
    def generate(cities = 20)
      self.reset!(true)
      cities.times { |i|
        # advance :a to :z and back to :a
        sym = Hansa.initial_symbol(i)
        # get a randomized position in 3D space (not uniformly random)
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

    # destroys any previously created river
    def add_river
      # return false if @positions.empty?
      @river = Set[]
      @river_path = []

      # find the highest pos and lowest pos
      # the floor is inland; makes it more likely the river finds a delta/coast
      floor = 0.01
      apex_name, gulch_name = 'center', 'center'
      apex, gulch = 0, 1
      @positions.each { |name, pos|
        next if self.east_sea?(name) or self.west_sea?(name)
        next if @east_delta.include?(name) or @west_delta.include?(name)
        if pos.z >= apex
          apex_name = name
          apex = pos.z
        elsif pos.z <= gulch and pos.z > floor
          gulch_name = name
          gulch = pos.z
        end
      }
      @river.add apex_name
      @river.add gulch_name

      # keep looking for midpoints
      # DANGER ZONE!
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
      gulch = @positions.fetch(gulch_name)
      shortest_dist = 0.5
      closest = nil
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
        # add to coast! (superpower for delta region)
        pos = @positions.fetch(closest)
        if pos.we == :east
          @east_coast.add closest
        else
          @west_coast.add closest
        end
      end
      self.river(cached: false)
    end

    def find_river_midpoint(name1, name2)
      pos1 = @positions.fetch(name1)
      pos2 = @positions.fetch(name2)
      dist = pos1.distance(pos2)
      mp = pos1.midpoint(pos2)
      shortest_dist = 5
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

    def river(cached: true)
      if !cached or !@river_path or @river_path.empty?
        @river_path = @river.sort_by { |name|
          -1 * @positions.fetch(name).z
        }
      end
      @river_path
    end

    def transport_cost(name1, name2)
      delta = self.river.last

      if self.east_sea?(name1)
        # start at east sea
        if self.east_sea?(name2)
          # east sea to east sea
          self.sea_cost(name1, name2)
        elsif @river.include?(name2) and
              (@east_coast + @east_delta).include?(delta)
          # east sea to upriver
          self.sea_cost(name1, delta) + self.river_cost(delta, name2)
        else
          # east sea to east port to inland
          port = self.east_port(name2)
          self.sea_cost(name1, port) +
            self.land_cost(port, name2, river_check: true)
        end
      elsif self.west_sea?(name1)
        # start at west sea
        if self.west_sea?(name2)
          # west sea to west sea
          self.sea_cost(name1, name2)
        elsif @river.include?(name2) and
              (@west_coast + @west_delta).include?(delta)
          # west sea to upriver
          self.sea_cost(name1, delta) + self.river_cost(delta, name2)
        else
          # west sea to west port to inland
          port = self.west_port(name2)
          self.sea_cost(name1, port) +
            self.land_cost(port, name2, river_check: true)
        end
      elsif @river.include?(name1)
        # start on the river
        if @river.include?(name2)
          # river to river
          self.river_cost(name1, name2)
        elsif self.east_sea?(name2)
          if (@east_coast + @east_delta).include?(delta)
            # downriver to east sea
            self.river_cost(name1, delta) + self.sea_cost(delta, name2)
          else
            # no delta to the sea, find a port over land
            port = self.east_port(name1)
            self.land_cost(name1, port, river_check: true) +
              self.sea_cost(port, name2)
          end
        elsif self.west_sea?(name2)
          if (@west_coast + @west_delta).include?(delta)
            self.river_cost(name1, delta) + self.sea_cost(delta, name2)
          else
            # no delta to the sea, find a port over land
            port = self.west_port(name1)
            self.land_cost(name1, port, river_check: true) +
              self.sea_cost(port, name2)
          end
        else
          # river to inland
          port = self.river_port(name2)
          self.river_cost(name1, port) + self.land_cost(port, name2)
        end
      else
        # starting inland not on a river
        if @river.include?(name2)
          # inland to river; check this first!
          port = self.river_port(name1)
          self.land_cost(name1, port) + self.river_cost(port, name2)
        elsif self.west_sea?(name2)
          # inland to west sea
          port = @west_coast.include?(delta) ? delta : self.west_port(name1)
          self.land_cost(name1, port, river_check: true) +
            self.sea_cost(port, name2)
        elsif self.east_sea?(name2)
          # inland to east sea
          port = @east_coast.include?(delta) ? delta : self.east_port(name1)
          self.land_cost(name1, port, river_check: true) +
            self.sea_cost(port, name2)
        else
          # inland to inland
          self.land_cost(name1, name2, river_check: true)
        end
      end
    end

    def land_check?(name1, name2)
      c1 = @cities.fetch(name1)
      c2 = @cities.fetch(name2)
      c1.type != :island and c2.type != :island
    end

    def land_cost(name1, name2, river_check: false)
      return 0 if name1 == name2
      if !self.land_check?(name1, name2)
        raise "no land route from #{name1} to #{name2}"
      end
      puts "land_cost(#{name1}, #{name2})"
      pos1 = @positions.fetch(name1)
      pos2 = @positions.fetch(name2)
      alt = pos2.z - pos1.z
      d = self.distance(name1, name2)
      land_only = d + d * alt * 0.5
      with_river = river_check ? self.river_check(name1, name2) : land_only
      land_only <= with_river ? land_only : with_river
    end

    # cost when using the river between two land cities
    def river_check(name1, name2)
      return 0 if name1 == name2
      if !self.land_check?(name1, name2)
        raise "no land route from #{name1} to #{name2}"
      end

      # if name1 or name2 are coastal, we can look for river + coastal
      delta = self.river.last
      if @east_coast.include?(name1) or @east_coast.include?(name2) and
         @east_coast.include?(delta)
        # check east delta route
        if @east_coast.include?(name1)
          # coast -> delta -> upriver -> inland
          port = self.river_port(name2)
          self.sea_cost(name1, delta) +
            self.river_cost(delta, port) +
            self.land_cost(port, name2)
        else
          # inland -> downriver -> delta -> west_coast
          port = self.river_port(name1)
          self.land_cost(name1, port) +
            self.river_cost(port, delta) +
            self.sea_cost(delta, name2)
        end
      elsif @west_coast.include?(name1) or @west_coast.include?(name2) and
            @west_coast.include?(delta)
        # check west delta route
        if @west_coast.include?(name1)
          # west_coast -> delta -> upriver -> inland
          port = self.river_port(name2)
          self.sea_cost(name1, delta) +
            self.river_cost(delta, port) +
            self.land_cost(port, name2)
        else
          # inland -> downriver -> delta -> west_coast
          port = self.river_port(name1)
          self.land_cost(name1, port) +
            self.river_cost(port, delta) +
            self.sea_cost(delta, name2)
        end
      else
        # no sea routes; dry -> port -> river -> port -> dry
        port1 = self.river_port(name1)
        port2 = self.river_port(name2)
        self.land_cost(name1, port1, river_check: false) +
          self.river_cost(port1, port2) +
          self.land_cost(port2, name2, river_check: false)
      end
    end

    def river_cost(name1, name2)
      return 0 if name1 == name2
      puts "river_cost(#{name1}, #{name2})"
      if self.river?(name1, name2)
        # upstream costs more than downstream
        start = @river_path.index(name1)
        finish = @river_path.index(name2)
        if start > finish # going upstream
          path = @river_path[finish, start - finish + 1].reverse
          river_mult = 8.5
        else
          path = @river_path[start, finish - start + 1]
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
      return 0 if name1 == name2
      puts "sea_cost(#{name1}, #{name2})"
      if (self.east_sea?(name1) and self.east_sea?(name2)) or
        (self.west_sea?(name1) and self.west_sea?(name2))
        self.distance(name1, name2) / 10.0
      else
        raise "no sea route from #{name1} to #{name2}"
      end
    end

    def distance(name1, name2)
      return 0 if name1 == name2
      Position.distance(@positions.fetch(name1), @positions.fetch(name2))
    end

    def midpoint(name1, name2)
      Position.midpoint(@positions.fetch(name1), @positions.fetch(name2))
    end

    def river?(name1, name2)
      @river.include?(name1) and @river.include?(name2)
    end

    def east_sea?(name)
      @east_coast.include?(name) or @east_isles.include?(name)
    end

    def west_sea?(name)
      @west_coast.include?(name) or @west_isles.include?(name)
    end

    def west_port(name)
      @west_coast.sort_by { |port| self.land_cost(name, port) }.first
    end

    def east_port(name)
      @east_coast.sort_by { |port| self.land_cost(name, port) }.first
    end

    def river_port(name)
      @river.sort_by { |port| self.land_cost(name, port) }.first
    end
  end
end
