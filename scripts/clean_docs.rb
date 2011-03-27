require_relative '../init'

MAX_DOCS_PER_PROJECT = 4

# [REMOTE_GEMS_PATH, REPOS_PATH].each do |source_dir|
[REPOS_PATH].each do |source_dir|
  Dir.glob("#{source_dir}/*/*") do |project_dir|
    puts ">> Checking #{project_dir}"

    candidate_dirs = {}
    dir_count      = 0

    Dir.glob("#{project_dir}/*").each do |dir|
      dir_count += 1

      if dir =~ /master$/
        puts "  >> Keeping master #{dir}"
      else
        candidate_dirs[dir] = File.new(dir).mtime.to_i
      end
    end

    candidate_dirs = candidate_dirs.sort_by { |dir, time| time }.map { |d| d[0] }
    keep_dir_count = (candidate_dirs.size > MAX_DOCS_PER_PROJECT) ? MAX_DOCS_PER_PROJECT : candidate_dirs.size
    keep_dir_count.times do
      keep_dir = candidate_dirs.shift
      puts "  >> Keeping #{keep_dir}"
    end

    candidate_dirs.each do |dir, time|
      puts "  >> Deleting #{dir}"
      FileUtils.rm_r(dir)
    end
  end
end
