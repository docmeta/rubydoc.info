require 'rails_helper'

RSpec.describe Library, type: :model do
  describe 'enums' do
    it 'defines source enum' do
      expect(Library.sources).to eq('remote_gem' => 'remote_gem', 'github' => 'github', 'stdlib' => 'stdlib', 'featured' => 'featured')
    end
  end

  describe 'scopes' do
    before do
      @gem1 = create(:gem, name: 'activerecord')
      @gem2 = create(:gem, name: 'rails')
      @github1 = create(:github, name: 'rails', owner: 'rails')
      @stdlib1 = create(:stdlib, name: 'json')
    end

    describe '.gem' do
      it 'returns only gems' do
        expect(Library.gem).to contain_exactly(@gem1, @gem2)
      end
    end

    describe '.github' do
      it 'returns only github libraries' do
        expect(Library.github).to contain_exactly(@github1)
      end
    end

    describe '.stdlib' do
      it 'returns only stdlib libraries' do
        expect(Library.stdlib).to contain_exactly(@stdlib1)
      end
    end

    describe '.allowed_gem' do
      context 'when no disallowed gems configured' do
        it 'returns all gems' do
          expect(Library.allowed_gem).to contain_exactly(@gem1, @gem2)
        end
      end

      context 'when disallowed gems are configured' do
        with_rubydoc_config(libraries: { disallowed_gems: ['rails*'] }) do
          it 'excludes disallowed gems' do
            expect(Library.allowed_gem).to contain_exactly(@gem1)
          end
        end
      end
    end

    describe '.allowed_github' do
      context 'when no disallowed projects configured' do
        it 'returns all github projects' do
          expect(Library.allowed_github).to contain_exactly(@github1)
        end
      end

      context 'when disallowed projects are configured' do
        with_rubydoc_config(libraries: { disallowed_projects: ['rails/*'] }) do
          it 'excludes disallowed projects' do
            expect(Library.allowed_github).to be_empty
          end
        end
      end
    end
  end

  describe '.wildcard' do
    it 'converts asterisks to SQL wildcards' do
      expect(Library.wildcard(['rails*', '*gem*'])).to eq(['rails%', '%gem%'])
    end
  end

  describe '#name' do
    context 'for github source' do
      it 'returns owner/name format' do
        library = create(:github, name: 'rails', owner: 'rails')
        expect(library.name).to eq('rails/rails')
      end
    end

    context 'for non-github source' do
      it 'returns the name' do
        library = create(:gem, name: 'rails')
        expect(library.name).to eq('rails')
      end
    end
  end

  describe '#project' do
    it 'returns the name attribute' do
      library = create(:github, name: 'rails', owner: 'rails')
      expect(library.project).to eq('rails')
    end
  end

  describe '#source' do
    it 'returns source as a symbol' do
      library = create(:gem)
      expect(library.source).to eq(:remote_gem)
      expect(library.source).to be_a(Symbol)
    end
  end

  describe '#library_versions' do
    context 'for gem library' do
      it 'returns library versions' do
        library = create(:gem, name: 'rails', versions: ['7.0.0', '6.1.0', '5.2.0'])
        versions = library.library_versions

        expect(versions.size).to eq(3)
        expect(versions.first).to be_a(YARD::Server::LibraryVersion)
        expect(versions.map(&:version)).to eq(['7.0.0', '6.1.0', '5.2.0'])
      end
    end

    context 'for github library' do
      it 'returns library versions' do
        library = create(:github, name: 'rails', owner: 'rails', versions: ['main', 'develop'])
        versions = library.library_versions

        expect(versions.size).to eq(2)
        expect(versions.first).to be_a(YARD::Server::LibraryVersion)
      end
    end

    it 'caches the result' do
      library = create(:gem, name: 'rails', versions: ['7.0.0'])
      first_call = library.library_versions
      second_call = library.library_versions

      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end
end
