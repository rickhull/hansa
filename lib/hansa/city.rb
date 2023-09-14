require 'hansa'

module Hansa
  class City
    class LaborShortfall < RuntimeError; end

    def self.labor_check!(labor, pop)
      if labor > pop
        raise(LaborShortfall,
              format("pop %i cannot support labor %i", pop, labor))
      end
      labor
    end

    attr_accessor :name, :pop
    attr_reader :terrain, :type

    def initialize(name: 'Hansa', pop: 10_000, type: nil)
      @name = name
      @pop = pop
      self.type = type
    end

    # regenerate terrain when changing city type
    def type=(val)
      @terrain = Hansa.terrain(val)
      @type = val
    end

    # how much labor is required to produce e.g.
    #   apple: 2 units
    #   bread: 5 units
    def labor(goods_hsh)
      Hansa.labor_cost(goods_hsh, terrain: @terrain)
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
      utility = Hansa.utility(goods_hsh)
      Hash[labor: labor,
           total_labor: total_labor,
           utility: utility,
           total_utility: utility.values.sum + leisure,
           leisure: leisure]
    end

    # generate a proposal for _n_ units of every good
    def proposal(n = 1)
      @terrain.transform_values { n }
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
    def advisor(take = nil)
      hsh = {}
      @terrain.each { |good, labor|
        utils = Hansa::CONSUMPTION.fetch(good)
        hsh[good] = Rational(utils, labor)
      }
      hsh.sort_by { |k, v| -1 * v }
    end
  end
end
