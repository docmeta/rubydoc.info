require 'rails_helper'

RSpec.describe StdlibController, type: :controller do
  describe "GET #index" do
    before do
      create(:stdlib, name: 'json', versions: ['2.6.0'])
      create(:stdlib, name: 'csv', versions: ['3.2.0'])
    end

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "sets the title" do
      get :index
      expect(assigns(:title)).to eq("Ruby Standard Library")
      expect(assigns(:page_title)).to eq("Ruby Standard Library")
    end

    it "loads stdlib libraries" do
      get :index
      expect(assigns(:collection).count).to eq(2)
    end

    it "renders the library_list template" do
      get :index
      expect(response).to render_template("shared/library_list")
    end
  end
end
