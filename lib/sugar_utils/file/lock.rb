# frozen_string_literal: true

require 'timeout'

module SugarUtils
  module File
    # @api private
    class Lock
      # @param file [File]
      # @param options [Hash]
      # @option options [Integer] :timeout (10)
      #
      # @raise [Timeout::Error]
      #
      # @return [void]
      def self.flock_shared(file, options = {})
        timeout = options[:timeout] || 10
        Timeout.timeout(timeout) { file.flock(::File::LOCK_SH) }
      end

      # @param file [File]
      # @param options [Hash]
      # @option options [Integer] :timeout (10)
      #
      # @raise [Timeout::Error]
      #
      # @return [void]
      def self.flock_exclusive(file, options = {})
        timeout = options[:timeout] || 10
        Timeout.timeout(timeout) { file.flock(::File::LOCK_EX) }
      end
    end
  end
end
