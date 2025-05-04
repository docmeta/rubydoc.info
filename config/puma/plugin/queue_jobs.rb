Puma::Plugin.create do
  def start(launcher)
    launcher.events.on_booted do
      if ENV["WITHOUT_JOBS"].blank?
        [UpdateRemoteGemsListJob, RegisterLibrariesJob].each do |job_class|
          if SolidQueue::Job.where(class_name: job_class.name).none?
            job_class.perform_later
          end
        end
      end
    end
  end
end
