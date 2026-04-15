require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  describe "GET #show" do
    it "marks HTML error responses as non-cacheable" do
      get :show, params: { code: '500' }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(response.headers['Pragma']).to eq('no-cache')
      expect(response.headers['Expires']).to eq('0')
    end

    it "marks non-HTML error responses as non-cacheable" do
      get :show, params: { code: '500', format: :json }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.headers['Cache-Control']).to eq('no-store')
      expect(response.headers['Pragma']).to eq('no-cache')
      expect(response.headers['Expires']).to eq('0')
    end
  end
end
