SolidQueue.on_start do
  Thread.new { GenerateDocsJob.prepare_image }

  # Queue a few jobs on start
  [ UpdateRemoteGemsListJob, RegisterLibrariesJob ].each do |job_class|
    if SolidQueue::Job.where(class_name: job_class.name).none?
      Rails.logger.info "Queueing #{job_class.name} job on start..."
      job_class.perform_later
    end
  end
end
