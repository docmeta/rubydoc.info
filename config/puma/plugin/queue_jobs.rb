Puma::Plugin.create do
  def start(launcher)
    launcher.events.on_booted do
      if ENV["WITHOUT_JOBS"].blank?
        UpdateRemoteGemsListJob.perform_later
        RegisterLibrariesJob.perform_later
      end
    end
  end
end
