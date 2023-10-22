print "\tCreating Org... "
start_time = Time.now

creator = User.find($simulation.founder.id)

random_local_number = rand 1000..9999
random_store_number = rand 100..999

def random_company_name
  companies_string = "Walmart,Amazon.com,Costco Wholesale,The Home Depot,The Kroger Co.,Walgreens Boots Alliance,Target,CVS Health Corporation,Lowe's Companies,Albertsons Companies,Apple Stores / iTunes,Royal Ahold Delhaize USA,Publix Super Markets,Best Buy,TJX Companies,Aldi,Dollar General,H.E. Butt Grocery,Dollar Tree,Ace Hardware,Macy's,7-Eleven,AT&T Wireless,Meijer,Verizon Wireless,Ross Stores,Kohl's,Wakefern / ShopRite,Rite Aid,BJ's Wholesale Club,Dell Technologies,Gap,Nordstrom,Menards,O’Reilly Auto Parts,Tractor Supply Co.,AutoZone,Dick's Sporting Goods,Hy Vee,Wayfair,Health Mart Systems,Wegmans Food Market,Qurate Retail,Giant Eagle,Alimentation Couche-Tard,Sherwin-Williams,Burlington,J.C. Penney Company,WinCo Foods,Chewy.com,Good Neighbor Pharmacy,Ulta Beauty,Williams-Sonoma,Army and Air Force Exchange Service,PetSmart,Bass Pro,Bath & Body Works,Southeastern Grocers,AVB Brandsource,Academy Sports,Staples,Dillard's,Hobby Lobby Stores,Bed Bath & Beyond,Big Lots,Signet Jewelers,Foot Locker,Sprouts Farmers Market,Sephora (LVMH),Ikea North America Services,Discount Tire,Camping World,Petco,True Value Co.,Office Depot,Victoria's Secret,Michaels Stores,Piggly Wiggly,Stater Bros Holdings,My Demoulas,Advance Auto,Harbor Freight Tools,Exxon Mobil Corporation,Hudson's Bay,Save-A-Lot,American Eagle Outfitters,Total Wine & More,Defense Commissary Agency,Ingles,Weis Markets,Casey's General Store,Tapestry,Smart & Final,Lululemon,Shell Oil Company,Golub,Save Mart,RH,Urban Outfitters,Barnes & Noble"
  companies_string.split(',').sample
end

potential_member_definition =
  "An employee of #{random_company_name} at store ##{random_store_number}"

Timecop.freeze($simulation.started_at) do
  creator.create_org! name: "Local #{random_local_number}",
    potential_member_definition: potential_member_definition

  creator.save!
end

puts "Completed in #{(Time.now - start_time).round 3} s"
