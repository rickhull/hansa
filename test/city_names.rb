require 'minitest/autorun'
require 'hansa/city_names'

include Hansa

describe "Hansa.city_name" do
  it "accepts (locale: scope: sym: exclude:) and returns a string" do
    expect(Hansa.city_name(locale: :inland)).must_be_kind_of String
    expect(Hansa.city_name(locale: :inland, scope: :global)).wont_be_empty
    expect(Hansa.city_name(locale: :inland,
                           scope: :usa,
                           sym: :a)[0]).must_equal 'A'
    expect(Hansa.city_name(locale: :inland,
                           scope: :global,
                           sym: :i,
                           exclude: ['Isfahan'])).wont_equal 'Isfahan'
  end

  it "accepts locales (:mountain, :inland, :coastal, :delta, :island)" do
  end

  it "accepts scopes (:global, :usa)" do
  end

  it "accepts single-letter downcase ascii symbols" do
  end

  it "accepts an exclusion list" do
  end
end

describe "INLAND_NAMES" do
  it "is mutually exclusive with COASTAL_NAMES" do
    [Global, USA].each { |m|
      m::INLAND_NAMES.each { |sym, ary|
        expect(ary & USA::COASTAL_NAMES.fetch(sym)).must_be_empty
      }
    }
  end
end

describe "COASTAL_NAMES" do
  it "is mutually exclusive with INLAND_NAMES" do
    [Global, USA].each { |m|
      m::COASTAL_NAMES.each { |sym, ary|
        expect(ary & USA::INLAND_NAMES.fetch(sym)).must_be_empty
      }
    }
  end
end

describe "DELTA_NAMES" do
  it "should be in either INLAND_NAMES or COASTAL_NAMES" do
    [Global, USA].each { |m|
      m::DELTA_NAMES.each { |sym, ary|
        land = m::INLAND_NAMES.fetch(sym)
        coast = m::COASTAL_NAMES.fetch(sym)
        ary.each { |delta_city|
          # puts "city: #{delta_city}"
          on_land = land.include?(delta_city)
          on_coast = coast.include?(delta_city)
          expect(on_land || on_coast).must_equal true
          expect(on_land && on_coast).wont_equal true
        }
      }
    }
  end
end

describe "MOUNTAIN_NAMES" do
  it "may overlap with INLAND_NAMES" do
    { USA => 'El Paso',
      Global => 'La Paz' }.each { |m, name|
      sym = name[0].downcase.to_sym
      expect(m::MOUNTAIN_NAMES.fetch(sym).include?(name)).must_equal true
      expect(m::INLAND_NAMES.fetch(sym).include?(name)).must_equal true
    }
  end
end

describe "ISLAND_NAMES" do
  it "may overlap with COASTAL_NAMES" do
    { Global => 'Kingston' }.each { |m, name|
      sym = name[0].downcase.to_sym
      expect(m::ISLAND_NAMES.fetch(sym).include?(name)).must_equal true
      expect(m::COASTAL_NAMES.fetch(sym).include?(name)).must_equal true
    }
  end
end
