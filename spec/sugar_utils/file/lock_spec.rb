# frozen_string_literal: true

require 'spec_helper'

describe SugarUtils::File::Lock do
  describe '.flock_shared' do
    subject { described_class.flock_shared(file, options) }

    let(:file) { instance_double(File) }

    before do
      allow(Timeout).to receive(:timeout).with(expected_timeout).and_yield
      expect(file).to receive(:flock).with(::File::LOCK_SH)
    end

    inputs            :options,           :expected_timeout
    side_effects_with Hash[],             10
    side_effects_with Hash[timeout: nil], 10
    side_effects_with Hash[timeout: 5],   5
  end

  describe '.flock_exclusive' do
    subject { described_class.flock_exclusive(file, options) }

    let(:file) { instance_double(File) }

    before do
      allow(Timeout).to receive(:timeout).with(expected_timeout).and_yield
      expect(file).to receive(:flock).with(::File::LOCK_EX)
    end

    inputs            :options,           :expected_timeout
    side_effects_with Hash[],             10
    side_effects_with Hash[timeout: nil], 10
    side_effects_with Hash[timeout: 5],   5
  end
end
