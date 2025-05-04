class YARDCopyAssetsJob < ApplicationJob
  queue_as :default

  def perform
    # Copy static assets from the yard to the public directory
    Rails.logger.info "YARD: Copying static system files..."
    YARD::Templates::Engine.template(:default, :fulldoc, :html).full_paths.each do |path|
      %w[css js images].each do |ext|
        srcdir, dstdir = Pathname.new(path).join(ext), Rails.root.join("public", "assets", ext)
        next unless srcdir.directory?

        dstdir.mkpath
        FileUtils.cp_r(srcdir.glob("*"), dstdir)
      end
    end
  end
end
