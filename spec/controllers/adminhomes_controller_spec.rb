# spec/controllers/adminhomes_controller_spec.rb
require 'rails_helper'

RSpec.describe AdminhomesController, type: :controller do
  let!(:admin) { create(:account, :admin) } # Admin user
  let!(:category) { create(:category) }
  let!(:cart) { create(:cart, account: admin) }
  let!(:cart_item) { create(:cart_item, cart: cart) }

  before do
    session[:current_account_id] = admin.id
    # Load common data required for most tests
    controller.send(:load_dashboard_data)
  end

  describe "GET #index" do
    it "assigns dashboard data and renders the index template" do
      get :index

      expect(controller.instance_variable_get(:@account)).to eq(admin)
      expect(controller.instance_variable_get(:@category_totals)).not_to be_nil
      expect(controller.instance_variable_get(:@highest_category)).not_to be_nil
      expect(controller.instance_variable_get(:@top_product)).not_to be_nil
      expect(controller.instance_variable_get(:@notifications)).not_to be_nil

      expect(response).to render_template(:index)
    end
  end

  describe "POST #adminlogout" do
    it "logs out the admin and redirects to login page" do
      post :adminlogout

      expect(session[:current_account_id]).to be_nil
      expect(response).to redirect_to(new_account_session_path)
    end
  end

  describe "GET #export_report" do
    it "generates and sends the PDF report" do
      allow(controller).to receive(:generate_pdf).and_return(Rails.root.join('spec', 'fixtures', 'dummy.pdf'))
      get :export_report

      expect(response.header['Content-Type']).to include 'application/pdf'
      expect(response.header['Content-Disposition']).to include 'attachment'
      expect(controller.instance_variable_get(:@monthly_sales_js)).not_to be_nil
      expect(controller.instance_variable_get(:@category_totals)).not_to be_nil
    end
  end

  describe "GET #category_totals" do
    it "returns category totals as JSON" do
      get :category_totals, format: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json; charset=utf-8")
    end
  end

  describe "POST #notify_report_export" do
    it "enqueues a Sidekiq worker for report export notification" do
      expect {
        post :notify_report_export
      }.to change(Sidekiq::Queues["default"], :size).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe "Private methods" do
    it "loads dashboard data correctly" do
      controller.send(:load_dashboard_data)

      account = controller.instance_variable_get(:@account)
      category_totals = controller.instance_variable_get(:@category_totals)
      top_product = controller.instance_variable_get(:@top_product)

      expect(account).to eq(admin)
      expect(category_totals).not_to be_nil
      expect(top_product).not_to be_nil
    end
  end

  describe "Authentication filter" do
    context "when admin is logged in" do
      it "does not redirect to noindex_path" do
        get :index

        expect(response).not_to redirect_to(noindex_path)
      end
    end

    context "when no admin is logged in" do
      before { session[:current_account_id] = nil }

      it "redirects to noindex_path" do
        get :index

        expect(response).to redirect_to(noindex_path)
      end
    end
  end
end
