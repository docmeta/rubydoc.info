$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'scm_checkout'
require 'ostruct'

describe GithubCheckout do
  before do
    @settings = OpenStruct.new(:settings => OpenStruct.new(:repos => 'x'))
  end

  def git(url, commit = nil)
    @git = GithubCheckout.new(@settings, url, commit)
  end

  describe '#initialize' do
    %w(git http https).each do |scheme|
      it "should accept github URLs with #{scheme}://" do
        git("#{scheme}://github.com/lsegal/yard")
        expect(@git.username).to eq("lsegal")
        expect(@git.project).to eq("yard")
        expect(@git.name).to eq("lsegal/yard")
      end
    end

    it "should accept ssh style github urls" do
      git("git@github.com:reevoo/stratocumulus.git")
      @git.username.should == "reevoo"
      @git.project.should == "stratocumulus"
      @git.name.should == "reevoo/stratocumulus"
    end

    it "should accept github URLs with ending in .git" do
      git("git://github.com/lsegal/yard.git")
      expect(@git.username).to eq("lsegal")
      expect(@git.project).to eq("yard")
      expect(@git.name).to eq("lsegal/yard")
    end

    it "should sanitize project names" do
      git("git://github.com/foo!/bar!")
      expect(@git.name).to eq("foo_/bar_")
    end

    it "should sanitize SHA-1 commit" do
      @git = GithubCheckout.new(@settings, "git://github.com/lsegal/yard", "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      expect(@git.commit).to eq("a94a8f")
    end

    it "should use master as commit if not selected" do
      git("git://github.com/lsegal/yard")
      expect(@git.commit).to eq("master")
    end

    it "should throw InvalidSchemeError on non github URL" do
      %w( http:// git:// sgdfhij gi://github.com/lsegal/yard git://github.com
        git://github.com/lsegal/ ).each do |url|
          expect { GithubCheckout.new(@settings, url) }.to raise_error(InvalidSchemeError)
      end
    end
  end

  describe '#is_fork?' do
    it "should return false for master repo" do
      expect(File).to receive(:directory?).and_return(false)
      git("git://github.com/lsegal/yard")
      expect(@git).not_to be_fork
    end

    it "should return true for non-master repo" do
      expect(File).to receive(:directory?).and_return(false)
      git("git://github.com/lsegal/redcarpet")
      expect(@git).to be_fork
    end
  end
end
