# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- SugarUtils::File.append, which is explicitly for appending to a file. It will
  also create a new file if it does not yet exist
- SugarUtils::scrub_encoding, which is used for cleaning badly encoded
  characters out of a string
- SugarUtils::File.change_access, a wrapper for changing ownership and
  permissions of a file
- SugarUtils::File.atomic_write, to atomically write a file
### Removed
- append support in SugarUtils::File.write (could have been specified by { mode: 'a })
### Changed
- :mode and :perm are now aliases for setting permissions on files in all the
  related methods (i.e., .write, .write_json, .touch, .append)

## [0.5.0] - 2018-05-01
### Changed
- bring back :perm as option to set the permissions in SugarUtils::File.write and SugarUtils::File.touch methods
- :mode option in SugarUtils::File.write is now to be used for setting the file mode (e.g. read/write, append, etc). It can still be used for setting the permissions if it is an integer value for backwards compatibility purposes, but this usage has been deprecated.

## [0.4.4] - 2018-01-31
### Changed
- fixed a bug in SugarUtils::File.read_json which it would raise an exception
  instead of returning an empty Hash, when :raise_on_missing was disabled and
  there was an error reading the file

## [0.4.3] - 2017-08-25
### Added
- option to scrub character encoding in SugarUtils::File.read
- option to set mtime in SugarUtils::File.touch

## [0.4.2] - 2017-08-01
### Changed
- default file creation permissions from 666 to 644.

## [0.4.1] - 2017-05-17
### Added
- options :owner, :group, :mode to SugarUtils::File.write and .touch

### Changed
- marked the :perm option as deprecated by :mode

## [0.4.0] - 2017-05-17
### Added
- SugarUtils::File.touch, which will ensure the directory before touching the
  specified file

## [0.3.0] - 2017-03-29
### Added
- SugarUtils::File.read, with locking and error handling when reading a plain
  text file
- SugarUtils::File.write, with locking and error handling when writing a plain
  text file

### Changed
- explicitly specify the Ruby v2.0.0 support limit
- divide SugarUtils::File.flock into .flock_shared and .flock_exclusive

## [0.2.0] - 2016-07-21
### Added
- SugarUtils::File.flock, for file locking with a timeout
- SugarUtils::File.read_json, with locking and error handling
- SugarUtils::File.write_json, with locking and error handling
- this CHANGELOG.md, following the http://keepachangelog.com/ guidelines

## [0.1.0] - 2016-07-09
### Added
- SugarUtils.ensure_boolean
- SugarUtils.ensure_integer
