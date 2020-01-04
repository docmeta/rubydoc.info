require_relative '../init'
require_relative 'gem_updater'

module AppPreloader
  def self.preload!
    copy_static_files
    start_update_gems_timer
    GC.compact
  end

  def self.copy_static_files
    # Copy template files
    puts ">> Copying static system files..."
    YARD::Templates::Engine.template(:default, :fulldoc, :html).full_paths.each do |path|
      %w(css js images).each do |ext|
        srcdir, dstdir = File.join(path, ext), File.join('public', ext)
        next unless File.directory?(srcdir)
        system "mkdir -p #{dstdir} && cp #{srcdir}/* #{dstdir}/"
      end
    end
  end

  def self.start_update_gems_timer
    Thread.new do
      loop do
        fork { GemUpdater.update_remote_gems display: true }
        sleep 600
      end
    end
  end
end
