# frozen_string_literal: true

module SugarUtils
  module File
    # @api private
    # Handle the write related options, and some of the methods which are
    # directly controlled by those options.
    class WriteOptions
      # @parma filename [String]
      # @param options [Hash]
      # @option options [String, Integer] :owner
      # @option options [String, Integer] :group
      # @option options [Integer] :mode
      # @option options [Integer] :perm
      # @option options [Boolean] :flush
      def initialize(filename, options)
        @filename = filename
        @options  = options

        return unless filename && ::File.exist?(filename)

        file_stat       = ::File::Stat.new(filename)
        @existing_owner = file_stat.uid
        @existing_group = file_stat.gid
      end

      # @overload perm
      #   The default permission is 0o644
      # @overload perm(default_value)
      #   @param default_value [nil, Integer]
      #   Override the default_value including allowing nil.
      #
      # @return [Integer]
      def perm(default_value = 0o644)
        # NOTE: We are using the variable name 'perm' because that is the name
        # of the argument used by File.open.
        @options[:mode] || @options[:perm] || default_value
      end

      # @return [String]
      # @return [Integer]
      def owner
        @options[:owner] || @existing_owner
      end

      # @return [String]
      # @return [Integer]
      def group
        @options[:group] || @existing_group
      end

      # @param keys [Array]
      #
      # @return [Hash]
      def slice(*args)
        keys = args.flatten.compact
        @options.select { |k| keys.include?(k) }
      end

      # @return [nil]
      # @return [String]
      def basename
        return unless @filename

        ::File.basename(@filename, '.*')
      end

      # @return [nil]
      # @return [String]
      def dirname
        return unless @filename

        ::File.dirname(@filename)
      end

      # Flush and fsync to be 100% sure we write this data out now because we
      # are often reading it immediately and if the OS is buffering, it is
      # possible we might read it before it is been physically written to
      # disk. We are not worried about speed here, so this should be OKAY.
      #
      # @param file [File]
      #
      # @return [void]
      def flush_if_requested(file)
        return unless @options[:flush]

        file.flush
        file.fsync
      end

      # @return [void]
      def mkdirname_p
        return unless dirname

        FileUtils.mkdir_p(dirname)
      end

      # @param mode [String]
      #
      # @yieldparam file [File]
      #
      # @raise [SystemCallError]
      # @raise [IOError]
      # @raise [Timeout::Error]
      #
      # @return [void]
      def open_exclusive(mode, &block)
        return unless @filename

        mkdirname_p
        ::File.open(@filename, mode, perm) do |file|
          SugarUtils::File::Lock.flock_exclusive(file, @options)

          block.call(file)

          flush_if_requested(file)
        end
      end
    end
  end
end
