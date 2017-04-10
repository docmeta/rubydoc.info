$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'scm_checkout'
require 'ostruct'

describe GitlabCheckout do
  before do
    @settings = OpenStruct.new(:settings => OpenStruct.new(:repos => 'x'))
  end

  def git(url, commit = nil)
    @git = GitlabCheckout.new(@settings, url, commit)
  end

  describe '#initialize' do
    %w(git http https).each do |scheme|
      it "should accept github URLs with #{scheme}://" do
        git("#{scheme}://gitlab.com/gitlab-org/gitlab-ce")
        expect(@git.username).to eq("gitlab-org")
        expect(@git.project).to eq("gitlab-ce")
        expect(@git.name).to eq("gitlab-org/gitlab-ce")
      end
    end

    it "should accept gitlab URLs with ending in .git" do
      git("git://gitlab.com/gitlab-org/gitlab-ce.git")
      expect(@git.username).to eq("gitlab-org")
      expect(@git.project).to eq("gitlab-ce")
      expect(@git.name).to eq("gitlab-org/gitlab-ce")
    end

    it "should sanitize project names" do
      git("git://gitlab.com/foo!/bar!")
      expect(@git.name).to eq("foo_/bar_")
    end

    it "should sanitize SHA-1 commit" do
      @git = GitlabCheckout.new(@settings, "git://gitlab.com/gitlab-org/gitlab-ce", "ad27f20426975cf515fd55e4b5b75e5d4703315c")
      expect(@git.commit).to eq("ad27f2")
    end

    it "should use master as commit if not selected" do
      git("git://gitlab.com/gitlab-org/gitlab-ce")
      expect(@git.commit).to eq("master")
    end

    it "should throw InvalidSchemeError on non gitlab URL" do
      %w( http:// git:// sgdfhij gi://gitlab.com/gitlab-org/gitlab-ce git://gitlab.com
        git://gitlab.com/gitlab-org/ ).each do |url|
          expect { GitlabCheckout.new(@settings, url) }.to raise_error(InvalidSchemeError)
      end
    end
  end

  describe '#is_fork?' do
    it "should return false for master repo" do
      expect(File).to receive(:directory?).and_return(false)
      git("git://gitlab.com/gitlab-org/gitlab-ce")
      expect(@git).not_to be_fork
    end

    it "should return true for non-master repo" do
      expect(File).to receive(:directory?).and_return(false)
      git("git://gitlab.com/marin/gitlab-test")
      expect(@git).to be_fork
    end
  end
end
