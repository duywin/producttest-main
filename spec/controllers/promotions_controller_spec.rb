require 'rails_helper'

RSpec.describe PromotionsController, type: :controller do
  let(:account) { create(:account) } # Assuming you have user authentication
  let(:promotion) { create(:promotion) }
  let(:product) { create(:product) }

  before do
    allow(controller).to receive(:session).and_return({ current_account_id: account.id })
  end

  describe "GET #new" do
    before { get :new }

    it "assigns a new Promotion to @promotion" do
      expect(controller.instance_variable_get(:@promotion)).to be_a_new(Promotion)
    end

    it "assigns a new Merchandise to @merchandise" do
      expect(controller.instance_variable_get(:@merchandise)).to be_a_new(Merchandise)
    end

    it "responds with a 200 status" do
      expect(response).to have_http_status(:ok)
    end
  end


  describe "POST #create" do
    context "with valid parameters" do
      let(:valid_attributes) do
        attributes_for(:promotion).merge(apply_field: product.id)
      end

      it "creates a new promotion and logs the action" do
        expect {
          post :create, params: { promotion: valid_attributes }
        }.to change(Promotion, :count).by(1)

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Promotion created successfully!")
      end
    end

    # context "with invalid parameters" do
    #   let(:invalid_attributes) { attributes_for(:promotion, promote_code: nil) }
    #
    #   it "redirects to the new promotion path with an error notice" do
    #     post :create, params: { promotion: invalid_attributes }
    #     expect(response).to redirect_to(new_promotion_path)
    #     expect(flash[:notice]).to eq('Unable to create promotion, please check the input')
    #   end
    # end
  end

  describe "DELETE #destroy" do
    let!(:promotion_to_delete) { create(:promotion) }

    it "destroys the promotion and associated promote products" do
      create(:promote_product, promotion: promotion_to_delete)

      expect {
        delete :destroy, params: { id: promotion_to_delete.id }
      }.to change(Promotion, :count).by(-1)
                                    .and change(PromoteProduct, :count).by(-1)

      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to eq("Promotion deleted successfully!")
    end
  end

  describe "GET #check_type" do
    context "with a valid promotion code" do
      it "returns the promotion type in JSON format" do
        get :check_type, params: { promote_code: promotion.promote_code }
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be_truthy
        expect(json_response["promotion_type"]).to eq(promotion.promotion_type)
      end
    end

    context "with an invalid promotion code" do
      it "returns an error in JSON format" do
        get :check_type, params: { promote_code: "INVALID" }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be_falsey
        expect(json_response["message"]).to eq("Invalid promotion code")
      end
    end
  end
end
