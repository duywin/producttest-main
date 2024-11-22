require "rails_helper"

RSpec.describe MerchandisesController, type: :controller do
  # Setup test data
  let(:product) { create(:product) } # Assuming product factory exists
  let(:valid_attributes) do
    {
      product_id: product.id,
      cut_off_value: Faker::Commerce.price(range: 10.0..1000.0),
      promotion_end: Faker::Date.forward(days: 30),
      promotion_start: Faker::Date.forward(days: 30)
    }
  end
  let(:invalid_attributes) do
    {
      product_id: nil,  # Invalid because product_id cannot be nil
      cut_off_value: nil,
      promotion_end: nil,
      promotion_start: nil
    }
  end


  # Test create action
  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Merchandise" do
        expect {
          post :create, params: { merchandise: valid_attributes }
        }.to change(Merchandise, :count).by(1)
      end

      it "redirects to the products path with a success notice" do
        post :create, params: { merchandise: valid_attributes }
        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq('Merchandise created successfully!')
      end
    end

    context "with invalid parameters" do
      it "does not create a new Merchandise" do
        expect {
          post :create, params: { merchandise: invalid_attributes }
        }.to change(Merchandise, :count).by(0)
      end

      it "redirects to the new promotion path with an error notice" do
        post :create, params: { merchandise: invalid_attributes }
        expect(response).to redirect_to(new_promotion_path)
        expect(flash[:notice]).to eq('Unable to create merchandise, please check the input')
      end
    end
  end

  # Test destroy action
  describe "DELETE #destroy" do
    let!(:merchandise) { create(:merchandise) }

    it "destroys the requested merchandise" do
      expect {
        delete :destroy, params: { id: merchandise.id }
      }.to change(Merchandise, :count).by(-1)
    end

    it "redirects to the products path with a success notice" do
      delete :destroy, params: { id: merchandise.id }
      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to eq('Merchandise deleted successfully!')
    end
  end
end

