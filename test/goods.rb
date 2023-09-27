require 'minitest/autorun'
require 'hansa/goods'

include Hansa

LABOR_KEYS = Set.new(Goods::LABOR.keys)

describe Goods do
  describe "Goods.basket" do
    it "generates a basket of goods, each with N units" do
      b = Goods.basket
      expect(Set.new(b.keys)).must_equal LABOR_KEYS
      expect(b.values.all? { |count| count == 0 }).must_equal true

      b = Goods.basket(0)
      expect(Set.new(b.keys)).must_equal LABOR_KEYS
      expect(b.values.all? { |count| count == 0 }).must_equal true

      b = Goods.basket(100)
      expect(Set.new(b.keys)).must_equal LABOR_KEYS
      expect(b.values.all? { |count| count == 100 }).must_equal true
    end
  end

  describe "CONSUMPTION" do
    it "defines the utility created by consuming a good" do
      expect(Goods::CONSUMPTION[:apple]).must_be_kind_of Numeric
      expect(Goods::CONSUMPTION[:apple]).must_be :>, 0
    end

    it "has the same set of keys (goods) as LABOR" do
      expect(Set.new(Goods::CONSUMPTION.keys)).must_equal LABOR_KEYS
    end
  end

  describe "LABOR" do
    it "defines the labor expended by producing a good" do
      expect(Goods::LABOR[:apple]).must_be_kind_of Numeric
      expect(Goods::LABOR[:apple]).must_be :>, 0
    end
  end
end
