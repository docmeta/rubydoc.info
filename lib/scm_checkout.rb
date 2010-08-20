module ScmCheckout
  def register_project(name)
    puts "#{Time.now}: Registering project #{name}"
    files = ["github.html", "github/#{name}.html", "github/#{name}", "list/github/#{name}"]
    rm_cmd = "rm -rf #{files.map {|f| File.join(options.public, f) }.join(' ')}"
    `#{rm_cmd}`
    puts "#{Time.now}: Flushing cache for #{name} (#{$?}): #{rm_cmd}"
  end

  def checkout(url, name, commit = nil, scheme = "git")
    commit = nil if commit.empty?
    github_project = nil
    name.gsub!(/[^a-z0-9-]/i, '_')
    if username = url[%r{\Agit://(?:www\.)?github.com/([^/]+)/}, 1]
      github_project = name
      name = "#{name}/#{username}"
    end
    cmd = case scheme
    when "git"
      fork = true
      begin
        if github_project && !File.directory?(File.join(options.repos, name))
          json = JSON.parse(open("http://github.com/api/v1/json/#{username}").read)
          proj_json = json["user"]["repositories"].find {|s| s["name"] == github_project }
          fork = proj_json["fork"] if proj_json
        end
      rescue IOError, OpenURI::HTTPError
      end
      checkout_command_for_git(url, name, commit, fork)
    when "svn"
      checkout_command_for_svn(url, name)
    else
      return
    end
    
    co_cmd = "cd #{options.repos} && #{cmd} && yardoc -n -q --no-cache && touch .yardoc/complete"
    out = `#{co_cmd}`
    result = $?
    puts "#{Time.now}: Checkout command (#{result}): #{co_cmd}"
    errorfile = "#{options.tmp}/#{[name.gsub('/', '_'), commit].join('_')}.error.txt"
    if result == 0
      register_project(name)
      File.unlink(errorfile) if File.file?(errorfile)
    else
      File.open(errorfile, "w") {|f| f.write(out) }
    end
  end
  
  private

  def checkout_command_for_svn(url, name)
    if File.directory?(File.join(options.repos, name))
      "cd #{name} && svn up"
    else
      "svn co #{url} #{name} && cd #{name}"
    end
  end

  def checkout_command_for_git(url, name, commit = nil, fork = true)
    commit_name = commit || 'master'
    commit_name = commit_name[0,6] if commit && commit.length == 40
    dirname = File.join(options.repos, name, commit_name)
    if File.directory?(dirname)
      "cd #{name}/#{commit_name} && git reset --hard && git pull --force"
    else
      fork_cmd = fork ? nil : "echo #{name.split('/').reverse.join('/')} > ../../.master_fork"
      checkout = if commit
        "git fetch && trap \"git pull origin #{commit_name}\" TERM && git checkout #{commit_name}"
      else
        nil
      end
      ["mkdir -p #{name}", "cd #{name}", 
        "git clone #{url} #{commit_name}", "cd #{commit_name}", 
        checkout, fork_cmd].compact.join(" && ")
    end
  end
end
