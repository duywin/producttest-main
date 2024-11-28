require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do
  let(:admin_account) { create(:account) }
  # Test for authenticate_admin before action
  describe "before actions" do

    context "when current_account_id is not set" do
      before { session[:current_account_id] = nil }

      it "redirects to noindex path" do
        get :index
        expect(response).to redirect_to(noindex_path)
      end
    end

    context "when current_account_id is set" do
      before { session[:current_account_id] = admin_account.id }

      it "does not redirect" do
        get :index
        expect(response).to_not redirect_to(noindex_path)
      end
    end
  end

  # Test for index action (HTML and JSON response)
  describe "GET #index" do
    let!(:category) { create(:category, name: "Sample Category", total: 10) }
    before do
      session[:current_account_id] = admin_account.id
      allow(Category).to receive(:page).and_return(Category.all)
    end

    context "HTML format" do
      it "assigns @categories and @category and renders the index template" do
        get :index, format: :html
        expect(assigns(:categories)).to include(category)
        expect(assigns(:category)).to be_a_new(Category)
        expect(response).to render_template(:index)
      end
    end

    context "JSON format" do
      it "returns categories data as JSON" do
        get :index, format: :json
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response).to include("data")
        expect(json_response["data"]).to include(
                                           { "name" => category.name, "total" => category.total, "id" => category.id }
                                         )
      end
    end
  end



  # Test for refreshtotal action
  describe "POST #refreshtotal" do
    before { session[:current_account_id] = admin_account.id }
    it "updates the total for each category" do
      category = create(:category)
      create(:product, product_type: category.name)

      post :refreshtotal
      expect(category.reload.total).to eq(1)
      expect(response).to redirect_to(categories_path)
      expect(flash[:notice]).to eq("Total counts refreshed successfully.")
    end
  end

  # Test for import action
  describe "POST #import" do
    before { session[:current_account_id] = admin_account.id }
    context "when no file is uploaded" do
      it "redirects with an alert" do
        post :import
        expect(response).to redirect_to(categories_path)
        expect(flash[:alert]).to eq("Please upload an ODS file.")
      end
    end

    context "when a file is uploaded" do
      let(:file) { Rack::Test::UploadedFile.new('/home/intern-npduy1/Documents/test.ods', 'application/vnd.oasis.opendocument.spreadsheet') }

      it "saves the file and queues the import job" do
        allow(ImportCategoriesJob).to receive(:perform_async)
        post :import, params: { file: file }
        expect(ImportCategoriesJob).to have_received(:perform_async)
        expect(response).to redirect_to(categories_path)
        expect(flash[:notice]).to eq("File read successfully. Please wait for the import.")
      end
    end
  end

  # Test for create action
  describe "POST #create" do
    before { session[:current_account_id] = admin_account.id }
    context "with valid parameters" do
      let(:valid_attributes) { { name: "New Category", total: 10 } }

      it "creates a new category and redirects" do
        expect {
          post :create, params: { category: valid_attributes }
        }.to change(Category, :count).by(1)

        expect(response).to redirect_to(categories_path)
        expect(flash[:notice]).to eq("Category was successfully created.")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: nil } }

      it "does not create a category and redirects with an alert" do
        expect {
          post :create, params: { category: invalid_attributes }
        }.not_to change(Category, :count)

        expect(response).to redirect_to(categories_path)
        expect(flash[:alert]).to eq("Unable to create category")
      end
    end
  end


  # Test for destroy action
  describe "DELETE #destroy" do
    let!(:category) { create(:category, name: "test") }
    before { session[:current_account_id] = admin_account.id }


    it "deletes the category and redirects to index" do
      expect(Category.exists?(category.id)).to be_truthy
      delete :destroy, params: { id: category.id }
      expect(Category.exists?(category.id)).to be_falsey
      expect(response).to redirect_to(categories_path)
      log_entry = "WARN Category: User ID: #{admin_account.id} - Category 'test' (ID: #{category.id}) was deleted"
      expect { Rails.logger.warn(log_entry) }.not_to raise_error
    end
  end

end
