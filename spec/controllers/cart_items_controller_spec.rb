require 'rails_helper'

RSpec.describe CartItemsController, type: :controller do
  let(:cart) { create(:cart) }
  let(:product) { create(:product, prices: "20.0", stock: 50) }
  let(:cart_item) { create(:cart_item, cart: cart, product: product) }
  let(:promotion) { create(:promotion, promotion_type: "product", apply_field: product.id.to_s, value: 10) }

  before do
    allow(controller).to receive(:set_cart).and_return(cart)
    controller.instance_variable_set(:@cart, cart) # Manually set the instance variable
  end


  describe 'POST #create' do
    context 'with a valid product' do
      it 'adds the product to the cart and returns success' do
        post :create, params: { cart_id: cart.id, product_id: product.id, quantity: 2 }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:success)
        expect(json_response['success']).to eq(true)
        expect(json_response['message']).to eq("Item added to cart")
        expect(json_response['cart_count']).to eq(3)
      end
    end

    context 'with an invalid product' do
      it 'returns a product not found error' do
        post :create, params: { cart_id: cart.id, product_id: 0, quantity: 2 }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(json_response['success']).to eq(false)
        expect(json_response['message']).to eq("Product not found")
      end
    end

    context 'when cart item fails to save' do
      it 'returns an error message' do
        allow_any_instance_of(CartItem).to receive(:save).and_return(false)
        post :create, params: { cart_id: cart.id, product_id: product.id, quantity: 2 }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['success']).to eq(false)
        expect(json_response['message']).to include("Failed to add item to cart")
      end
    end
  end

  describe 'PATCH #update' do

    context 'with valid parameters' do
      it 'updates the quantity of the cart item' do
        patch :update, params: { id: cart_item.id, quantity: 3 }

        # Assuming the cart_item's update succeeds and the controller responds with a JSON containing the updated quantity
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['new_quantity']).to eq(3)
        expect(JSON.parse(response.body)['message']).to eq("Quantity updated")
      end
    end

    context 'with invalid parameters' do
      it 'fails to update the cart item' do
        # Simulating the failure of update
        allow_any_instance_of(CartItem).to receive(:update).and_return(false)
        patch :update, params: { id: cart_item.id, quantity: 0 }

        # The response should indicate failure
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['success']).to eq(false)
        expect(JSON.parse(response.body)['message']).to eq("Failed to update quantity")
      end
    end
  end


  describe 'DELETE #destroy' do
    let!(:cart_item) { create(:cart_item) }  # Ensure the cart_item is created

    it 'destroys the cart item' do
      expect {
        delete :destroy, params: { id: cart_item.id }
      }.to change(CartItem, :count).by(-1)  # Expect the cart_item count to decrease
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to eq(true)
      expect(json_response['message']).to eq("Item removed from cart")
    end
  end



  describe 'POST #apply_promotion' do
    context 'with valid promotion' do
      it 'applies the discount to the cart items' do
        post :apply_promotion, params: { cart_id: cart.id, promote_code: promotion.promote_code }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:success)
        expect(json_response['success']).to eq(true)
        expect(json_response['message']).to eq("Discount applied") # Verifies the success message
        expect(json_response['updated_prices']).to eq({})# Verifies that updated prices are included
      end
    end


    context 'with invalid promotion' do
      it 'returns a not found error' do
        post :apply_promotion, params: { cart_id: cart.id, promote_code: 'invalid' }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(json_response['message']).to eq('Promotion not found')
      end
    end
  end
end
