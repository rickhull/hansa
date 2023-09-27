require 'minitest/autorun'
require 'hansa/city'

include Hansa

describe Hansa do
  describe City do
    describe "City.new" do
      it "has name, pop, dmu, icu, terrain, type" do
        c = City.new
        expect(c.name).must_be_kind_of String
        expect(c.pop).must_be_kind_of Numeric
        expect(c.dmu).must_be_kind_of Numeric
        expect(c.icu).must_be_kind_of Numeric
        expect(c.terrain).must_be_kind_of Hash
        expect(c.type).must_be_kind_of Symbol
      end

      it "has optional initialization parameters" do
        c = City.new
        expect(c).must_be_kind_of Hansa::City

        c = City.new(name: 'xyz')
        expect(c.name).must_equal 'xyz'

        c = City.new(pop: 2000)
        expect(c.pop).must_equal 2000

        c = City.new(type: :undeveloped)
        expect(c.type).must_equal :undeveloped
      end
    end

    describe "City types" do
      # City.new
      it "may be one of several types, with a default" do
        # default
        expect(City.new).must_be_kind_of Hansa::City
        expect(City.new(type: :developing)).must_be_kind_of Hansa::City

        # farming, high_tech, industrial, coastal, culture, undeveloped
        expect(City.new(type: :farming)).must_be_kind_of Hansa::City
        expect(City.new(type: :high_tech)).must_be_kind_of Hansa::City
        expect(City.new(type: :industrial)).must_be_kind_of Hansa::City
        expect(City.new(type: :coastal)).must_be_kind_of Hansa::City
        expect(City.new(type: :culture)).must_be_kind_of Hansa::City
        expect(City.new(type: :undeveloped)).must_be_kind_of Hansa::City

        expect { City.new(type: :invalid) }.must_raise
      end

      # City.modify
      it "modifies the base Goods::LABOR costs according to city type" do
        expect(City.modify(:developing)).must_equal Goods::LABOR
        expect(City.modify(:farming)).wont_equal Goods::LABOR
      end

      # City#type=
      it "regenerates terrain when the city type is changed" do
        c = City.new
        t = c.terrain
        c.type = :developing
        expect(c.terrain).wont_equal t
        c.type = :farming
        expect(c.type) == :farming
      end
    end

    describe "Labor cost and city terrain" do
      # City.terrain
      it "has a terrain which modifies labor costs" do
        terrain = City.terrain
        expect(terrain).wont_equal Goods::LABOR

        industrial_labor = City.modify(:industrial)
        industrial_terrain = City.terrain(:industrial)
        expect(industrial_terrain).wont_equal industrial_labor
      end

      # City#labor
      it "determines the labor cost (per-good) for a basket of goods" do
        c = City.new
        basket = { apple: 2, bread: 5 }
        labor = c.labor(basket)

        expect(labor[:apple]).must_be_kind_of Numeric
        expect(labor[:bread]).must_be_kind_of Numeric
        expect(labor[:other]).must_be_nil

        # simply multiply unit count * labor cost
        basket.each { |good, count|
          expect(labor[good]).must_equal count * c.terrain[good]
        }
      end
    end

    describe "Utility generated from consumption" do
      # City#utility
      it "determines the utility generated from consuming a basket of goods" do
        c = City.new
        basket = { corn: 7, donut: 5 }
        utility = c.utility(basket)

        expect(utility[:corn]).must_be_kind_of Numeric
        expect(utility[:donut]).must_be_kind_of Numeric
        expect(utility[:other]).must_be_nil

        # utility is very complicated to predict due to DMU and ICU
        basket.each { |good, count|
          expect(utility[good]).must_be :>, 0
        }
      end

      # City.dmu
      it "varies Diminishing Marginal Utility based on population" do
        [1, 99, 530, 9874235].each { |pop|
          expect(City.dmu(pop)).must_be :>=, 0.9
          expect(City.dmu(pop)).must_be :<=, 1.0
        }

        tiny = City.new(pop: 15)
        huge = City.new(pop: 9999999)

        expect(tiny.dmu).must_be :<, huge.dmu
      end

      # City.icu
      it "varies Increasing Complementary Utility based on population" do
        [1, 99, 530, 9874235].each { |pop|
          expect(City.icu(pop)).must_be :>=, 1.0
          expect(City.icu(pop)).must_be :<=, 1.1
        }
        tiny = City.new(pop: 15)
        huge = City.new(pop: 9999999)

        expect(tiny.icu).must_be :>, huge.icu
      end
    end

    describe "Diminishing Marginal Utility" do
      it "mandates decreasing additional utility from N+1 goods produced" do
        c = City.new
        basket = { apple: 5, bread: 7 }
        utils = c.utility(basket)
        utils2 = c.utility(basket.merge(apple: 6))

        # additional utility from 6th apple
        apple_diff = utils2[:apple] - utils[:apple]
        expect(apple_diff).must_be :>, 0

        # avg utility from 5 apples > additional utility from 6th apple
        expect(utils[:apple] / 5.0).must_be :>, apple_diff
      end
    end

    describe "Increasing Complementary Utility" do
      it "mandates increasing utility as other good amounts increase" do
        c = City.new
        basket = { apple: 5, bread: 7 }
        utils = c.utility(basket)
        utils2 = c.utility(basket.merge(apple: 6))

        bread_diff = utils2[:bread] - utils[:bread]
        expect(bread_diff).must_be :>, 0

        # total utility from 7 bread goes up as apples go up
        expect(utils[:bread]).must_be :<, utils2[:bread]
      end
    end

    # City.labor_check!
    it "may raise when production is attempted without enough labor" do
      expect { City.labor_check!(100, 10) }.must_raise City::LaborShortfall
      expect(City.labor_check!(10, 100)).must_equal 10
    end

    # City#to_s
    it "has a string representation" do
      s = City.new.to_s
      expect(s).must_be_kind_of String
      expect(s).wont_be_empty
    end

    # City#propose
    it "determines the expected labor and utility for a basket of goods" do
      c = City.new
      basket = { egg: 3, fish: 7 }
      stats = c.propose(basket)

      expect(stats[:labor]).must_be_kind_of Hash
      expect(stats[:total_labor]).must_be_kind_of Integer
      expect(stats[:utility]).must_be_kind_of Hash
      expect(stats[:total_utility]).must_be_kind_of Numeric
      expect(stats[:leisure]).must_be_kind_of Integer
    end

    # City#allocate
    it "determines the expected goods basket for the amount of labor" do
      c = City.new
      labor = { apple: 25, bread: 20 }
      basket = c.allocate(labor)

      expect(basket[:apple]).must_be_kind_of Integer
      expect(basket[:bread]).must_be_kind_of Integer
      expect(basket[:leisure]).must_be_kind_of Integer
    end

    # City#advisor
    describe "City advisor" do
      it "ranks goods in order of utils per labor" do
        c = City.new
        adv = c.advisor

        expect(adv.keys.all? { |s| s.kind_of? Symbol }).must_equal true
        expect(adv.values.all? { |n| n.kind_of? Numeric }).must_equal true

        last_value = adv.first[1]
        adv.each { |good, value|
          expect(value).must_be :<=, last_value
          last_value = value
        }
      end

      it "can also rank on e.g. utils per labor^2" do
        c = City.new
        adv = c.advisor
        adv2 = c.advisor(2)

        expect(adv.keys).wont_equal adv2.keys
        expect(adv.keys.sort).must_equal adv.keys.sort
      end
    end
  end
end
