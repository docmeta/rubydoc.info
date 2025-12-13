require 'rails_helper'

RSpec.describe GithubProject, type: :model do
  describe 'validations' do
    it 'validates url format' do
      project = GithubProject.new(url: 'https://github.com/rails/rails')
      expect(project).to be_valid

      project.url = 'https://example.com/rails/rails'
      expect(project).not_to be_valid
      expect(project.errors[:url]).to be_present

      project.url = 'not a url'
      expect(project).not_to be_valid
    end

    it 'accepts valid GitHub URLs' do
      valid_urls = [
        'https://github.com/rails/rails',
        'https://github.com/ruby/ruby',
        'https://github.com/user-name/repo.name',
        'https://github.com/user_name/repo_name',
        'https://github.com/123/456'
      ]

      valid_urls.each do |url|
        project = GithubProject.new(url: url)
        expect(project).to be_valid, "Expected #{url} to be valid"
      end
    end

    it 'validates commit format' do
      project = GithubProject.new(url: 'https://github.com/rails/rails', commit: 'abc123')
      expect(project).to be_valid

      project.commit = '1234567890abcdef'
      expect(project).to be_valid

      project.commit = ''
      expect(project).to be_valid

      project.commit = 'invalid commit!'
      expect(project).not_to be_valid
      expect(project.errors[:commit]).to be_present
    end

    it 'allows blank commit' do
      project = GithubProject.new(url: 'https://github.com/rails/rails')
      expect(project).to be_valid
    end
  end

  describe '#owner' do
    it 'extracts owner from URL' do
      project = GithubProject.new(url: 'https://github.com/rails/rails')
      expect(project.owner).to eq('rails')
    end
  end

  describe '#name' do
    it 'extracts name from URL' do
      project = GithubProject.new(url: 'https://github.com/rails/rails')
      expect(project.name).to eq('rails')
    end
  end

  describe '#path' do
    it 'returns path components as array' do
      project = GithubProject.new(url: 'https://github.com/rails/rails')
      expect(project.path).to eq([ 'rails', 'rails' ])
    end

    it 'handles different URL formats' do
      project = GithubProject.new(url: 'https://github.com/ruby/ruby')
      expect(project.path).to eq([ 'ruby', 'ruby' ])
    end
  end
end
