require "rails_helper"

RSpec.describe AdminhomesController, type: :controller do
  let(:account) {
    FakeAccount.create!(
      id: 8,
      email: "ad@example.com",
      username: "admin1",
      phonenumber: "0988694913",
      address: "6/9 nguyen canh di-",
      password: "Admin@12",
      gender: "male",
      is_admin: 1
    )
  }
  let!(:category) { Category.create!(id: 9, name: "Tea", total: 9) }

  describe "before_action :authenticate_admin" do
    it "redirects unauthenticated users to no index" do
      session[:current_account_id] = nil
      get :index
      expect(response).to redirect_to(noindex_path)
    end
  end

  describe "GET #adminlogout" do
    context "when admin is authenticated" do
      before do
        session[:current_account_id] = account.id
      end

      it "logs out the admin and redirects to login page" do
        get :adminlogout
        expect(session[:current_account_id]).to be_nil
        expect(response).to redirect_to(new_account_session_path)
      end
    end
  end

  describe "GET #index" do
    context "when admin is not authenticated" do
      it "redirects to login page" do
        get :index
        expect(response).to redirect_to(noindex_path)
      end
    end

    context "when admin is authenticated" do
      before do
        session[:current_account_id] = account.id
      end

      it "renders the index template successfully" do
        get :index
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end

      it "assigns @account based on session" do
        get :index
        expect(assigns(:account)).to eq(account)
      end

      it "assigns @category_totals as a hash of category names and totals" do
        get :index
        expect(assigns(:category_totals)).to eq({"Tea" => 9})
      end

      it "assigns @highest_category based on the highest total" do
        get :index
        expect(assigns(:highest_category)).to eq(["Tea", 9])
      end

      # Create a product for testing the top product logic
      let!(:product) do
        Product.create!(
          id: 44,
          name: "Keychain Souvenir",
          product_type: "Bottle water",
          prices: "5.00",
          desc: "No description available.",
          stock: 400,
          picture: "https://m.media-amazon.com/images/I/518n3UiBDVL._AC_UY580_.jpg"
        )
      end

      let!(:cart_item) { CartItem.create!(product: product, quantity: 10) }

      it "assigns @top_product based on the product with the highest quantity in the cart" do
        get :index
        expect(assigns(:top_product).name).to eq("Keychain Souvenir")
        expect(assigns(:top_product).total_quantity).to eq(10)
      end

      it "assigns @category_totals_js in JSON format" do
        get :index
        expect(assigns(:category_totals_js)).to eq([["Tea", 9]].to_json)
      end
    end
  end
end
