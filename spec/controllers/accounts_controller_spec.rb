require 'rails_helper'

RSpec.describe AccountsController, type: :controller do
  let(:admin) { create(:account, :admin) }
  let(:user) { create(:account) }

  before do
    allow(controller).to receive(:authenticate_admin).and_return(true)
  end

  describe "before actions" do

    context "when current_account_id is not set" do
      before do
        session[:current_account_id] = nil  # Simulate no user being logged in
      end

      it "redirects to the noindex path" do
        get :index
        expect(response).to redirect_to(noindex_path)
      end
    end

    context "when current_account_id is set" do
      before { session[:current_account_id] = admin.id }

      it "does not redirect" do
        get :index
        expect(response).to_not redirect_to(noindex_path)
      end
    end
  end

  describe "GET #index" do
    context "as an admin" do
      it "renders the index template" do
        session[:current_account_id] = admin.id
        get :index
        expect(response).to render_template(:index)
      end
    end
  end

  describe "POST #import" do
    context "when a file is uploaded" do
      let(:file) { Rack::Test::UploadedFile.new('/home/intern-npduy1/Documents/user.ods', 'application/vnd.oasis.opendocument.spreadsheet') }

      it "saves the file and queues the import job" do
        allow(ImportAccountsJob).to receive(:perform_async)
        post :import, params: { file: file }
        expect(ImportAccountsJob).to have_received(:perform_async)
        expect(response).to redirect_to(accounts_path)
        expect(flash[:notice]).to eq('Importing accounts. You will be notified once the import is complete.')
      end
    end

    context "without a file" do
      it "redirects with an alert" do
        post :import, params: { file: nil }
        expect(response).to redirect_to(accounts_path)
        expect(flash[:alert]).to eq("Please upload an ODS file.")
      end
    end

    context "with invalid file" do
      it "redirects with an alert" do
        file = Rack::Test::UploadedFile.new('/home/intern-npduy1/Reports/ip', 'text/plain')
        post :import, params: { file: file }
        expect(response).to redirect_to(accounts_path)
        expect(flash[:alert]).to eq("Please upload a valid ODS file.")
      end
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates a new account and redirects to its show page" do
        account_params = attributes_for(:account)
        expect {
          post :create, params: { account: account_params }
        }.to change(Account, :count).by(1)
        expect(response).to redirect_to(assigns(:account))
        expect(flash[:notice]).to eq("Account was successfully created.")
      end
    end

    context "with invalid attributes" do
      it "does not create a new account and renders the new template" do
        account_params = attributes_for(:account, username: nil)
        expect {
          post :create, params: { account: account_params }
        }.to_not change(Account, :count)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:account) { create(:account) }

    it "deletes the account and redirects to the index page" do
      expect {
        delete :destroy, params: { id: account.id }
      }.to change(Account, :count).by(-1)
      expect(response).to redirect_to(accounts_url)
      expect(flash[:notice]).to eq("Account was successfully destroyed.")
    end
  end

  describe "PUT #update" do
    let!(:account) { create(:account, username: "old_username") }

    context "with valid attributes" do
      it "updates the account and redirects to its show page" do
        put :update, params: { id: account.id, account: { username: "new_username" } }
        account.reload
        expect(account.username).to eq("new_username")
        expect(response).to redirect_to(account)
        expect(flash[:notice]).to eq("Account was successfully updated.")
      end
    end

    context "with invalid attributes" do
      it "does not update the account and renders the edit template" do
        put :update, params: { id: account.id, account: { username: nil } }
        account.reload
        expect(account.username).to eq("old_username")
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "GET #show" do
    it "assigns the requested account to @account and renders the show template" do
      get :show, params: { id: user.id }
      expect(assigns(:account)).to eq(user)
      expect(response).to render_template(:show)
    end
  end


end
