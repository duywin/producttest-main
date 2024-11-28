require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  let(:admin) { create(:account, :admin) }
  let(:category) { create(:category) }
  let(:product) { create(:product) }

  before do
    session[:current_account_id] = admin.id
    create(:category) # Ensuring at least one category exists
  end



  describe 'GET #show' do
    it 'assigns @product and renders the show template' do
      get :show, params: { id: product.id }

      expect(assigns(:product)).to eq(product)
      expect(response).to render_template(:show)
    end
  end

  describe 'GET #new' do
    it 'assigns a new product and renders the new template' do
      get :new
      expect(assigns(:product)).to be_a_new(Product)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new product and redirects to the product show page' do
        product_params = attributes_for(:product)

        expect {
          post :create, params: { product: product_params }
        }.to change(Product, :count).by(1)

        expect(response).to redirect_to(product_path(assigns(:product)))
      end
    end

    context 'with invalid attributes' do
      it 'does not create a product and redirects to the new template with an alert' do
        product_params = attributes_for(:product, name: nil)
        post :create, params: { product: product_params }
        expect(Product.count).to_not change.by(1)
        expect(response).to redirect_to(new_product_path)
        expect(flash[:alert]).to eq('Something went wrong. Please try again.')
      end
    end

  end

  describe 'GET #edit' do
    it 'assigns @product and renders the edit template' do
      get :edit, params: { id: product.id }

      expect(assigns(:product)).to eq(product)
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    context 'with valid attributes' do
      it 'updates the product and redirects to the product show page' do
        updated_name = 'Updated Product Name'
        patch :update, params: { id: product.id, product: { name: updated_name } }

        product.reload
        expect(product.name).to eq(updated_name)
        expect(response).to redirect_to(product_path(product))
      end
    end

    context 'with invalid attributes' do
      it 'does not update the product and re-renders the edit template' do
        patch :update, params: { id: product.id, product: { name: nil } }

        product.reload
        expect(product.name).not_to eq(nil)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the product and redirects to the index page' do
      product_to_destroy = create(:product)

      expect {
        delete :destroy, params: { id: product_to_destroy.id }
      }.to change(Product, :count).by(-1)

      expect(response).to redirect_to(products_path)
    end
  end

  describe 'GET #render_product_datatable' do
    it 'returns products data as JSON' do
      create_list(:product, 5)

      get :render_product_datatable
      expect(response.content_type).to eq("application/json")
      expect(JSON.parse(response.body)['data'].size).to eq(5)
    end
  end

  describe 'POST #export_report' do
    context 'with valid report type' do
      it 'exports the weekly report' do
        post :export_report, params: { report_type: 'weekly' }

        expect(response).to have_http_status(:success)
      end

      it 'exports the monthly report' do
        post :export_report, params: { report_type: 'monthly' }

        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid report type' do
      it 'returns an alert' do
        post :export_report, params: { report_type: 'invalid' }

        expect(flash[:alert]).to eq('Invalid report type.')
        expect(response).to redirect_to(products_path)
      end
    end
  end

  describe 'POST #import' do
    context 'with valid ODS file' do
      it 'starts the product import job' do
        uploaded_file = fixture_file_upload('files/valid_products.ods', 'application/vnd.oasis.opendocument.spreadsheet')

        post :import, params: { file: uploaded_file }

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq('Product import has started. You will be notified once complete.')
      end
    end

    context 'with invalid file type' do
      it 'shows an alert message' do
        uploaded_file = fixture_file_upload('files/invalid_file.txt', 'text/plain')

        post :import, params: { file: uploaded_file }

        expect(response).to redirect_to(products_path)
        expect(flash[:alert]).to eq('Please upload a valid ODS file.')
      end
    end
  end
end
