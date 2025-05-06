class ReapGenerateDocsJob < ApplicationJob
  queue_as :default

  def perform
    running_containers.each do |id, created_at|
      if created_at < 5.minutes.ago
        logger.info "Stopping DEAD container #{id} (created at #{created_at})"
        `docker rm -f #{id}`
      end
    end
  end

  private

  def running_containers
    `docker ps -f status=running -f ancestor=#{GenerateDocsJob::IMAGE} --format '{{.ID}},{{.CreatedAt}}'`
      .strip
      .split("\n")
      .map { |line| id, time = line.split(","); [ id, DateTime.parse(time) ] }
      .to_h
  end
end
