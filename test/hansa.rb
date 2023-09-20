require 'minitest/autorun'
require 'hansa'

include Hansa

describe Hansa do
  describe "CONSUMPTION and LABOR" do
    it "maps goods to utils" do
      expect(CONSUMPTION[:apple]).must_be_kind_of Numeric
      expect(LABOR[:apple]).must_be_kind_of Numeric
    end

    it "has identical keys (goods)" do
      expect(CONSUMPTION.keys.sort).must_equal LABOR.keys.sort
    end
  end

  it "generates a basket of goods" do
    b = Hansa.basket(0)
    expect(b.keys.sort).must_equal LABOR.keys.sort
    expect(b.values.all? { |count| count == 0 }).must_equal true

    b = Hansa.basket(100)
    expect(b.values.all? { |count| count == 100 }).must_equal true
  end
end
