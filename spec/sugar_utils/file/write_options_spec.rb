# frozen_string_literal: true

require 'spec_helper'

describe SugarUtils::File::WriteOptions do
  subject(:write_options) { described_class.new(filename, options) }

  let(:filename) { nil }

  before do
    allow(File).to receive(:exist?).with('missing').and_return(false)
    allow(File).to receive(:exist?).with(/found/).and_return(true)
    allow(File::Stat).to receive(:new).with(/found/).and_return(
      instance_double(File::Stat, uid: :uid, gid: :gid)
    )
  end

  describe '#perm' do
    subject { write_options.perm(*args) }

    inputs  :options, :args
    it_with Hash[],                         [],                0o644
    it_with Hash[],                         %i[default_value], :default_value
    it_with Hash[mode: :mode],              [],                :mode
    it_with Hash[mode: :mode],              %i[default_value], :mode
    it_with Hash[perm: :perm, mode: :mode], [],                :mode
    it_with Hash[perm: :perm, mode: :mode], %i[default_value], :mode
    it_with Hash[perm: :perm],              [],                :perm
    it_with Hash[perm: :perm],              %i[default_value], :perm
  end

  describe '#owner' do
    subject { write_options.owner }

    inputs  :filename, :options
    it_with nil,       Hash[],              nil
    it_with 'missing', Hash[],              nil
    it_with 'found',   Hash[],              :uid
    it_with nil,       Hash[owner: :owner], :owner
    it_with 'missing', Hash[owner: :owner], :owner
    it_with 'found',   Hash[owner: :owner], :owner
  end

  describe '#group' do
    subject { write_options.group }

    inputs  :filename, :options
    it_with nil,       Hash[],              nil
    it_with 'missing', Hash[],              nil
    it_with 'found',   Hash[],              :gid
    it_with nil,       Hash[group: :group], :group
    it_with 'missing', Hash[group: :group], :group
    it_with 'found',   Hash[group: :group], :group
  end

  describe '#slice' do
    subject { write_options.slice(*args) }

    let(:options) { { key1: :value1, key2: :value2, key3: :value3 } }

    inputs  :args
    it_with [],                        Hash[]
    it_with %i[key1],                  Hash[key1: :value1]
    it_with %i[key2],                  Hash[key2: :value2]
    it_with %i[key3],                  Hash[key3: :value3]
    it_with %i[key1 key3],             Hash[key1: :value1, key3: :value3]
    it_with [%i[key1], nil, %i[key3]], Hash[key1: :value1, key3: :value3]
  end

  describe '#basename' do
    subject { write_options.basename }

    let(:options) { {} }

    inputs  :filename
    it_with nil,                   nil
    it_with 'missing',             'missing'
    it_with 'found',               'found'
    it_with 'dir1/dir2/found',     'found'
    it_with 'found.ext',           'found'
    it_with 'dir1/dir2/found.ext', 'found'
  end

  describe '#dirname' do
    subject { write_options.dirname }

    let(:options) { {} }

    inputs  :filename
    it_with nil,                   nil
    it_with 'missing',             '.'
    it_with 'found',               '.'
    it_with 'dir1/dir2/found',     'dir1/dir2'
    it_with 'found.ext',           '.'
    it_with 'dir1/dir2/found.ext', 'dir1/dir2'
  end

  describe '#flush_if_requested' do
    subject { write_options.flush_if_requested(file) }

    let(:file) { instance_double(File) }

    context 'without flush' do
      let(:options) { {} }

      it_has_side_effects
    end

    context 'with flush false' do
      let(:options) { { flush: false } }

      it_has_side_effects
    end

    context 'with flush true' do
      let(:options) { { flush: true } }

      before do
        expect(file).to receive(:flush)
        expect(file).to receive(:fsync)
      end

      it_has_side_effects
    end
  end

  describe '#mkdirname_p', :fakefs do
    subject { write_options.mkdirname_p }

    let(:options) { {} }

    before { allow(write_options).to receive(:dirname).and_return(dirname) }

    context 'without dirname' do
      let(:dirname) { nil }

      it { is_expected.to eq(nil) }
    end

    context 'with dirname' do
      let(:dirname) { 'dirname' }

      its_side_effects_are { expect(dirname).to be_directory }
    end
  end

  describe '#open_exclusive', :fakefs do
    subject do
      write_options.open_exclusive(mode) { |file| file.puts('foobar') }
    end

    let(:options) { { key: :value } }
    let(:file)    { instance_double(File) }

    before { allow(write_options).to receive(:perm).and_return(:perm) }

    context 'without filename' do
      let(:mode)     { :noop }
      let(:filename) { nil }

      it { is_expected.to eq(nil) }
    end

    context 'with filename' do
      let(:filename) { 'dir1/dir2/found' }

      before do
        expect(SugarUtils::File::Lock).to receive(:flock_exclusive)
          .with(kind_of(File), options)
        expect(write_options).to receive(:flush_if_requested)
          .with(kind_of(File))
      end

      shared_examples_for 'file contains' do |content|
        its_side_effects_are { expect(filename).to have_content(content) }
      end

      context 'when appending missing file' do
        let(:mode) { 'a' }

        it_behaves_like 'file contains', 'foobar'
      end

      context 'when appending existing file' do
        let(:mode) { 'a' }

        before { write(filename, 'deadbeef') }

        it_behaves_like 'file contains', 'deadbeeffoobar'
      end

      context 'when writing missing file' do
        let(:mode) { 'w+' }

        it_behaves_like 'file contains', 'foobar'
      end

      context 'when writing existing file' do
        let(:mode) { 'w+' }

        before { write(filename, 'deadbeef') }

        it_behaves_like 'file contains', 'foobar'
      end
    end
  end

  ##############################################################################

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
