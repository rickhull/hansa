require 'minitest/autorun'
require 'hansa/city_names'

include Hansa

describe "NAMES" do
  it "is mutually exclusive with COASTAL_NAMES" do
    City::NAMES.each { |sym, ary|
      expect(ary & City::COASTAL_NAMES.fetch(sym)).must_be_empty
    }
  end
end

describe "COASTAL_NAMES" do
  it "is mutually exclusive with NAMES" do
    City::COASTAL_NAMES.each { |sym, ary|
      expect(ary & City::NAMES.fetch(sym)).must_be_empty
    }
  end
end

describe "DELTA_NAMES" do
  it "should be in either NAMES or COASTAL_NAMES" do
    City::DELTA_NAMES.each { |sym, ary|
      land = City::NAMES.fetch(sym)
      coast = City::COASTAL_NAMES.fetch(sym)
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
