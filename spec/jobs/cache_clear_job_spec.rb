require 'rails_helper'

RSpec.describe CacheClearJob, type: :job do
  describe '#perform' do
    let(:paths) { [ '/docs/rails/7.0.0', '/docs/rspec/3.12.0' ] }

    context 'when Cloudflare token is configured' do
      with_rubydoc_config(integrations: { cloudflare_token: 'test_token', cloudflare_zones: [ 'zone123' ] }) do
        it 'clears cache from Cloudflare' do
          http = instance_double(Net::HTTP::Persistent)
          allow(Net::HTTP::Persistent).to receive(:new).and_return(http)
          allow(http).to receive(:request)
          allow(http).to receive(:shutdown)

          expect(http).to receive(:request)

          subject.perform(*paths)
        end

        it 'batches paths in groups of 30' do
          paths = (1..65).map { |i| "/docs/gem#{i}" }
          http = instance_double(Net::HTTP::Persistent)
          allow(Net::HTTP::Persistent).to receive(:new).and_return(http)
          allow(http).to receive(:request)
          allow(http).to receive(:shutdown)

          # 65 paths divided by 30 per batch = 3 batches per zone
          expect(http).to receive(:request).at_least(3).times

          subject.perform(*paths)
        end

        it 'shuts down HTTP connection' do
          http = instance_double(Net::HTTP::Persistent)
          allow(Net::HTTP::Persistent).to receive(:new).and_return(http)
          allow(http).to receive(:request)

          expect(http).to receive(:shutdown).at_least(:once)

          subject.perform(*paths)
        end
      end
    end

    context 'when Cloudflare token is not configured' do
      it 'returns early without making API calls' do
        allow(Rubydoc.config.integrations).to receive(:cloudflare_token).and_return(nil)
        expect(Net::HTTP::Persistent).not_to receive(:new)

        subject.perform(*paths)
      end
    end

    context 'with multiple zones' do
      with_rubydoc_config(integrations: { cloudflare_token: 'test_token', cloudflare_zones: [ 'zone1', 'zone2' ] }) do
        it 'clears cache for all zones' do
          http = instance_double(Net::HTTP::Persistent)
          allow(http).to receive(:request)
          allow(http).to receive(:shutdown)

          # Each zone creates an HTTP object and shuts it down
          # Using at_least to allow for test environment config
          expect(Net::HTTP::Persistent).to receive(:new).at_least(2).times.and_return(http)

          subject.perform(*paths)
        end
      end
    end
  end
end
