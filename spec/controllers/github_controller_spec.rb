require 'rails_helper'

RSpec.describe GithubController, type: :controller do
  describe "GET #index" do
    before do
      create(:github, name: 'rails', owner: 'rails', versions: ['main'])
      create(:github, name: 'ruby', owner: 'ruby', versions: ['master'])
    end

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "sets the title" do
      get :index
      expect(assigns(:title)).to eq("GitHub Projects")
    end

    it "loads allowed github projects" do
      get :index
      expect(assigns(:collection).count).to eq(2)
    end

    context "with letter filter" do
      it "filters by letter" do
        get :index, params: { letter: 'r' }
        expect(response).to be_successful
      end
    end

    context "without letter filter" do
      it "shows latest 10 projects" do
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe "GET #add_project" do
    it "returns a successful response" do
      get :add_project
      expect(response).to be_successful
    end

    it "initializes a new project" do
      get :add_project
      expect(assigns(:project)).to be_a(GithubProject)
      expect(assigns(:project).url).to be_nil
    end

    it "uses modal layout" do
      get :add_project
      expect(response).to render_template(layout: 'modal')
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      { github_project: { url: 'https://github.com/rails/rails', commit: '' } }
    end

    let(:invalid_params) do
      { github_project: { url: 'invalid-url', commit: '' } }
    end

    context "with valid parameters" do
      it "creates a github checkout job" do
        expect(GithubCheckoutJob).to receive(:perform_now)
          .with(owner: 'rails', project: 'rails', commit: '')

        post :create, params: valid_params
      end

      it "redirects to the yard path" do
        allow(GithubCheckoutJob).to receive(:perform_now)
        post :create, params: valid_params
        expect(response).to redirect_to(yard_github_path('rails', 'rails', ''))
      end
    end

    context "with invalid parameters" do
      it "renders add_project template" do
        post :create, params: invalid_params
        expect(response).to render_template(:add_project)
      end

      it "sets errors on the project" do
        post :create, params: invalid_params
        expect(assigns(:project).errors).to be_present
      end
    end

    context "when IOError is raised" do
      it "adds error and renders add_project" do
        allow(GithubCheckoutJob).to receive(:perform_now).and_raise(IOError, "Network error")
        post :create, params: valid_params

        expect(response).to render_template(:add_project)
        expect(assigns(:project).errors[:url]).to include("could not be cloned. Please check the URL and try again.")
      end
    end

    context "when DisallowedCheckoutError is raised" do
      it "adds error and renders add_project" do
        allow(GithubCheckoutJob).to receive(:perform_now).and_raise(DisallowedCheckoutError.new(owner: 'rails', project: 'rails'))
        post :create, params: valid_params

        expect(response).to render_template(:add_project)
        expect(assigns(:project).errors[:url]).to include("is not allowed. Please check the URL and try again.")
      end
    end
  end
end
