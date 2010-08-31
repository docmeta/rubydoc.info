$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'scm_checkout'

describe GithubCheckout do
  before do
    @options = OpenStruct.new(:options => OpenStruct.new(:repos => 'x'))
  end
    
  def git(url, commit = nil)
    @git = GithubCheckout.new(@options, url, commit)
  end
  
  describe '#initialize' do
    %w(git http https).each do |scheme|
      it "should accept github URLs with #{scheme}://" do
        git("#{scheme}://github.com/lsegal/yard")
        @git.username.should == "lsegal"
        @git.project.should == "yard"
        @git.name.should == "lsegal/yard"
      end
    end

    it "should accept github URLs with ending in .git" do
      git("git://github.com/lsegal/yard.git")
      @git.username.should == "lsegal"
      @git.project.should == "yard"
      @git.name.should == "lsegal/yard"
    end
    
    it "should sanitize project names" do
      git("git://github.com/foo!/bar!")
      @git.name.should == "foo_/bar_"
    end
    
    it "should sanitize SHA-1 commit" do
      @git = GithubCheckout.new(@options, "git://github.com/lsegal/yard", "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
      @git.commit.should == "a94a8f"
    end
    
    it "should use master as commit if not selected" do
      git("git://github.com/lsegal/yard")
      @git.commit.should == "master"
    end

    it "should throw InvalidSchemeError on non github URL" do
      %w( http:// git:// sgdfhij gi://github.com/lsegal/yard git://github.com 
        git://github.com/lsegal/ ).each do |url|
          lambda { GithubCheckout.new(@options, url) }.should raise_error(InvalidSchemeError)
      end
    end
  end
  
  describe '#is_fork?' do
    it "should return false for master repo" do
      File.should_receive(:directory?).and_return(false)
      git("git://github.com/lsegal/yard")
      @git.should_not be_fork
    end 

    it "should return true for non-master repo" do
      File.should_receive(:directory?).and_return(false)
      git("git://github.com/lsegal/rails")
      @git.should be_fork
    end 
  end
end