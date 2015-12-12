class Generator
  begin
    require 'factory_girl_rails'
    include FactoryGirl::Syntax::Methods
  rescue LoadError => e
    # This will fail in production. That's okay.
  end

  USERS_PER_COUNTRY  = 2..4
  ORDERS_PER_USER    = 1..5
  SUPPLIES_PER_ORDER = 1..4

  def initialize *countries
    @countries = countries.map { |name| Country.find_by_name name }
  end

  def clear_existing!
    users.each &:destroy!
  end

  def create_users!
    @countries.each do |c|
      USERS_PER_COUNTRY.to_a.sample.times do
        create :user, country: c
      end
    end
  end

  def create_orders!
    users.each do |user|
      ORDERS_PER_USER.to_a.sample.times do
        created_at   = (1..40).to_a.sample.days.ago
        request      = create :request, created_at: created_at
        supply_count = SUPPLIES_PER_ORDER.to_a.sample
        supplies.sample(supply_count).each do |supply|
          create :order,
            user:       user,
            request:    request,
            supply:     supply,
            created_at: created_at
        end
        user.mark_updated_orders
      end
      user.update_waiting!
    end
  end

  def supplies
    @_supplies ||= Supply.all
  end

  def users
    User.where(country: @countries).select { |u| u.email =~ /example.com/ }
  end

  def orders
    Order.where user: users
  end
end

desc "Generates random order data"
task :generate => :environment do
  g = Generator.new "Georgia", "Senegal"
  g.clear_existing!
  g.create_users!
  g.create_orders!

  puts "Done ... created #{g.orders.count} orders"
end
