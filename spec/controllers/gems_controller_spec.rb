require 'rails_helper'

RSpec.describe GemsController, type: :controller do
  describe "GET #index" do
    before do
      create(:gem, name: 'activerecord', versions: [ '7.0.0' ])
      create(:gem, name: 'actionpack', versions: [ '3.12.0' ])
    end

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "sets the title" do
      get :index
      expect(assigns(:title)).to eq("RubyGems")
    end

    it "loads allowed gems" do
      get :index
      expect(assigns(:collection).to_a.count).to eq(2)
    end

    context "with letter filter" do
      it "filters by letter" do
        get :index, params: { letter: 'r' }
        expect(response).to be_successful
        expect(assigns(:letter)).to eq('r')
      end
    end

    context "with pagination" do
      before do
        30.times { |i| create(:gem, name: "gem#{i}") }
      end

      it "paginates results" do
        get :index, params: { page: 2 }
        expect(response).to be_successful
      end
    end
  end
end
