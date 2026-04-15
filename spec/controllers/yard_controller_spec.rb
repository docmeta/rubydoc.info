require 'rails_helper'

RSpec.describe YARDController, type: :controller do
  render_views

  describe 'GET #featured' do
    let(:store) { instance_double(LibraryStore::FeaturedStore) }
    let(:adapter) { instance_double(YARD::Server::RackAdapter) }
    let(:router_instance) { instance_double(LibraryRouter::FeaturedRouter) }
    let(:library_version) { instance_double('Library', source_path: Pathname.new('/tmp/docs')) }

    before do
      allow(LibraryStore::FeaturedStore).to receive(:new).and_return(store)
      allow(YARD::Server::RackAdapter).to receive(:new).and_return(adapter)
      allow(LibraryRouter::FeaturedRouter).to receive(:new).with(adapter).and_return(router_instance)
      allow(router_instance).to receive(:parse_library_from_path).and_return([ library_version ])
      allow(FileUtils).to receive(:touch)
      allow(adapter).to receive(:call).and_return([
        200,
        { 'Content-Type' => 'text/html' },
        [ '<title>Docs</title><main>Generated docs</main>' ]
      ])
    end

    it 'disables Turbo prefetching for YARD pages' do
      get :featured, params: { name: 'yard' }

      expect(response).to be_successful
      expect(response.body).to include('<meta name="turbo-prefetch" content="false">')
    end
  end
end
