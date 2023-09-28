[About Hansa](http://www.daviddfriedman.com/Living_Paper/Hansa/hansa_instructions/hansa_instructions.htm)

A _League_ is made up of _Cities_

City:
  - population
  - production function
  - utility function

Production function: `production(labor) #=> goods`
  - L labor units produce 1 good unit
  - N good units require L * N labor units
  - labor cost varies between goods and cities
  - labor cost is partly but not entirely determined by surrounding terrain

Utility function: `util(goods_consumed) # => utils`
  - total happiness of inhabitants; depends on goods consumed
  - **The additional utility from consuming one more unit of a good decreases
    as the amount of that good consumed increases and increases as the amount
    of any other good increases**
  - identical across cities
  - autarchy level: highest utility achieved *without trade*

Trade:
  - transportation requires labor, provided by the exporting city
  - transportation costs vary between cities (distance, water / land)
  - transportation is instant (every turn represents 1 year)
  - trade agreement?  payment?  matching coincidence of needs?

Gameplay:
  - Production / Consumption / Trade
  - Allocate labor towards production of specific goods
  - Allocate production towards consumption or trade (export)
  - No storage, so Consumption is: Production + Imports - Exports

### Additionally

Worldmap:
  - (x,y) coordinates with (0,0) SW corner and (1,1) NE corner
  - consider: (x,y) coordinates with (-1,-1) SW corner and (1,1) NE corner
  - East coast and West coast (defined by x-axis)
  - The outermost coastal areas are islands: East Isles and West Isles
  - Inland from coastal areas are delta areas, not accessible by sea
  - East coast cities have water routes between them
  - West coast cities have water routes between them
  - No East-West water route
  - One river runs inland from high to low, providing an inland water route
  - One possible river-coast city (delta or coastal)
  - If river empties into **delta**,
      that city **becomes available by sea** (and river)
  - If river empties into coastal,
      still available by sea (and river)
  - Water routes require less transportation labor than land routes
  - Altitude affects river and land routes (downhill is cheaper)
