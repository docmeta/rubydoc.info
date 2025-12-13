require 'rails_helper'

RSpec.describe DeleteDocsJob, type: :job do
  let(:library_version) do
    double('LibraryVersion',
      source_path: '/tmp/gems/rails/7.0.0',
      source: :remote_gem,
      name: 'rails',
      version: '7.0.0',
      to_s: 'rails-7.0.0'
    )
  end

  let(:library) do
    create(:gem, name: 'rails', versions: [ '7.0.0', '6.1.0' ])
  end

  describe '#perform' do
    before do
      allow(CleanupUnvisitedDocsJob).to receive(:should_invalidate?).and_return(true)
    end

    context 'when library version should be invalidated' do
      it 'removes the library version from database' do
        allow(Library).to receive(:where).and_return(double(first: library))
        allow(library).to receive(:versions).and_return([ '7.0.0', '6.1.0' ])
        allow(library).to receive(:save)
        allow(Pathname).to receive(:new).and_return(double(rmtree: nil))
        allow(CacheClearJob).to receive(:perform_later)

        expect(library.versions).to receive(:delete).with('7.0.0')

        subject.perform(library_version)
      end

      it 'removes the directory' do
        allow(Library).to receive(:where).and_return(double(first: library))
        allow(library).to receive(:versions).and_return([ '7.0.0' ])
        allow(library.versions).to receive(:delete)
        allow(library).to receive(:save)
        allow(CacheClearJob).to receive(:perform_later)

        path_double = double('Pathname')
        expect(Pathname).to receive(:new).with('/tmp/gems/rails/7.0.0').and_return(path_double)
        expect(path_double).to receive(:rmtree)

        subject.perform(library_version)
      end

      it 'queues cache clear job' do
        allow(Library).to receive(:where).and_return(double(first: library))
        allow(library).to receive(:versions).and_return([ '7.0.0' ])
        allow(library.versions).to receive(:delete)
        allow(library).to receive(:save)
        allow(Pathname).to receive(:new).and_return(double(rmtree: nil))

        expect(CacheClearJob).to receive(:perform_later).with(library_version)

        subject.perform(library_version)
      end

      context 'when it is the last version' do
        it 'destroys the library record' do
          library.versions = [ '7.0.0' ]
          allow(Library).to receive(:where).and_return(double(first: library))
          allow(library.versions).to receive(:delete)
          allow(library.versions).to receive(:empty?).and_return(true)
          allow(Pathname).to receive(:new).and_return(double(rmtree: nil))
          allow(CacheClearJob).to receive(:perform_later)

          expect(library).to receive(:destroy)

          subject.perform(library_version)
        end
      end

      context 'when there are other versions' do
        it 'keeps the library record and saves' do
          allow(Library).to receive(:where).and_return(double(first: library))
          allow(library).to receive(:versions).and_return([ '7.0.0', '6.1.0' ])
          allow(library.versions).to receive(:delete)
          allow(library.versions).to receive(:empty?).and_return(false)
          allow(Pathname).to receive(:new).and_return(double(rmtree: nil))
          allow(CacheClearJob).to receive(:perform_later)

          expect(library).to receive(:save)

          subject.perform(library_version)
        end
      end
    end

    context 'when library version should not be invalidated' do
      it 'does not remove anything' do
        allow(CleanupUnvisitedDocsJob).to receive(:should_invalidate?).and_return(false)

        expect(Library).not_to receive(:where)
        expect(Pathname).not_to receive(:new)

        subject.perform(library_version)
      end
    end

    context 'for GitHub library' do
      let(:github_version) do
        double('LibraryVersion',
          source_path: '/tmp/github/rails/rails/main',
          source: :github,
          name: 'rails/rails',
          version: 'main',
          to_s: 'rails/rails-main'
        )
      end

      it 'handles owner/name format' do
        allow(CleanupUnvisitedDocsJob).to receive(:should_invalidate?).and_return(true)
        github_lib = create(:github, name: 'rails', owner: 'rails', versions: [ 'main' ])
        allow(Library).to receive(:where).and_return(double(first: github_lib))
        allow(github_lib.versions).to receive(:delete)
        allow(github_lib).to receive(:save)
        allow(Pathname).to receive(:new).and_return(double(rmtree: nil))
        allow(CacheClearJob).to receive(:perform_later)

        expect { subject.perform(github_version) }.not_to raise_error
      end
    end
  end
end
