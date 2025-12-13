require 'rails_helper'

RSpec.describe ShellHelper, type: :helper do
  describe '#sh' do
    context 'with successful command' do
      it 'executes the command and returns result' do
        result = helper.sh('echo "test"', raise_error: true)
        expect(result).to be_success
      end

      it 'logs the command and result' do
        expect(Rails.logger).to receive(:info).at_least(:once)
        helper.sh('echo "test"', raise_error: true)
      end

      it 'uses custom title if provided' do
        expect(Rails.logger).to receive(:info).at_least(:once).with(a_string_matching(/Custom Title/))
        helper.sh('echo "test"', title: 'Custom Title', raise_error: true)
      end
    end

    context 'with failing command' do
      it 'raises IOError when raise_error is true' do
        expect {
          helper.sh('exit 1', raise_error: true)
        }.to raise_error(IOError, /Error executing command/)
      end

      it 'does not raise error when raise_error is false' do
        expect {
          helper.sh('exit 1', raise_error: false)
        }.not_to raise_error
      end

      it 'logs error details' do
        expect(Rails.logger).to receive(:error).with(a_string_matching(/STDERR/))
        expect {
          helper.sh('exit 1', raise_error: true)
        }.to raise_error(IOError)
      end
    end

    context 'with show_output option' do
      it 'prints output when show_output is true' do
        expect {
          helper.sh('echo "visible"', show_output: true, raise_error: true)
        }.to output(/visible/).to_stdout
      end
    end

    context 'command output capture' do
      it 'captures stdout and stderr' do
        expect {
          helper.sh('echo "stdout"; echo "stderr" >&2', raise_error: true)
        }.not_to raise_error
      end
    end
  end
end
