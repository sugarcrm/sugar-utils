# frozen_string_literal: true

require 'solid_assert'
require 'fileutils'
require 'multi_json'
require 'tempfile'

require 'sugar_utils/file/lock'
require 'sugar_utils/file/write_options'

module SugarUtils
  # @api
  module File # rubocop:disable Metrics/ModuleLength
    class Error < StandardError; end

    # @param file [File]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    #
    # @raise [Timeout::Error]
    #
    # @return [void]
    def self.flock_shared(file, options = {})
      Lock.flock_shared(file, options)
    end

    # @param file [File]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    #
    # @raise [Timeout::Error]
    #
    # @return [void]
    def self.flock_exclusive(file, options = {})
      Lock.flock_exclusive(file, options)
    end

    # Change all of the access values for the specified file including:
    # * owner
    # * group
    # * permissions
    #
    # @note Although the are all required, nil can be passed to any of them and
    # those nils will be skipped. Hopefully, this will avoid conditions in the
    # calling code because the optional parameters will just be passed in and
    # skipped when they are missing.
    #
    # @param filename [String]
    # @param owner [nil, Integer, String]
    # @param group [nil, Integer, String]
    # @param permission [nil, Integer]
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [void]
    def self.change_access(filename, owner, group, permission)
      FileUtils.chown(owner, group, filename)
      FileUtils.chmod(permission, filename) if permission
      nil
    rescue SystemCallError, IOError
      raise(Error, "Unable to change access on #{filename}")
    end

    # @param filename [String]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    # @option options [Boolean] :raise_on_missing (true)
    # @option options [String] :value_on_missing ('') which specifies the
    #   value to return if the file is missing and raise_on_missing is false
    # @option options [Boolean, String] :scrub_encoding scrub incorrectly
    #   encoded characters with this value, or with '' if the value is true
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [String]
    def self.read(filename, options = {}) # rubocop:disable MethodLength
      options[:value_on_missing] ||= ''
      options[:raise_on_missing] = true if options[:raise_on_missing].nil?

      result =
        ::File.open(filename, ::File::RDONLY) do |file|
          flock_shared(file, options)
          file.read
        end

      return result unless options[:scrub_encoding]

      SugarUtils.scrub_encoding(result, options[:scrub_encoding])
    rescue SystemCallError, IOError
      raise(Error, "Cannot read #{filename}") if options[:raise_on_missing]

      options[:value_on_missing]
    rescue Timeout::Error
      raise(Error, "Cannot read #{filename} because it is locked")
    end

    # @param filename [String]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    # @option options [Boolean] :raise_on_missing (true)
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [Object]
    def self.read_json(filename, options = {})
      options[:value_on_missing] = :missing

      read_result = read(filename, options)
      return {} if read_result == :missing

      MultiJson.load(read_result)
    rescue MultiJson::ParseError
      raise(Error, "Cannot parse #{filename}")
    end

    # Touch the specified file.
    #
    # @param filename [String]
    # @param options [Hash]
    # @option options [String, Integer] :owner
    # @option options [String, Integer] :group
    # @option options [Integer] :mode
    # @option options [Integer] :perm
    # @option options [Integer] :mtime
    #
    # @return [void]
    def self.touch(filename, options = {})
      write_options = WriteOptions.new(filename, options)

      write_options.mkdirname_p
      FileUtils.touch(filename, write_options.slice(:mtime))
      change_access(
        filename,
        write_options.owner,
        write_options.group,
        write_options.perm(nil)
      )
    end

    # Write to an existing file, overwriting it, or create the file if it does
    # not exist.
    #
    # @note Either option :mode or :perm can be used to specific the permissions
    # on the file being written to. This aliasing is used because both these
    # names are used in the standard library, File.open uses :perm and FileUtils
    # uses :mode. The user can choose whichever alias makes their code most
    # readable.
    #
    # @param filename [String]
    # @param data [#to_s]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    # @option options [Boolean] :flush (false)
    # @option options [String, Integer] :owner
    # @option options [String, Integer] :group
    # @option options [Integer] :mode (0o644)
    # @option options [Integer] :perm (0o644)
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [void]
    def self.write(filename, data, options = {}) # rubocop:disable MethodLength
      write_options = WriteOptions.new(filename, options)

      write_options.open_exclusive('w+') do |file|
        file.puts(data.to_s)
      end

      change_access(
        filename,
        write_options.owner,
        write_options.group,
        write_options.perm
      )
    rescue Timeout::Error
      raise(Error, "Unable to write #{filename} because it is locked")
    rescue SystemCallError, IOError => e
      raise(Error, "Unable to write #{filename} with #{e}")
    end

    # Atomically write to an existing file, overwriting it, or create the file
    # if it does not exist.
    #
    # @note Either option :mode or :perm can be used to specific the permissions
    # on the file being written to. This aliasing is used because both these
    # names are used in the standard library, File.open uses :perm and FileUtils
    # uses :mode. The user can choose whichever alias makes their code most
    # readable.
    #
    # @note This method is similar to the atomic_write which is implemnted in
    # ActiveSupport.
    # @see https://apidock.com/rails/File/atomic_write/class
    #
    # @param filename [String]
    # @param data [#to_s]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    # @option options [Boolean] :flush (false)
    # @option options [String, Integer] :owner
    # @option options [String, Integer] :group
    # @option options [Integer] :mode (0o644)
    # @option options [Integer] :perm (0o644)
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [void]
    def self.atomic_write(filename, data, options = {}) # rubocop:disable MethodLength, AbcSize
      write_options = WriteOptions.new(filename, options)

      write_options.mkdirname_p
      Tempfile.open(write_options.basename, write_options.dirname) do |temp_file|
        temp_file.puts(data.to_s)
        write_options.flush_if_requested(temp_file)
        temp_file.close

        write_options.open_exclusive('w+') do
          FileUtils.move(temp_file.path, filename)
        end
      end

      change_access(
        filename,
        write_options.owner,
        write_options.group,
        write_options.perm
      )
    rescue Timeout::Error
      raise(Error, "Unable to write #{filename} because it is locked")
    rescue SystemCallError, IOError => e
      raise(Error, "Unable to write #{filename} with #{e}")
    end

    # Write the data parameter as JSON to the filename path.
    #
    # @note Either option :mode or :perm can be used to specific the permissions
    # on the file being written to. This aliasing is used because both these
    # names are used in the standard library, File.open uses :perm and FileUtils
    # uses :mode. The user can choose whichever alias makes their code most
    # readable.
    #
    # @param filename [String]
    # @param data [#to_json]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    # @option options [Boolean] :flush (false)
    # @option options [String, Integer] :owner
    # @option options [String, Integer] :group
    # @option options [Integer] :mode (0o644)
    # @option options [Integer] :perm (0o644)
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [void]
    def self.write_json(filename, data, options = {})
      atomic_write(filename, MultiJson.dump(data, pretty: true), options)
    end

    # Append to an existing file, or create the file if it does not exist.
    #
    # @note Either option :mode or :perm can be used to specific the permissions
    # on the file being written to. This aliasing is used because both these
    # names are used in the standard library, File.open uses :perm and FileUtils
    # uses :mode. The user can choose whichever alias makes their code most
    # readable.
    #
    # @param filename [String]
    # @param data [#to_s]
    # @param options [Hash]
    # @option options [Integer] :timeout (10)
    # @option options [Boolean] :flush (false)
    # @option options [String, Integer] :owner
    # @option options [String, Integer] :group
    # @option options [Integer] :mode (0o644)
    # @option options [Integer] :perm (0o644)
    #
    # @raise [SugarUtils::File::Error]
    #
    # @return [void]
    def self.append(filename, data, options = {}) # rubocop:disable MethodLength
      write_options = WriteOptions.new(filename, options)

      write_options.open_exclusive('a') do |file|
        file.puts(data.to_s)
      end

      change_access(
        filename,
        write_options.owner,
        write_options.group,
        write_options.perm
      )
    rescue Timeout::Error
      raise(Error, "Unable to write #{filename} because it is locked")
    rescue SystemCallError, IOError => e
      raise(Error, "Unable to write #{filename} with #{e}")
    end

    ############################################################################

    # Following the same pattern as the existing stdlib method deprecation
    # module.
    # @see http://ruby-doc.org/stdlib-2.0.0/libdoc/rubygems/rdoc/Gem/Deprecate.html
    def self.deprecate_option(_method, option_name, option_repl, year, month) # rubocop:disable MethodLength
      return if Gem::Deprecate.skip

      klass  = is_a?(Module)
      target = klass ? "#{self}." : "#{self.class}#"

      # Determine the method
      method = caller_locations(1, 1).first.label

      # Determine the caller
      external_caller             = caller_locations(2, 1).first
      location_of_external_caller = "#{external_caller.absolute_path}:#{external_caller.lineno}"

      msg = [
        "NOTE: #{target}#{method} option :#{option_name} is deprecated",
        case option_repl
        when :none
          ' with no replacement'
        when String
          option_repl
        else
          "; use :#{option_repl} instead"
        end,
        format('. It will be removed on or after %4d-%02d-01.', year, month),
        "\n#{target}#{method} called from #{location_of_external_caller}"
      ]
      warn("#{msg.join}.")
    end
    private_class_method :deprecate_option
  end
end
