require 'hansa/city'
require 'pp'
require 'set'
require 'slop'

opts = Slop.parse { |o|
  o.string '-n', '--name', 'city name', default: 'Hansa'
  o.integer '-p', '--pop', 'population', default: 5000
  o.symbol '-t', '--type', 'e.g. farming', default: nil
}

c = Hansa::City.new(**opts.to_hash)
puts c
puts "TERRAIN: (labor cost)"
pp c.terrain
puts

puts "ADVISOR:"
goods = c.advisor
pp goods
puts

basket = Hansa.basket(0) # 0 of every possible good
i = 0
checkmod = [1, opts[:pop] / 100].max  # for periodic output


loop {
  best = -9**9
  best_good = nil
  count = 0
  last_stats = c.propose(basket)

  goods.each { |good, _|
    next if last_stats[:total_labor] + c.terrain[good] > opts[:pop]
    stats = c.propose basket.merge(good => basket[good] + 1)
    du = stats[:total_utility] - last_stats[:total_utility]
    dl = stats[:total_labor] - last_stats[:total_labor]
    upl = du / dl.to_f
    if upl > best
      best_good = good
      best = upl
    end
    count += 1
  }

  break unless best_good

  basket[best_good] += 1
  # puts format("%s: %i", best_good, basket[best_good])
  i += 1

  if i % checkmod == 0
    stats = c.propose(basket)
    u = stats[:total_utility]
    l = stats[:total_labor]

    puts format("%i utility (%i / %i labor): %.2f u/l",
                u, l, opts[:pop], u/l.to_f)
  end
}

puts
puts "GOODS PRODUCED:"
pp basket.sort_by { |k, v| -v }
puts

stats = c.propose(basket)

puts "LABOR USED:"
pp stats[:labor].sort_by { |k, v| -v }
puts

puts "UTILITY GAINED:"
pp stats[:utility].sort_by { |k, v| -v }
puts

hsh = {}
stats[:utility].each { |good, utils|
  labor = stats[:labor][good].to_f
  hsh[good] = utils / stats[:labor][good].to_f unless labor == 0.0
}

puts "UTILITY PER LABOR:"
pp hsh.sort_by { |k, v| -v }
puts

u = stats[:total_utility]
l = stats[:total_labor]
puts format("%i utility (%i / %i labor): %.2f u/l",
            u, l, opts[:pop], u/l.to_f)


# zlib openssl libyaml gmp

# TMPDIR=~/tmp asdf install ruby 3.2.2
