require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'constants' do
    it 'defines LIBRARY_TYPES' do
      expect(ApplicationHelper::LIBRARY_TYPES).to be_a(Hash)
      expect(ApplicationHelper::LIBRARY_TYPES[:featured]).to eq("Gem")
      expect(ApplicationHelper::LIBRARY_TYPES[:stdlib]).to eq("Standard Library")
      expect(ApplicationHelper::LIBRARY_TYPES[:gems]).to eq("Gem")
      expect(ApplicationHelper::LIBRARY_TYPES[:github]).to eq("GitHub repository")
    end

    it 'defines LIBRARY_ALT_TYPES' do
      expect(ApplicationHelper::LIBRARY_ALT_TYPES).to be_a(Hash)
      expect(ApplicationHelper::LIBRARY_ALT_TYPES[:github]).to eq("GitHub Project")
    end

    it 'defines HAS_SEARCH' do
      expect(ApplicationHelper::HAS_SEARCH).to be_a(Set)
      expect(ApplicationHelper::HAS_SEARCH).to include('github', 'gems')
    end
  end

  describe '#nav_links' do
    it 'returns navigation links hash' do
      links = helper.nav_links
      expect(links).to be_a(Hash)
      expect(links.keys).to include("Featured", "Stdlib", "RubyGems", "GitHub")
    end

    it 'includes correct paths' do
      links = helper.nav_links
      expect(links["Featured"]).to eq(featured_index_path)
      expect(links["Stdlib"]).to eq(stdlib_index_path)
      expect(links["RubyGems"]).to eq(gems_path)
      expect(links["GitHub"]).to eq(github_index_path)
    end
  end

  describe '#settings' do
    it 'returns Rubydoc config' do
      expect(helper.settings).to eq(Rubydoc.config)
    end
  end

  describe '#page_title' do
    it 'combines settings name and title content' do
      allow(Rubydoc.config).to receive(:name).and_return('RubyDoc.info')
      assign(:page_title, 'Test Page')
      expect(helper.page_title).to eq('RubyDoc.info: Test Page')
    end
  end

  describe '#title_content' do
    it 'returns page_title instance variable if set' do
      assign(:page_title, 'Custom Title')
      expect(helper.title_content).to eq('Custom Title')
    end

    it 'falls back to page_description' do
      assign(:page_description, 'Custom Description')
      expect(helper.title_content).to eq('Custom Description')
    end
  end

  describe '#page_description' do
    it 'returns page_description instance variable if set' do
      assign(:page_description, 'Custom Description')
      expect(helper.page_description).to eq('Custom Description')
    end

    it 'falls back to settings description' do
      allow(Rubydoc.config).to receive(:description).and_return('Default Description')
      expect(helper.page_description).to eq('Default Description')
    end
  end

  describe '#link_to_library' do
    let(:gem_library) { create(:gem, name: 'rails') }
    let(:github_library) { create(:github, name: 'rails', owner: 'rails') }

    it 'creates link for gem library' do
      link = helper.link_to_library(gem_library)
      expect(link).to include('href="#/gems/rails"')
      expect(link).to include('rails')
    end

    it 'creates link with version' do
      link = helper.link_to_library(gem_library, '7.0.0')
      expect(link).to include('href="#/gems/rails/7.0.0"')
      expect(link).to include('7.0.0')
    end

    it 'creates link for github library' do
      link = helper.link_to_library(github_library)
      expect(link).to include('href="#/github/rails/rails"')
    end

    it 'creates link for featured library' do
      featured_library = create(:featured, name: 'yard')
      link = helper.link_to_library(featured_library)
      expect(link).to include('href="#/docs/yard"')
    end
  end

  describe '#library_name' do
    it 'returns name param if present' do
      allow(helper).to receive(:params).and_return({ name: 'rails' })
      expect(helper.library_name).to eq('rails')
    end

    it 'joins username and project params' do
      allow(helper).to receive(:params).and_return({ username: 'rails', project: 'rails' })
      expect(helper.library_name).to eq('rails/rails')
    end
  end

  describe '#library_type' do
    it 'returns library type for action' do
      allow(helper).to receive(:action_name).and_return('github')
      expect(helper.library_type).to eq("GitHub repository")
    end
  end

  describe '#library_type_alt' do
    it 'returns alternative library type for action' do
      allow(helper).to receive(:action_name).and_return('github')
      expect(helper.library_type_alt).to eq("GitHub Project")
    end
  end

  describe '#has_search?' do
    it 'returns true for github controller' do
      allow(helper).to receive(:controller_name).and_return('github')
      expect(helper.has_search?).to be true
    end

    it 'returns true for gems controller' do
      allow(helper).to receive(:controller_name).and_return('gems')
      expect(helper.has_search?).to be true
    end

    it 'returns false for other controllers' do
      allow(helper).to receive(:controller_name).and_return('stdlib')
      expect(helper.has_search?).to be false
    end
  end

  describe '#sorted_versions' do
    it 'returns sorted versions' do
      library = create(:gem, name: 'rails', versions: [ '7.0.0', '6.1.0', '5.2.0' ])
      versions = helper.sorted_versions(library)
      expect(versions).to eq([ '7.0.0', '6.1.0', '5.2.0' ])
    end
  end

  describe '#has_featured?' do
    context 'when featured libraries are configured' do
      with_rubydoc_config(libraries: { featured: { rails: 'gem' } }) do
        it 'returns true' do
          expect(helper.has_featured?).to be true
        end
      end
    end

    context 'when no featured libraries are configured' do
      with_rubydoc_config(libraries: { featured: {} }) do
        it 'returns false' do
          expect(helper.has_featured?).to be false
        end
      end
    end
  end

  describe '#featured_libraries' do
    context 'when no featured libraries configured' do
      with_rubydoc_config(libraries: { featured: {} }) do
        it 'returns empty array' do
          expect(helper.featured_libraries).to eq([])
        end
      end
    end

    context 'when featured gems are configured' do
      with_rubydoc_config(libraries: { featured: { rails: 'gem', rspec: 'gem' } }) do
        before do
          create(:gem, name: 'rails', versions: [ '7.0.0' ])
          create(:gem, name: 'rspec', versions: [ '3.12.0' ])
        end

        it 'returns featured gem libraries' do
          libraries = helper.featured_libraries
          expect(libraries.size).to eq(2)
          expect(libraries.map(&:name)).to contain_exactly('rails', 'rspec')
        end

        it 'loads libraries in batch to avoid N+1' do
          expect(Library).to receive(:gem).once.and_call_original
          helper.featured_libraries
        end
      end
    end
  end
end
