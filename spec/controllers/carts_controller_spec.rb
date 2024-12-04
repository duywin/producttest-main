require 'rails_helper'

RSpec.describe CartsController, type: :controller do
  let(:cart) { create(:cart) }
  let(:cart_item) { create(:cart_item, cart_id: cart) }
  let(:promotion) { create(:promotion, promotion_type: "cart", value: 10, promote_code: "PROMO10") }

  before do
    allow(controller).to receive(:set_cart).and_return(cart)
  end

  describe 'GET #index' do
    it 'fetches weeks with checkouts' do
      allow(Cart).to receive(:fetch_weeks_with_checkouts).and_return(["Week 1", "Week 2"])
      get :index
      expect(assigns(:weeks)).to eq(["Week 1", "Week 2"])
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #render_cart_datatable' do
    it 'renders filtered cart datatable results' do
      allow(Cart).to receive(:search_carts).and_return([cart])
      allow(cart).to receive(:formatted_data).and_return({ id: cart.id, total_price: cart.total_price })

      get :render_cart_datatable, params: { week: "1", day: "Monday", sort_order: "desc", status: "checked_out" }
      json_response = JSON.parse(response.body)
      expect(json_response["data"].first["id"]).to eq(cart.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      it 'updates the cart and redirects' do
        patch :update, params: { id: cart.id, cart: { username: "UpdatedUser" } }
        expect(cart.reload.username).to eq("UpdatedUser")
        expect(response).to redirect_to(carts_path)
      end
    end

    context 'with invalid params' do
      it 're-renders the edit form with errors' do
        allow_any_instance_of(Cart).to receive(:update).and_return(false)
        patch :update, params: { id: cart.id, cart: { username: "" } }
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #show' do
    let!(:cart) { create(:cart) }
    let!(:cart_item) { create(:cart_item, cart: cart) }

    it 'fetches cart items for the given cart' do
      get :show, params: { id: cart.id }
      expect(assigns(:cart_items)).to include(cart_item)
      expect(response).to render_template(:show)
    end
  end

  describe 'POST #update_item' do
    it 'updates the cart item quantity successfully' do
      post :update_item, params: { id: cart_item.id, quantity: 5 }
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to eq(true)
      expect(json_response["new_quantity"]).to eq(5)
    end

    it 'fails to update the cart item quantity with invalid data' do
      allow_any_instance_of(CartItem).to receive(:update).and_return(false)
      post :update_item, params: { id: cart_item.id, quantity: -1 }
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to eq(false)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #checkout' do
    context 'with items in the cart' do
      before { allow(cart).to receive(:cart_items).and_return([cart_item]) }

      it 'completes the checkout and reduces stock' do
        expect { post :checkout, params: { id: cart.id } }
          .to change { cart_item.product.reload.stock }.by(-cart_item.quantity)
        expect(response).to redirect_to(delivery_form_path)
      end
    end

    context 'with an empty cart' do
      it 'returns an error' do
        allow(cart).to receive(:cart_items).and_return([])
        post :checkout, params: { id: cart.id }
        expect(response).to redirect_to(carts_path)
        expect(flash[:alert]).to eq("Cannot checkout an empty cart.")
      end
    end
  end

  describe 'POST #apply_cart_promotion' do
    context 'with a valid promotion' do
      it 'applies the promotion and updates the cart total' do
        allow(controller).to receive(:apply_cart_discount).and_return(90.0)
        post :apply_cart_promotion, params: { cart_id: cart.id, promote_code: promotion.promote_code }
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to eq(true)
        expect(json_response["new_total"]).to eq(90.0)
      end
    end

    context 'with an invalid promotion' do
      it 'returns an error' do
        post :apply_cart_promotion, params: { cart_id: cart.id, promote_code: "INVALID" }
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to eq(false)
        expect(json_response["message"]).to eq("Promotion not found")
      end
    end
  end
end
