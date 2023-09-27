require 'minitest/autorun'
require 'hansa/city_names'

include Hansa

describe "NAMES" do
  it "is mutually exclusive with COASTAL_NAMES" do
    USA::NAMES.each { |sym, ary|
      expect(ary & USA::COASTAL_NAMES.fetch(sym)).must_be_empty
    }
  end
end

describe "COASTAL_NAMES" do
  it "is mutually exclusive with NAMES" do
    USA::COASTAL_NAMES.each { |sym, ary|
      expect(ary & USA::NAMES.fetch(sym)).must_be_empty
    }
  end
end

describe "DELTA_NAMES" do
  it "should be in either NAMES or COASTAL_NAMES" do
    USA::DELTA_NAMES.each { |sym, ary|
      land = USA::NAMES.fetch(sym)
      coast = USA::COASTAL_NAMES.fetch(sym)
      ary.each { |delta_city|
        # puts "city: #{delta_city}"
        on_land = land.include?(delta_city)
        on_coast = coast.include?(delta_city)
        expect(on_land || on_coast).must_equal true
        expect(on_land && on_coast).wont_equal true
      }
    }
  end
end

describe "MOUNTAIN_NAMES" do
  it "may overlap with NAMES" do
    ['El Paso'].each { |name|
      sym = name[0].downcase.to_sym
      expect(USA::MOUNTAIN_NAMES[sym].include?(name)).must_equal true
      expect(USA::NAMES[sym].include?(name)).must_equal true
    }
  end
end

describe "ISLAND_NAMES" do
  it "may overlap with COASTAL_NAMES" do
    ['Kingston'].each { |name|
      sym = name[0].downcase.to_sym
      expect(USA::ISLAND_NAMES[sym].include?(name)).must_equal true
      expect(USA::COASTAL_NAMES[sym].include?(name)).must_equal true
    }
  end
end
