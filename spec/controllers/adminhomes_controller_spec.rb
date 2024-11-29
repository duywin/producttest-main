# spec/controllers/adminhomes_controller_spec.rb
require 'rails_helper'
require 'sidekiq/testing'


RSpec.describe AdminhomesController, type: :controller do
  Sidekiq::Testing.fake!
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
      # Mock the generate_pdf method to return a fixed file path
      file_path = Rails.root.join('spec', 'fixtures', 'dummy.pdf').to_s  # Ensure it's a string
      allow(controller).to receive(:generate_pdf).and_return(file_path)

      # Mock send_file to prevent the actual file from being sent during tests
      allow(controller).to receive(:send_file)

      # Trigger the action
      get :export_report

      # Check that send_file was called with the expected arguments
      expect(controller).to have_received(:send_file).with(
        file_path,
        filename: 'admin_report.pdf',
        type: 'application/pdf',
        disposition: 'attachment'
      )
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
      # Simulate the method call that would normally enqueue the job
      allow(controller).to receive(:build_export_promises).and_return([])

      # Check if the job is enqueued correctly by monitoring the Sidekiq queue
      expect {
        # Directly trigger the controller's internal method without calling POST
        controller.send(:notify_report_export)
      }.to change(Sidekiq::Queues["default"], :size).by(1)

      # Check the response status (if the controller was set up to return something)
      expect(response).to have_http_status(:success)  # Or any other relevant response

      # Now validate that the job is valid and ready to be performed
      job_payload = Sidekiq::Queues["default"].first['args']
      expect(job_payload).to match_array([anything, anything])  # Ensure the job can be enqueued successfully
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
