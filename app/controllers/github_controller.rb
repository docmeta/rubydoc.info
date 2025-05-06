class GithubController < ApplicationController
  include AlphaIndexable
  include Searchable
  include Pageable
  include Cacheable

  layout "modal", only: [ :add_project, :create ]

  prepend_before_action do
    @title = "GitHub Projects"
    @collection = Library.github.all
  end

  def index
    render "shared/library_list"
  end

  def add_project
    @project ||= GithubProject.new
  end

  def create
    @project = GithubProject.new(params.require(:github_project).permit(%i[url commit]))
    if @project.validate
      GithubCheckoutJob.perform_now(owner: @project.owner, project: @project.name, commit: @project.commit)
      redirect_to yard_github_path(@project.owner, @project.name, @project.commit)
    else
      add_project
    end
  rescue IOError => e
    logger.error "Failed to create GitHub project: #{e.message}"
    @project.errors.add(:url, "could not be cloned. Please check the URL and try again.")
    render :add_project
  end

  private

  def default_alpha_index
    nil
  end

  def set_alpha_index_collection
    @collection = @collection.reorder(updated_at: :desc).limit(10) if @letter.blank?
    super
  end
end
