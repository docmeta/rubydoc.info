SolidQueue.on_start do
  UpdateRemoteGemsListJob.clear_lock_file

  # Queue a few jobs on start
  [ UpdateRemoteGemsListJob, RegisterLibrariesJob, ReapGenerateDocsJob ].each do |job_class|
    if SolidQueue::Job.where(class_name: job_class.name, finished_at: nil).none?
      Rails.logger.info "[initializer/queue_jobs] Queueing #{job_class.name} job on start..."
      job_class.perform_later
    end
  end
end
