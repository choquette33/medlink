require 'spec_helper'

describe Response do
  before :each do
    @user = create :user
    @response = create :response, user: @user
    3.times do
      create :order,
        user:            @user,
        response:        @response,
        delivery_method: DeliveryMethod::Pickup
    end
  end

  pending "Email response contents"

  it "can de-serialize responded orders" do
    expect( Order.last.delivery_method ).to respond_to :name
  end

  it "stores simple strings in the database" do
    raw = Order.connection.execute %{
      SELECT delivery_method
      FROM orders
      ORDER BY id DESC
      LIMIT 1
    }.squish
    expect( raw.first["delivery_method"] ).to eq "pickup"
  end

  describe "messaging" do
    it "all pickup" do
      expect( @response.sms_instructions ).to match /approved for pickup/i
    end

    it "some failures" do
      @response.orders.first.update_attributes delivery_method: DeliveryMethod::Denial
      expect( @response.sms_instructions ).to match /unable to fill.*entire order/i
    end

    it "mixed approval" do
      @response.orders.first.update_attributes delivery_method: DeliveryMethod::Delivery
      expect( @response.sms_instructions ).to match /approved.*check email/i
    end
  end
end
