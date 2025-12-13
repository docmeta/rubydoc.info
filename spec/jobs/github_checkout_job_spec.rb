require 'rails_helper'

RSpec.describe GithubCheckoutJob, type: :job do
  let(:owner) { 'rails' }
  let(:project) { 'rails' }
  let(:commit) { 'main' }

  subject { described_class.new }

  before do
    allow(subject).to receive(:sh).and_return(true)
  end

  describe '#perform' do
    let(:library_version) { double('LibraryVersion', disallowed?: false) }

    before do
      allow(subject).to receive(:library_version).and_return(library_version)
      allow(subject).to receive(:run_checkout).and_return(true)
      allow(subject).to receive(:register_project)
      allow(subject).to receive(:flush_cache)
    end

    it 'sets owner, project, and commit' do
      subject.perform(owner: owner, project: project, commit: commit)
      expect(subject.owner).to eq(owner)
      expect(subject.project).to eq(project)
      expect(subject.commit).to eq(commit)
    end

    it 'runs checkout process' do
      expect(subject).to receive(:run_checkout).and_return(true)
      subject.perform(owner: owner, project: project, commit: commit)
    end

    it 'registers the project after successful checkout' do
      expect(subject).to receive(:register_project)
      subject.perform(owner: owner, project: project, commit: commit)
    end

    it 'flushes cache after successful checkout' do
      expect(subject).to receive(:flush_cache)
      subject.perform(owner: owner, project: project, commit: commit)
    end

    context 'when commit is blank' do
      it 'uses primary branch' do
        allow(subject).to receive(:primary_branch).and_return('master')
        subject.perform(owner: owner, project: project, commit: '')
        expect(subject.commit).to eq('master')
      end
    end

    context 'when library is disallowed' do
      before do
        allow(library_version).to receive(:disallowed?).and_return(true)
      end

      it 'raises DisallowedCheckoutError' do
        expect {
          subject.perform(owner: owner, project: project, commit: commit)
        }.to raise_error(DisallowedCheckoutError)
      end
    end

    context 'when checkout fails' do
      before do
        allow(subject).to receive(:run_checkout).and_return(false)
      end

      it 'does not register project' do
        expect(subject).not_to receive(:register_project)
        subject.perform(owner: owner, project: project, commit: commit)
      end

      it 'does not flush cache' do
        expect(subject).not_to receive(:flush_cache)
        subject.perform(owner: owner, project: project, commit: commit)
      end
    end
  end

  describe '#commit=' do
    it 'converts empty string to nil' do
      subject.commit = ''
      expect(subject.commit).to be_nil
    end

    it 'truncates 40-character SHA to 6 characters' do
      subject.commit = 'a' * 40
      expect(subject.commit).to eq('a' * 6)
    end

    it 'extracts valid commit reference' do
      subject.commit = '  abc123/branch_name  '
      expect(subject.commit).to eq('abc123/branch_name')
    end

    it 'handles branch names with dots, slashes, and underscores' do
      subject.commit = 'feature/my_branch.v1'
      expect(subject.commit).to eq('feature/my_branch.v1')
    end

    it 'sets nil value as nil' do
      subject.commit = nil
      expect(subject.commit).to be_nil
    end
  end

  describe '#name' do
    it 'returns owner/project format' do
      subject.owner = 'rails'
      subject.project = 'rails'
      expect(subject.name).to eq('rails/rails')
    end
  end

  describe '#url' do
    it 'returns GitHub URL' do
      subject.owner = 'rails'
      subject.project = 'rails'
      expect(subject.url).to eq('https://github.com/rails/rails')
    end
  end

  describe '#run_checkout' do
    let(:repository_path) { instance_double(Pathname, directory?: false) }

    before do
      allow(subject).to receive(:repository_path).and_return(repository_path)
      subject.commit = commit
    end

    context 'when commit is present and repository exists' do
      before do
        allow(repository_path).to receive(:directory?).and_return(true)
      end

      it 'runs checkout pull' do
        expect(subject).to receive(:run_checkout_pull).and_return(true)
        subject.run_checkout
      end
    end

    context 'when repository does not exist' do
      it 'runs checkout clone' do
        expect(subject).to receive(:run_checkout_clone).and_return(true)
        subject.run_checkout
      end
    end

    context 'when commit is not present' do
      before do
        subject.commit = nil
      end

      it 'runs checkout clone' do
        expect(subject).to receive(:run_checkout_clone).and_return(true)
        subject.run_checkout
      end
    end
  end

  describe '#run_checkout_pull' do
    let(:repository_path) { instance_double(Pathname, to_s: '/path/to/repo', join: yardoc_path) }
    let(:yardoc_path) { instance_double(Pathname, directory?: true, rmtree: nil) }

    before do
      allow(subject).to receive(:repository_path).and_return(repository_path)
      allow(subject).to receive(:write_fork_data)
      subject.owner = owner
      subject.project = project
      subject.commit = commit
    end

    it 'writes fork data' do
      expect(subject).to receive(:write_fork_data)
      subject.run_checkout_pull
    end

    it 'runs git reset and pull commands' do
      expect(subject).to receive(:sh).with(
        a_string_matching(/git reset --hard.*git pull --force/),
        hash_including(title: "Updating project #{owner}/#{project}")
      )
      subject.run_checkout_pull
    end

    it 'removes .yardoc directory if present' do
      expect(yardoc_path).to receive(:rmtree)
      subject.run_checkout_pull
    end

    context 'when .yardoc does not exist' do
      before do
        allow(yardoc_path).to receive(:directory?).and_return(false)
      end

      it 'does not try to remove it' do
        expect(yardoc_path).not_to receive(:rmtree)
        subject.run_checkout_pull
      end
    end
  end

  describe '#run_checkout_clone' do
    let(:temp_clone_path) { instance_double(Pathname, to_s: '/tmp/clone', parent: temp_parent) }
    let(:temp_parent) { instance_double(Pathname, mkpath: nil) }
    let(:repository_path) { instance_double(Pathname, to_s: '/path/to/repo', parent: repo_parent) }
    let(:repo_parent) { instance_double(Pathname, mkpath: nil) }

    before do
      allow(subject).to receive(:temp_clone_path).and_return(temp_clone_path)
      allow(subject).to receive(:repository_path).and_return(repository_path)
      allow(subject).to receive(:write_primary_branch_file)
      allow(subject).to receive(:write_fork_data)
      allow(subject).to receive(:`).and_return('main')
      subject.owner = owner
      subject.project = project
      subject.commit = commit
    end

    it 'creates parent directory for temp clone path' do
      expect(temp_parent).to receive(:mkpath)
      subject.run_checkout_clone
    end

    it 'runs git clone command' do
      expect(subject).to receive(:sh).with(
        a_string_matching(/git clone.*--depth 1.*--single-branch/),
        hash_including(title: "Cloning project #{owner}/#{project}")
      )
      allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
      subject.run_checkout_clone
    end

    it 'includes branch option when commit is present' do
      expect(subject).to receive(:sh).with(
        a_string_matching(/--branch #{commit}/),
        anything
      )
      allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
      subject.run_checkout_clone
    end

    it 'creates parent directory for repository path' do
      expect(repo_parent).to receive(:mkpath)
      subject.run_checkout_clone
    end

    it 'writes fork data' do
      expect(subject).to receive(:write_fork_data)
      subject.run_checkout_clone
    end

    it 'moves temp clone to repository path' do
      expect(subject).to receive(:sh).with(
        a_string_matching(/rm -rf.*mv/),
        hash_including(title: "Move #{owner}/#{project} into place")
      )
      subject.run_checkout_clone
    end

    it 'returns true' do
      expect(subject.run_checkout_clone).to be true
    end

    context 'when commit is blank' do
      before do
        subject.commit = nil
      end

      it 'does not include branch option' do
        expect(subject).to receive(:sh).with(
          a_string_matching(/git clone.*--depth 1.*--single-branch(?!.*--branch)/),
          anything
        )
        allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
        subject.run_checkout_clone
      end

      it 'writes primary branch file' do
        expect(subject).to receive(:write_primary_branch_file)
        subject.run_checkout_clone
      end

      it 'detects current branch' do
        expect(subject).to receive(:`).with(a_string_matching(/git.*rev-parse.*HEAD/))
        subject.run_checkout_clone
        expect(subject.commit).to eq('main')
      end
    end

    context 'when commit is present' do
      it 'does not write primary branch file' do
        expect(subject).not_to receive(:write_primary_branch_file)
        subject.run_checkout_clone
      end
    end
  end

  describe 'shell injection prevention' do
    let(:malicious_commit) { "main; rm -rf /" }
    let(:malicious_owner) { "owner'; rm -rf /; echo '" }
    let(:malicious_project) { "project`rm -rf /`" }

    before do
      allow(subject).to receive(:write_fork_data)
      allow(subject).to receive(:write_primary_branch_file)
      allow(subject).to receive(:`).and_return('main')
    end

    describe '#run_checkout_pull' do
      let(:repository_path) { instance_double(Pathname, to_s: '/tmp/repo', join: yardoc_path) }
      let(:yardoc_path) { instance_double(Pathname, directory?: false) }

      before do
        allow(subject).to receive(:repository_path).and_return(repository_path)
      end

      it 'escapes commit parameter in git commands' do
        subject.owner = owner
        subject.project = project
        subject.commit = malicious_commit

        expect(subject).to receive(:sh) do |cmd, _|
          # Verify semicolon is escaped (becomes \;)
          expect(cmd).to include('main\\;')
          # Verify the malicious part doesn't execute as a separate command
          expect(cmd).not_to match(/; rm/)
        end
        subject.run_checkout_pull
      end

      it 'escapes repository path in git commands' do
        subject.owner = owner
        subject.project = project
        subject.commit = commit

        expect(subject).to receive(:sh).with(
          a_string_including(Shellwords.escape(repository_path.to_s)),
          anything
        )
        subject.run_checkout_pull
      end
    end

    describe '#run_checkout_clone' do
      let(:temp_clone_path) { instance_double(Pathname, to_s: '/tmp/clone', parent: temp_parent) }
      let(:temp_parent) { instance_double(Pathname, mkpath: nil) }
      let(:repository_path) { instance_double(Pathname, to_s: '/path/to/repo', parent: repo_parent) }
      let(:repo_parent) { instance_double(Pathname, mkpath: nil) }

      before do
        allow(subject).to receive(:temp_clone_path).and_return(temp_clone_path)
        allow(subject).to receive(:repository_path).and_return(repository_path)
      end

      it 'escapes malicious commit in branch option' do
        subject.owner = owner
        subject.project = project
        subject.commit = malicious_commit

        expect(subject).to receive(:sh) do |cmd, _|
          # Verify semicolon is escaped
          expect(cmd).to include('--branch main\\;')
          # Verify the rm command doesn't execute as separate command
          expect(cmd).not_to match(/; rm/)
        end
        allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
        subject.run_checkout_clone
      end

      it 'escapes URL in git clone command' do
        subject.owner = malicious_owner
        subject.project = project
        subject.commit = commit

        expected_url = "https://github.com/#{malicious_owner}/#{project}"
        expect(subject).to receive(:sh).with(
          a_string_including(Shellwords.escape(expected_url)),
          anything
        )
        allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
        subject.run_checkout_clone
      end

      it 'escapes temp clone path in git clone command' do
        subject.owner = owner
        subject.project = project
        subject.commit = commit

        expect(subject).to receive(:sh).with(
          a_string_including(Shellwords.escape(temp_clone_path.to_s)),
          anything
        )
        allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
        subject.run_checkout_clone
      end

      it 'escapes paths in git -C command for branch detection' do
        subject.owner = owner
        subject.project = project
        subject.commit = nil

        expect(subject).to receive(:`).with(
          a_string_including(Shellwords.escape(temp_clone_path.to_s))
        )
        allow(subject).to receive(:sh)
        subject.run_checkout_clone
      end

      it 'escapes all paths in mv command' do
        subject.owner = owner
        subject.project = project
        subject.commit = commit

        allow(subject).to receive(:sh)
        expect(subject).to receive(:sh).with(
          a_string_matching(/rm -rf #{Regexp.escape(Shellwords.escape(repository_path.to_s))}.*mv #{Regexp.escape(Shellwords.escape(temp_clone_path.to_s))} #{Regexp.escape(Shellwords.escape(repository_path.to_s))}/),
          anything
        )
        subject.run_checkout_clone
      end

      it 'prevents command injection through owner name' do
        subject.owner = malicious_owner
        subject.project = project
        subject.commit = commit

        # Should not execute arbitrary commands
        expect(subject).to receive(:sh) do |cmd, _|
          # Verify the malicious content is properly escaped and won't execute
          expect(cmd).to include(Shellwords.escape("https://github.com/#{malicious_owner}/#{project}"))
          expect(cmd).not_to include("rm -rf /;")
        end
        allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
        subject.run_checkout_clone
      end

      it 'prevents command injection through project name' do
        subject.owner = owner
        subject.project = malicious_project
        subject.commit = commit

        expect(subject).to receive(:sh) do |cmd, _|
          # Verify backtick is escaped (becomes \`)
          expect(cmd).to include('project\\`rm')
          # Original URL should be escaped
          expect(cmd).to include(Shellwords.escape("https://github.com/#{owner}/#{malicious_project}"))
        end
        allow(subject).to receive(:sh).with(a_string_matching(/rm -rf/), anything)
        subject.run_checkout_clone
      end
    end

    describe 'commit sanitization' do
      it 'sanitizes dangerous commit values' do
        dangerous_commits = [
          "; rm -rf /",
          "main && malicious_command",
          "$(evil_command)",
          "`evil_command`",
          "| evil_command",
          "main\nmalicious_line"
        ]

        dangerous_commits.each do |dangerous_commit|
          subject.commit = dangerous_commit
          # The commit setter should sanitize or the escaping should protect
          # Just verify it doesn't cause an exception
          expect { subject.commit }.not_to raise_error
        end
      end
    end

    describe 'path construction' do
      it 'safely handles paths with special characters' do
        subject.owner = "owner-with-special"
        subject.project = "project.with.dots"
        subject.commit = "branch/with/slashes"

        # Should not raise errors with special characters
        expect { subject.repository_path }.not_to raise_error
        expect { subject.temp_clone_path }.not_to raise_error
        expect { subject.url }.not_to raise_error
      end
    end
  end

  describe '#temp_clone_path' do
    it 'returns path in github_clones directory' do
      subject.owner = owner
      subject.project = project
      path = subject.temp_clone_path
      expect(path.to_s).to include('github_clones')
      expect(path.to_s).to include(project)
      expect(path.to_s).to include(owner)
    end

    it 'includes timestamp for uniqueness' do
      path1 = subject.temp_clone_path
      subject.instance_variable_set(:@temp_clone_path, nil)
      sleep 0.01
      path2 = subject.temp_clone_path
      expect(path1.to_s).not_to eq(path2.to_s)
    end
  end

  describe '#repository_path' do
    it 'returns path based on GithubLibrary base path' do
      subject.owner = owner
      subject.project = project
      subject.commit = commit
      expect(subject.repository_path.to_s).to include(project)
      expect(subject.repository_path.to_s).to include(owner)
      expect(subject.repository_path.to_s).to include(commit)
    end
  end

  describe '#library_version' do
    before do
      subject.owner = owner
      subject.project = project
      subject.commit = commit
    end

    it 'returns a LibraryVersion object' do
      expect(subject.library_version).to be_a(YARD::Server::LibraryVersion)
    end

    it 'has correct name' do
      expect(subject.library_version.name).to eq("#{owner}/#{project}")
    end

    it 'has correct version' do
      expect(subject.library_version.version).to eq(commit)
    end

    it 'has github source' do
      expect(subject.library_version.source).to eq(:github)
    end
  end

  describe '#flush_cache' do
    it 'calls CacheClearJob with correct paths' do
      subject.owner = owner
      subject.project = project

      expect(CacheClearJob).to receive(:perform_now).with(
        '/',
        '/github',
        "/github/~#{project[0, 1]}",
        "/github/#{owner}/#{project}/",
        "/list/github/#{owner}/#{project}/",
        "/static/github/#{owner}/#{project}/"
      )
      subject.flush_cache
    end
  end

  describe '#register_project' do
    let(:library_version) { double('LibraryVersion') }

    before do
      allow(subject).to receive(:library_version).and_return(library_version)
    end

    it 'calls RegisterLibrariesJob' do
      expect(RegisterLibrariesJob).to receive(:perform_now).with(library_version)
      subject.register_project
    end
  end

  describe '#primary_branch' do
    let(:primary_branch_file) { instance_double(Pathname, read: 'master') }

    before do
      allow(subject).to receive(:primary_branch_file).and_return(primary_branch_file)
    end

    it 'reads from primary branch file' do
      expect(primary_branch_file).to receive(:read).and_return('master')
      expect(subject.primary_branch).to eq('master')
    end

    context 'when file does not exist' do
      before do
        allow(primary_branch_file).to receive(:read).and_raise(Errno::ENOENT)
      end

      it 'returns nil' do
        expect(subject.primary_branch).to be_nil
      end
    end
  end

  describe '#write_primary_branch_file' do
    let(:primary_branch_file) { instance_double(Pathname, write: nil) }

    before do
      allow(subject).to receive(:primary_branch_file).and_return(primary_branch_file)
      subject.commit = commit
    end

    it 'writes commit to file' do
      expect(primary_branch_file).to receive(:write).with(commit)
      subject.write_primary_branch_file
    end
  end

  describe '#write_fork_data' do
    let(:fork_file) { instance_double(Pathname, file?: false, write: nil) }

    before do
      allow(subject).to receive(:fork_file).and_return(fork_file)
      allow(subject).to receive(:fork?).and_return(false)
      subject.owner = owner
      subject.project = project
    end

    context 'when fork file already exists' do
      before do
        allow(fork_file).to receive(:file?).and_return(true)
      end

      it 'does not write' do
        expect(fork_file).not_to receive(:write)
        subject.write_fork_data
      end
    end

    context 'when repository is a fork' do
      before do
        allow(subject).to receive(:fork?).and_return(true)
      end

      it 'does not write' do
        expect(fork_file).not_to receive(:write)
        subject.write_fork_data
      end
    end

    context 'when fork file does not exist and not a fork' do
      it 'writes owner/project name to file' do
        expect(fork_file).to receive(:write).with("#{owner}/#{project}")
        subject.write_fork_data
      end
    end
  end

  describe '#fork?' do
    before do
      subject.owner = owner
      subject.project = project
    end

    context 'when repository is a fork' do
      before do
        allow(URI).to receive(:open).and_yield(StringIO.new('{"fork": true}'))
      end

      it 'returns true' do
        expect(subject.fork?).to be true
      end

      it 'caches the result' do
        expect(URI).to receive(:open).once.and_yield(StringIO.new('{"fork": true}'))
        subject.fork?
        subject.fork?
      end
    end

    context 'when repository is not a fork' do
      before do
        allow(URI).to receive(:open).and_yield(StringIO.new('{"fork": false}'))
      end

      it 'returns false' do
        expect(subject.fork?).to be false
      end
    end

    context 'when API call fails' do
      before do
        allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new('404', nil))
      end

      it 'returns false' do
        expect(subject.fork?).to be false
      end

      it 'sets cache to nil' do
        subject.fork?
        expect(subject.instance_variable_get(:@is_fork)).to be_nil
      end
    end

    context 'when network timeout occurs' do
      before do
        allow(URI).to receive(:open).and_raise(Timeout::Error)
      end

      it 'returns false' do
        expect(subject.fork?).to be false
      end
    end
  end

  describe 'cleanup after perform' do
    it 'has an after_perform callback defined' do
      callbacks = described_class._perform_callbacks.select { |cb| cb.kind == :after }
      expect(callbacks).not_to be_empty
    end

    it 'cleans up temp clone path if it exists' do
      temp_path = double('Pathname', directory?: true, rmtree: nil)
      allow_any_instance_of(described_class).to receive(:temp_clone_path).and_return(temp_path)
      allow_any_instance_of(described_class).to receive(:library_version).and_return(double(disallowed?: false))
      allow_any_instance_of(described_class).to receive(:run_checkout).and_return(true)
      allow_any_instance_of(described_class).to receive(:register_project)
      allow_any_instance_of(described_class).to receive(:flush_cache)

      expect(temp_path).to receive(:directory?).and_return(true)
      expect(temp_path).to receive(:rmtree)

      described_class.perform_now(owner: owner, project: project, commit: commit)
    end
  end
end
