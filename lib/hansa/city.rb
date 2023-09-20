require 'hansa'

module Hansa
  class City
    class LaborShortfall < RuntimeError; end

    TYPES = {
      nil => {},
      farming: {
        apple: 0.2,
        bread: 0.6,
        corn: 0.2,
        donut: 0.6,
        egg: 0.3,
        grape: 0.2,
        potato: 0.2,
        restaurant_meal: 0.6,
        fancy_meal: 0.6,
        cinema: 1.5,
        water: 0.75,
        fuel: 0.8,
        wood: 0.8,
        bicycle: 0.75,
        motorcycle: 0.75,
        truck: 0.8,
        house: 0.75,
        watch: 1.2,
        tv: 1.7,
        computer: 1.7,
        phone: 1.2,
        medicine: 0.75,
        water_filter: 0.8,
        hand_tools: 0.8,
      },
      high_tech: {
        donut: 0.65,
        restaurant_meal: 0.65,
        cinema: 0.5,
        amusement_park: 0.5,
        water: 0.35,
        fuel: 0.5,
        bicycle: 0.5,
        motorcycle: 0.5,
        car: 0.6,
        truck: 0.6,
        apartment: 0.5,
        house: 0.6,
        watch: 0.05,
        tv: 0.15,
        computer: 0.15,
        phone: 0.15,
        medicine: 0.15,
        healthcare: 0.6,
      },
      industrial: {
        bread: 0.2,
        donut: 0.35,
        restaurant_meal: 0.75,
        water: 0.4,
        fuel: 0.4,
        wood: 0.6,
        bicycle: 0.25,
        motorcycle: 0.5,
        car: 0.5,
        truck: 0.4,
        apartment: 0.5,
        house: 0.6,
        clothes: 0.2,
        fashion: 0.2,
        medicine: 0.2,
        light_bulb: 0.2,
        water_filter: 0.2,
        hand_tools: 0.1,
        power_tools: 0.2,
      },
      culture: {
        restaurant_meal: 0.5,
        fancy_meal: 0.5,
        opera: 0.5,
        theater: 0.5,
        fashion: 0.6,
        high_fashion: 0.4,
        apartment: 0.65,
        bicycle: 0.65,
        motorcycle: 0.8,
        car: 1.7,
        truck: 1.7,
        house: 1.7,
      },
      coastal: {
        apple: 0.6,
        fish: 0.2,
        egg: 0.6,
        grape: 0.4,
        restaurant_meal: 0.6,
        fancy_meal: 0.6,
        cinema: 0.75,
        opera: 0.75,
        theater: 0.75,
        amusement_park: 0.5,
        water: 0.8,
        fuel: 0.8,
        bicycle: 0.75,
        motorcycle: 0.8,
        car: 0.75,
        truck: 0.75,
        house: 1.7,
        fashion: 0.8,
        high_fashion: 0.8,
        medicine: 0.5,
        healthcare: 0.75,
        light_bulb: 0.8,
        water_filter: 0.4,
      },
      undeveloped: {
        bread: 2,
        donut: 2,
        restaurant_meal: 2,
        fancy_meal: 5,
        cinema: 2,
        opera: 2,
        theater: 2,
        amusement_park: 5,
        water: 2,
        fuel: 2,
        bicycle: 2.5,
        motorcycle: 4,
        car: 2.5,
        truck: 2.5,
        apartment: 2,
        house: 4,
        watch: 3,
        tv: 7,
        computer: 1.7,
        phone: 1.7,
        clothes: 1.6,
        fashion: 0.5,
        high_fashion: 80,
        medicine: 2,
        healthcare: 3,
        light_bulb: 4,
        water_filter: 2,
        hand_tools: 1.5,
        power_tools: 2.5,
      },
    }

    MODIFIED = {}

    # apply modifier (default nil) values to LABOR; return a new hash
    def self.modify(type = nil)
      cached = MODIFIED[type]
      return cached unless cached.nil?
      mods = TYPES.fetch type
      hsh = {}
      LABOR.each { |good, labor|
        m = mods[good] || 1
        hsh[good] = [1, labor * m].max
      }
      hsh
    end

    # generate a LABOR-like hash with modifications and disturbances
    def self.terrain(type = nil)
      hsh = {}
      self.modify(type).each { |good, labor|
        delta = labor * (rand(0) - 0.5) / 2
        hsh[good] = [1, (labor + delta).round].max
      }
      hsh
    end

    # diminishing marginal utility
    # 0.9 <= DMU <= 1.0
    def self.dmu(pop)
      if pop <= 10
        0.9
      elsif pop <= 100
        0.92
      elsif pop <= 1000
        0.95
      elsif pop <= 5000
        0.965
      elsif pop <= 10_000
        0.98
      elsif pop <= 100_000
        0.99
      else
        0.999
      end
    end

    # increasing complementary utility
    # 1.0 <= ICU <= 1.1
    def self.icu(pop)
      if pop <= 10
        1.1
      elsif pop <= 100
        1.05
      elsif pop <= 1000
        1.001
      elsif pop <= 5000
        1.0001
      elsif pop <= 10_000
        1.00002
      elsif pop <= 100_000
        1.00001
      else
        1.000005
      end
    end

    def self.labor_check!(labor, pop)
      if labor > pop
        raise(LaborShortfall,
              format("pop %i cannot support labor %i", pop, labor))
      end
      labor
    end

    attr_accessor :name, :pop, :dmu, :icu
    attr_reader :terrain, :type

    def initialize(name: 'Hansa', pop: 10_000, type: nil)
      @name = name
      @pop = pop
      @dmu = self.class.dmu(@pop)
      @icu = self.class.icu(@pop)
      self.type = type
    end

    def to_s
      format("%s, pop: %i%s\tDMU: %.3f ICU: %.5f",
             @name, @pop, (@type ? " (#{@type})" : ''), @dmu, @icu)
    end

    # regenerate terrain when changing city type
    def type=(val)
      @terrain = self.class.terrain(val)
      @type = val
    end

    # how much labor is required to produce e.g.
    #   apple: 2 units
    #   bread: 5 units
    def labor(goods_hsh)
      labor = {}
      goods_hsh.each { |good, count|
        labor[good] = count * @terrain.fetch(good)
      }
      labor
    end

    # how much utility is generated by e.g.
    #   apple: 2 units
    #   bread: 5 units
    def utility(goods_hsh)
      total_goods = goods_hsh.values.sum
      utility = {}
      goods_hsh.each { |good, count|
        other_goods = total_goods - count
        utils = CONSUMPTION.fetch(good)
        # for every util, add them up
        utility[good] = Array.new(count) { |i|
          # the multiplier gets smaller as i goes up
          utils * (@dmu ** i)
        }.sum.round * (@icu ** other_goods)
      }
      utility
    end

    # given different amounts of different goods
    # show the expected labor required and utility generated, e.g.
    #   apple: 2 units
    #   bread: 5 units
    def propose(goods_hsh)
      labor = self.labor(goods_hsh)
      total_labor = labor.values.sum
      leisure = @pop - total_labor
      self.class.labor_check!(total_labor, @pop)
      utility = self.utility(goods_hsh)
      Hash[labor: labor,
           total_labor: total_labor,
           utility: utility,
           total_utility: utility.values.sum,
           leisure: leisure]
    end

    # expected production (good => units) from e.g.
    #   apple: 10 labor assigned
    #   bread:  5 labor assigned
    def allocate(goods_labor)
      total_labor = self.class.labor_check!(goods_labor.values.sum, @pop)
      hsh = {}
      goods_labor.each { |good, labor|
        # how many units can we produce for this good?
        hsh[good] = (labor / @terrain.fetch(good)).floor
      }
      hsh[:leisure] = @pop - total_labor
      hsh
    end

    # based on @terrain, sort by utils per labor
    def advisor(pow = 1)
      hsh = {}
      @terrain.each { |good, labor|
        utils = Hansa::CONSUMPTION.fetch(good)
        hsh[good] = utils.to_f / labor ** pow
      }
      hsh.sort_by { |k, v| -1 * v }
    end
  end
end
