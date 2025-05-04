class GithubWebhookController < ApplicationController
  def create
    data = JSON.parse(request.body.read || "{}")
    payload = data.has_key?("payload") ? data["payload"] : data
    url = (payload["repository"] || {})["url"]
    commit = (payload["repository"] || {})["commit"]
    @project = GithubProject.new(url:, commit:)
    GithubCheckoutJob.perform_later(owner: @project.owner, project: @project.name, commit: @project.commit)
  end
end
