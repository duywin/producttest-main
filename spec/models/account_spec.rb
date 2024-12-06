require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'Validations' do
    before do
      # Create an existing record to test uniqueness
      Account.create!(
        username: "existing_user",
        email: "existing@example.com",
        password: "Password1!"
      )
    end

    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

    describe 'password complexity' do
      it 'is invalid without an uppercase letter' do
        account = Account.new(password: 'password1!')
        account.validate
        expect(account.errors[:password]).to include("must include at least one uppercase letter")
      end

      it 'is invalid without a number' do
        account = Account.new(password: 'Password!')
        account.validate
        expect(account.errors[:password]).to include("must include at least one number")
      end

      it 'is invalid without a symbol' do
        account = Account.new(password: 'Password1')
        account.validate
        expect(account.errors[:password]).to include("must include at least one symbol")
      end
    end
  end

  describe 'Elasticsearch' do
    let(:account) { create(:account) }

    it 'indexes a document in Elasticsearch after creation' do
      expect(account.__elasticsearch__).to receive(:index_document)
      account.run_callbacks(:create)
    end

    it 'updates a document in Elasticsearch after update' do
      expect(account.__elasticsearch__).to receive(:update_document)
      account.run_callbacks(:update)
    end
  end

describe 'Class Methods' do
  describe '.search' do
    let!(:current_week_account) { create(:account, created_at: Time.current, username: 'testuser1', email: 'test1@example.com') }
    let!(:last_week_account) { create(:account, created_at: 1.week.ago, username: 'testuser2', email: 'test2@example.com') }

    it 'returns results matching the query' do
      result = Account.search('testuser1')
      expect(result.records).to include(current_week_account)
      expect(result.records).not_to include(last_week_account)
    end

    it 'filters by created_at when "this_week" filter is provided' do
      current_week_account = create(:account, created_at: Time.current, username: 'week_user', email: 'week@example.com')
      outside_week_account = create(:account, created_at: 1.week.ago, username: 'last_week_user', email: 'last_week@example.com')

      result = Account.search('user', 'this_week')
      expect(result.records).to include(current_week_account)
      expect(result.records).not_to include(outside_week_account)
    end
  end
end


