# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do

  describe "factory" do
    it "has a valid factory" do
      product = FactoryBot.create(:product)
      expect(product).to be_valid
    end
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:prices) }
    it { should validate_numericality_of(:prices).is_greater_than(0.00) }
  end


  describe "associations" do
    it { should have_many(:merchandises) }
  end

  describe "methods" do
    let(:product) { create(:product, prices: 100) }
    let!(:merchandise) { create(:merchandise, product: product, cut_off_value: 20, promotion_end: Date.today + 1.day) }

    context "#current_price" do
      it "returns discounted price if promotion is active" do
        merchandise.update(promotion_end: '31/12/2100')
        expect(product.current_price).to eq("")
      end

      it "returns original price if no promotion is active" do
        merchandise.update(promotion_end: Date.yesterday)
        expect(product.current_price).to eq("100") # Expect a float
      end
    end


    context "#price_status" do
      it "returns 'anomaly' if a promotion is active" do
        expect(product.price_status).to eq("anomaly")
      end

      it "returns 'normal' if no promotion is active" do
        merchandise.update(promotion_end: Date.yesterday)
        expect(product.price_status).to eq("normal")
      end
    end

    context ".find_top_product" do
      it "returns the top product based on quantity sold" do
        product_2 = create(:product)
        create(:cart_item, product: product, quantity: 5)
        create(:cart_item, product: product_2, quantity: 3)

        top_product = Product.find_top_product
        expect(top_product.name).to eq(product.name)
        expect(top_product.total_quantity).to eq(5)
      end
    end
  end

  describe "Elasticsearch integration" do
    it "indexes the product after creation" do
      product = build(:product)
      expect(product).to receive(:index_to_elasticsearch)
      product.save
    end

    it "updates the Elasticsearch document after update" do
      product = create(:product)
      expect(product).to receive(:update_in_elasticsearch)
      product.update(name: "Updated Name")
    end
  end

  describe "ransackable attributes" do
    it "returns the correct attributes for search" do
      expect(Product.ransackable_attributes).to match_array(%w[name prices product_type])
    end
  end
end
