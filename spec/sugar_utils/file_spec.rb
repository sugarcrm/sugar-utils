# frozen_string_literal: true

require 'spec_helper'

describe SugarUtils::File do
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

  describe '.change_access', :fakefs do
    subject do
      described_class.change_access(filename, owner, group, permission)
    end

    let(:filename) { 'filename' }

    context 'when file does not exist' do
      let(:owner)      { 'nobody' }
      let(:group)      { 'nogroup' }
      let(:permission) { 0o777 }

      it { expect_raise_error("Unable to change access on #{filename}") }
    end

    context 'when file exists' do
      before { write(filename, 'foobar') }

      context 'with no values specified' do # rubocop:disable RSpec/NestedGroups
        let(:owner)      { nil }
        let(:group)      { nil }
        let(:permission) { nil }

        it { expect_not_to_raise_error }
        its_side_effects_are do
          expect(filename).not_to have_owner('nobody')
          expect(filename).not_to have_group('nogroup')
          expect(filename).not_to have_file_permission(0o100777)
        end
      end

      context 'with all values(Integer) specified' do # rubocop:disable RSpec/NestedGroups
        let(:owner)      { Etc.getpwnam('nobody').uid }
        let(:group)      { Etc.getgrnam('nogroup').gid }
        let(:permission) { 0o777 }

        it { expect_not_to_raise_error }
        its_side_effects_are do
          expect(filename).to have_owner('nobody')
          expect(filename).to have_group('nogroup')
          expect(filename).to have_file_permission(0o100777)
        end
      end

      context 'with all values specified' do # rubocop:disable RSpec/NestedGroups
        let(:owner)      { 'nobody' }
        let(:group)      { 'nogroup' }
        let(:permission) { 0o777 }

        it { expect_not_to_raise_error }
        its_side_effects_are do
          expect(filename).to have_owner('nobody')
          expect(filename).to have_group('nogroup')
          expect(filename).to have_file_permission(0o100777)
        end
      end
    end
  end

  describe '.read', :fakefs do
    subject { described_class.read('filename', options) }

    shared_examples_for 'handles the missing file error' do
      inputs           :options
      raise_error_with Hash[],                                                described_class::Error
      raise_error_with Hash[],                                                'Cannot read filename'
      raise_error_with Hash[raise_on_missing: true],                          described_class::Error
      raise_error_with Hash[raise_on_missing: true],                          'Cannot read filename'
      it_with          Hash[raise_on_missing: false],                         ''
      it_with          Hash[raise_on_missing: false, value_on_missing: 'hi'], 'hi'
    end

    context 'when missing file' do
      it_behaves_like 'handles the missing file error'
    end

    context 'with IOError' do
      before { allow(File).to receive(:open).and_raise(IOError) }

      it_behaves_like 'handles the missing file error'
    end

    context 'when file present' do
      before { write('filename', 'foobar') }

      # rubocop:disable RSpec/NestedGroups
      context 'when locked' do
        let(:options) { { key: :value } }

        before do
          expect(described_class).to receive(:flock_shared)
            .with(kind_of(File), options)
            .and_raise(Timeout::Error)
        end

        it { expect_raise_error('Cannot read filename because it is locked') }
      end

      context 'when unlocked' do
        let(:options) { { key: :value, scrub_encoding: scrub_encoding } }

        before do
          expect(described_class).to receive(:flock_shared)
            .with(kind_of(File), options)
          allow(SugarUtils).to receive(:scrub_encoding)
            .with('foobar', scrub_encoding)
            .and_return(:scrubbed_data)
        end

        inputs  :scrub_encoding
        it_with nil,             'foobar'
        it_with false,           'foobar'
        it_with :scrub_encoding, :scrubbed_data
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe '.read_json', :fakefs do
    subject do
      described_class.read_json(
        :filename, key: :value, value_on_missing: :foobar
      )
    end

    before do
      allow(described_class).to receive(:read)
        .with(:filename, key: :value, value_on_missing: :missing)
        .and_return(file_content)
    end

    inputs           :file_content
    raise_error_with 'I am not json',                described_class::Error
    raise_error_with 'I am not json',                'Cannot parse filename'
    it_with          :missing,                       Hash[]
    it_with          Hash['key' => 'value'].to_json, Hash['key' => 'value']
  end

  describe '.touch', :fakefs do
    subject { described_class.touch(filename, *options) }

    let(:filename) { 'path1/path2/filename' }

    context 'without options' do
      let(:options) { [] }

      it { expect_not_to_raise_error }
      its_side_effects_are { expect(File.exist?(filename)).to eq(true) }
    end

    context 'with options, and :mode key' do
      let(:options) { [{ owner: 'nobody', group: 'nogroup', mode: 0o600, mtime: 0 }] }

      it { expect_not_to_raise_error }
      its_side_effects_are do
        expect(filename).to have_owner('nobody')
        expect(filename).to have_group('nogroup')
        expect(filename).to have_file_permission(0o100600)
        expect(filename).to have_mtime(0)
      end
    end

    context 'with options, and :perm key' do
      let(:options) { [{ owner: 'nobody', group: 'nogroup', perm: 0o600, mtime: 0 }] }

      it { expect_not_to_raise_error }
      its_side_effects_are do
        expect(filename).to have_owner('nobody')
        expect(filename).to have_group('nogroup')
        expect(filename).to have_file_permission(0o100600)
        expect(filename).to have_mtime(0)
      end
    end
  end

  describe '.write', :fakefs do
    subject { described_class.write(filename, data, options) }

    let(:data)      { 'content' }
    let(:filename)  { 'dir1/dir2/filename' }

    context 'when SystemCallError' do
      let(:options) { {} }
      let(:exception) { SystemCallError.new(nil) }

      before { allow(File).to receive(:open).and_raise(exception) }

      it { expect_raise_error("Unable to write #{filename} with #{exception}") }
    end

    context 'when IOError' do
      let(:options) { {} }
      let(:exception) { IOError.new(nil) }

      before { allow(File).to receive(:open).and_raise(exception) }

      it { expect_raise_error("Unable to write #{filename} with #{exception}") }
    end

    context 'when locked' do
      let(:options) { {} }

      before do
        expect(described_class).to receive(:flock_exclusive)
          .with(kind_of(File), options)
          .and_raise(Timeout::Error)
      end

      it { expect_raise_error("Unable to write #{filename} because it is locked") }
    end

    shared_examples_for 'file is correctly written' do
      before do
        expect(described_class).to receive(:flock_exclusive)
          .with(kind_of(File), options)
      end

      # rubocop:disable RSpec/NestedGroups
      context 'without options' do
        let(:options) { {} }

        it { expect_not_to_raise_error }
        its_side_effects_are do
          expect(filename).to have_content(data)
          expect(filename).to have_file_permission(0o100644)
        end
      end

      context 'with options' do
        let(:options) do
          { flush: true, owner: 'nobody', group: 'nogroup', mode_or_perm_key => 0o600 }
        end

        before do
          # rubocop:disable RSpec/AnyInstance
          expect_any_instance_of(File).to receive(:flush)
          expect_any_instance_of(File).to receive(:fsync)
          # rubocop:enable RSpec/AnyInstance
        end

        context 'with mode key' do
          let(:mode_or_perm_key) { :mode }

          it { expect_not_to_raise_error }
          its_side_effects_are do
            expect(filename).to have_content(data)
            expect(filename).to have_owner('nobody')
            expect(filename).to have_group('nogroup')
            expect(filename).to have_file_permission(0o100600)
          end
        end

        context 'with perm key' do
          let(:mode_or_perm_key) { :perm }

          it { expect_not_to_raise_error }
          its_side_effects_are do
            expect(filename).to have_content(data)
            expect(filename).to have_owner('nobody')
            expect(filename).to have_group('nogroup')
            expect(filename).to have_file_permission(0o100600)
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when file does not exist' do
      it_behaves_like 'file is correctly written'
    end

    context 'when file exists' do
      before { write(filename, 'foobar', 0o777) }

      it_behaves_like 'file is correctly written'
    end
  end

  describe '.atomic_write', :fakefs do
    subject { described_class.atomic_write(filename, data, options) }

    let(:data)      { 'content' }
    let(:filename)  { 'dir1/dir2/filename' }

    context 'when SystemCallError' do
      let(:options) { {} }
      let(:exception) { SystemCallError.new(nil) }

      before { allow(File).to receive(:open).and_raise(exception) }

      it { expect_raise_error("Unable to write #{filename} with #{exception}") }
    end

    context 'when IOError' do
      let(:options) { {} }
      let(:exception) { IOError.new(nil) }

      before { allow(File).to receive(:open).and_raise(exception) }

      it { expect_raise_error("Unable to write #{filename} with #{exception}") }
    end

    context 'when locked' do
      let(:options) { {} }

      before do
        expect(described_class).to receive(:flock_exclusive)
          .with(kind_of(File), options)
          .and_raise(Timeout::Error)
      end

      it { expect_raise_error("Unable to write #{filename} because it is locked") }
    end

    shared_examples_for 'file is correctly written' do
      before do
        expect(described_class).to receive(:flock_exclusive)
          .with(kind_of(File), options)
      end

      # rubocop:disable RSpec/NestedGroups
      context 'without options' do
        let(:options) { {} }

        it { expect_not_to_raise_error }
        its_side_effects_are do
          expect(filename).to have_content(data)
          expect(filename).to have_file_permission(0o100644)
        end
      end

      context 'with options' do
        let(:options) do
          { flush: true, owner: 'nobody', group: 'nogroup', mode_or_perm_key => 0o600 }
        end

        before do
          # rubocop:disable RSpec/AnyInstance
          expect_any_instance_of(File).to receive(:flush).at_least(:once)
          expect_any_instance_of(File).to receive(:fsync).at_least(:once)
          # rubocop:enable RSpec/AnyInstance
        end

        context 'with mode key' do
          let(:mode_or_perm_key) { :mode }

          it { expect_not_to_raise_error }
          its_side_effects_are do
            expect(filename).to have_content(data)
            expect(filename).to have_owner('nobody')
            expect(filename).to have_group('nogroup')
            expect(filename).to have_file_permission(0o100600)
          end
        end

        context 'with perm key' do
          let(:mode_or_perm_key) { :perm }

          it { expect_not_to_raise_error }
          its_side_effects_are do
            expect(filename).to have_content(data)
            expect(filename).to have_owner('nobody')
            expect(filename).to have_group('nogroup')
            expect(filename).to have_file_permission(0o100600)
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when file does not exist' do
      it_behaves_like 'file is correctly written'
    end

    context 'when file exists' do
      before { write(filename, 'foobar', 0o777) }

      it_behaves_like 'file is correctly written'
    end
  end

  describe '.write_json', :fakefs do
    subject { described_class.write_json(:filename, data, :options) }

    let(:data) { { 'key' => 'value' } }

    before do
      expect(described_class).to receive(:atomic_write).with(
        :filename, MultiJson.dump(data, pretty: true), :options
      )
    end

    it_has_side_effects
  end

  describe '.append', :fakefs do
    subject { described_class.append(filename, data, options) }

    let(:data)      { 'content' }
    let(:filename)  { 'dir1/dir2/filename' }

    context 'when SystemCallError' do
      let(:options) { {} }
      let(:exception) { SystemCallError.new(nil) }

      before { allow(File).to receive(:open).and_raise(exception) }

      it { expect_raise_error("Unable to write #{filename} with #{exception}") }
    end

    context 'when IOError' do
      let(:options) { {} }
      let(:exception) { IOError.new(nil) }

      before { allow(File).to receive(:open).and_raise(exception) }

      it { expect_raise_error("Unable to write #{filename} with #{exception}") }
    end

    context 'when locked' do
      let(:options) { {} }

      before do
        expect(described_class).to receive(:flock_exclusive)
          .with(kind_of(File), options)
          .and_raise(Timeout::Error)
      end

      it { expect_raise_error("Unable to write #{filename} because it is locked") }
    end

    shared_examples_for 'file is correctly appended' do
      before do
        expect(described_class).to receive(:flock_exclusive)
          .with(kind_of(File), options)
      end

      # rubocop:disable RSpec/NestedGroups
      context 'without options' do
        let(:options) { {} }

        it { expect_not_to_raise_error }
        its_side_effects_are do
          expect(filename).to have_content(expected_file_data)
          expect(filename).to have_file_permission(0o100644)
        end
      end

      context 'with options' do
        let(:options) do
          { flush: true, owner: 'nobody', group: 'nogroup', mode_or_perm_key => 0o600 }
        end

        before do
          # rubocop:disable RSpec/AnyInstance
          expect_any_instance_of(File).to receive(:flush)
          expect_any_instance_of(File).to receive(:fsync)
          # rubocop:enable RSpec/AnyInstance
        end

        context 'with mode key' do
          let(:mode_or_perm_key) { :mode }

          it { expect_not_to_raise_error }
          its_side_effects_are do
            expect(filename).to have_content(expected_file_data)
            expect(filename).to have_owner('nobody')
            expect(filename).to have_group('nogroup')
            expect(filename).to have_file_permission(0o100600)
          end
        end

        context 'with perm key' do
          let(:mode_or_perm_key) { :perm }

          it { expect_not_to_raise_error }
          its_side_effects_are do
            expect(filename).to have_content(expected_file_data)
            expect(filename).to have_owner('nobody')
            expect(filename).to have_group('nogroup')
            expect(filename).to have_file_permission(0o100600)
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when file does not exist' do
      let(:expected_file_data) { data }

      it_behaves_like 'file is correctly appended'
    end

    context 'when file exists' do
      let(:expected_file_data) { "foobar#{data}" }

      before { write(filename, 'foobar', 0o777) }

      it_behaves_like 'file is correctly appended'
    end
  end

  ##############################################################################

  # @param message [String]
  def expect_raise_error(message)
    expect { subject }.to raise_error(described_class::Error, message)
  end

  def expect_not_to_raise_error
    expect { subject }.not_to raise_error
  end

  # @overload write(filename, content)
  #   @param filename [String]
  #   @param content [String]
  #
  # @overload write(filename, content, perm)
  #   @param filename [String]
  #   @param content [String]
  #   @param perm [Integer]
  #
  # @return [void]
  def write(filename, content, perm = nil)
    FileUtils.mkdir_p(::File.dirname(filename))
    File.write(filename, content)
    FileUtils.chmod(perm, filename) if perm
  end
end
