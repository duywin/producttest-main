# spec/models/cart_spec.rb
require 'rails_helper'

RSpec.describe Cart, type: :model do
  # Associations
  it { should belong_to(:account) }
  it { should have_many(:cart_items).dependent(:destroy) }
  it { should have_many(:products).through(:cart_items) }

  # Validations
  # Add any validations if applicable

  # Elasticsearch Integration
  describe 'Elasticsearch Integration' do
    let(:cart) { build(:cart) } # Use `build` to avoid persisting the cart initially

    it 'indexes the cart to Elasticsearch after creation when function_check_out is true' do
      allow(cart.__elasticsearch__).to receive(:index_document)
      cart.function_check_out = true
      expect(cart.__elasticsearch__).to receive(:index_document)
      cart.save
    end

    it 'does not index the cart to Elasticsearch when function_check_out is false' do
      cart.function_check_out = false
      expect(cart.__elasticsearch__).not_to receive(:index_document)
    end

    it 'updates the cart in Elasticsearch after an update' do
      cart.update(admin_update: true)
      expect(cart).to receive(:update_in_elasticsearch)
      cart.save
    end
  end

  describe '.apply_filters' do
    let(:current_time) { Time.zone.now }
    let(:cart1) { create(:cart, created_at: current_time.beginning_of_week + 1.day) } # Monday
    let(:cart2) { create(:cart, created_at: current_time.beginning_of_week + 3.days) } # Wednesday

    it 'filters carts by week' do
      week_start = current_time.beginning_of_week
      week_param = week_start.strftime('%d %b %Y')

      filtered_carts = Cart.apply_filters(Cart.all, week_param, nil)

      expect(filtered_carts).to include(cart1, cart2) # Both carts in the same week
    end

    it 'filters carts by day within the week' do
      week_start = current_time.beginning_of_week
      week_param = week_start.strftime('%d %b %Y')
      day_param = 'Monday'

      filtered_carts = Cart.apply_filters(Cart.all, week_param, day_param)

      expect(filtered_carts).to include(cart1) # Only cart1 is on Monday
      expect(filtered_carts).not_to include(cart2)
    end

    it 'returns all carts if no filters are applied' do
      filtered_carts = Cart.apply_filters(Cart.all, nil, nil)

      expect(filtered_carts).to include(cart1, cart2)
    end

    it 'filters carts correctly with both week and day' do
      week_start = current_time.beginning_of_week
      week_param = week_start.strftime('%d %b %Y')
      day_param = 'Wednesday'

      filtered_carts = Cart.apply_filters(Cart.all, week_param, day_param)

      expect(filtered_carts).to include(cart2) # Only cart2 is on Wednesday
      expect(filtered_carts).not_to include(cart1)
    end
  end


  describe '.fetch_weeks_with_checkouts' do
    it 'returns unique weeks with checkouts' do
      cart1 = create(:cart, created_at: 2.days.ago, check_out: true)
      cart2 = create(:cart, created_at: 1.day.ago, check_out: true)
      weeks = Cart.fetch_weeks_with_checkouts
      expect(weeks).to include(cart1.created_at.beginning_of_week)
      expect(weeks).to include(cart2.created_at.beginning_of_week)
    end
  end

  describe '.search_carts' do
    let(:current_time) { Time.zone.local(2024, 12, 2, 14, 0, 0) } # Monday, 2 Dec 2024
    let(:cart) { create(:cart, created_at: current_time, status: 'pending') }

    it 'returns carts filtered by week and day' do
      week_start = '02 Dec 2024' # Start of the week
      result = Cart.search_carts(week: week_start, day: 'Monday')

      expect(result).to include(cart) # Matches the correct day and week
    end

    it 'returns carts filtered by status' do
      cart1 = create(:cart, status: 'pending')
      cart2 = create(:cart, status: 'completed')
      result = Cart.search_carts(status: 'pending')
      expect(result.records).to include(cart1)
      expect(result.records).not_to include(cart2)
    end
  end


  # Instance Methods
  describe '#formatted_data' do
    let(:cart) { create(:cart, total_price: 100.0, status: 'pending', address: '123 Main St') }

    it 'returns formatted data with correct keys' do
      formatted_data = cart.formatted_data
      expect(formatted_data[:id]).to eq(cart.id)
      expect(formatted_data[:total]).to eq('$100.00')
      expect(formatted_data[:address]).to eq('123 Main St')
      expect(formatted_data[:status]).to eq('pending')
    end
  end

  describe '.monthly_sales_data' do
    it 'returns monthly sales data grouped by month' do
      create(:cart, deliver_day: 1.month.ago, quantity: 10)
      create(:cart, deliver_day: 1.month.ago, quantity: 5)
      result = Cart.monthly_sales_data
      expect(result).to include("#{1.month.ago.strftime('%B %Y')}" => 15)
    end
  end

  describe '.monthly_category_sales_data' do
    it 'returns monthly category sales data grouped by month and product type' do
      create(:cart_item, created_at: 1.month.ago, quantity: 10, product: create(:product, product_type: 'Electronics'))
      create(:cart_item, created_at: 1.month.ago, quantity: 5, product: create(:product, product_type: 'Clothing'))
      result = Cart.monthly_category_sales_data
      expect(result).to include("#{1.month.ago.strftime('%B %Y')}" => {'Electronics' => 10, 'Clothing' => 5})
    end
  end
end
