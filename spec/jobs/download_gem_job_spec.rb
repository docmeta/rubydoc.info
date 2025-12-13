require 'rails_helper'

RSpec.describe DownloadGemJob, type: :job do
  let(:library_version) do
    double('LibraryVersion',
      disallowed?: false,
      ready?: false,
      to_s: 'rails-7.0.0',
      platform: nil,
      source_path: '/tmp/gems/rails/7.0.0',
      source: :remote_gem,
      name: 'rails'
    )
  end

  describe '#perform' do
    before do
      allow(FileUtils).to receive(:rm_rf)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:rmdir)
    end

    context 'when library version is ready' do
      it 'skips download' do
        allow(library_version).to receive(:ready?).and_return(true)
        expect(URI).not_to receive(:open)

        subject.perform(library_version)
      end
    end

    context 'when library version is not ready' do
      it 'prepares directory structure' do
        expect(FileUtils).to receive(:rm_rf).with('/tmp/gems/rails/7.0.0')
        expect(FileUtils).to receive(:mkdir_p).with('/tmp/gems/rails/7.0.0')

        allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new('404', nil))
        subject.perform(library_version)
      end

      it 'constructs correct gem URL' do
        expected_url = 'http://rubygems.org/gems/rails-7.0.0.gem'
        expect(URI).to receive(:open).with(expected_url)

        allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new('404', nil))
        subject.perform(library_version)
      end

      context 'with platform specified' do
        before do
          allow(library_version).to receive(:platform).and_return('ruby')
        end

        it 'includes platform in URL' do
          expected_url = 'http://rubygems.org/gems/rails-7.0.0-ruby.gem'
          expect(URI).to receive(:open).with(expected_url)

          allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new('404', nil))
          subject.perform(library_version)
        end
      end

      context 'with custom gem source' do
        with_rubydoc_config(gem_source: 'https://custom.gems.org/') do
          it 'uses custom gem source' do
            expected_url = 'https://custom.gems.org/gems/rails-7.0.0.gem'
            expect(URI).to receive(:open).with(expected_url)

            allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new('404', nil))
            subject.perform(library_version)
          end
        end
      end

      context 'when download fails' do
        it 'removes directory and logs warning' do
          allow(URI).to receive(:open).and_raise(OpenURI::HTTPError.new('404 Not Found', nil))
          expect(FileUtils).to receive(:rmdir).with('/tmp/gems/rails/7.0.0')

          subject.perform(library_version)
        end
      end
    end
  end

  describe '#expand_gem' do
    let(:io) { double('IO') }

    it 'expands gem data archive' do
      expect(Gem::Package::TarReader).to receive(:new).with(io)

      allow(Gem::Package::TarReader).to receive(:new).and_return([])
      subject.expand_gem(io, library_version)
    end
  end
end
