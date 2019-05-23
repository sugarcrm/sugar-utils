# sugar_utils

[![Gem Version](https://badge.fury.io/rb/sugar_utils.svg)](http://badge.fury.io/rb/sugar_utils)
[![Build Status](https://travis-ci.org/sugarcrm/sugar_utils.svg?branch=master)](https://travis-ci.org/sugarcrm/sugar_utils)
[![Code Climate](https://codeclimate.com/github/sugarcrm/sugar_utils/badges/gpa.svg)](https://codeclimate.com/github/sugarcrm/sugar_utils)
[![Test Coverage](https://codeclimate.com/github/sugarcrm/sugar_utils/badges/coverage.svg)](https://codeclimate.com/github/sugarcrm/sugar_utils/coverage)
[![Inline docs](http://inch-ci.org/github/sugarcrm/sugar_utils.svg)](http://inch-ci.org/github/sugarcrm/sugar_utils)
[![License](http://img.shields.io/badge/license-Apache2-green.svg?style=flat)](LICENSE)

Utility methods extracted from SugarCRM Ruby projects.

These methods are included:

* SugarUtils.ensure_boolean
* SugarUtils.ensure_integer
* SugarUtils.scrub_encoding
* SugarUtils::File.flock_shared
* SugarUtils::File.flock_exclusive
* SugarUtils::File.change_access
* SugarUtils::File.read
* SugarUtils::File.write
* SugarUtils::File.atomic_write
* SugarUtils::File.read_json
* SugarUtils::File.write_json
* SugarUtils::File.append

These methods will probably be included in the future:

* sizeof_dir
* find_files
* find_file!
* gzip
* gunzip
* tarball
* untarball
* tarball_list
* encrypt
* http_get_file
* timeout_retry

## Installation

Add this line to your application's Gemfile:


```ruby
gem 'sugar_utils'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install sugar_utils
```

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for how you can contribute changes back into this project.

## Contributors

* [Andrew Sullivan Cant](https://github.com/acant)
* [Robert Lockstone](https://github.com/lockstone)
* [Vadim Kazakov](https://github.com/yads)

## Acknowledgements

Copyright 2019 [SugarCRM Inc.](http://sugarcrm.com), released under the Apache2 License.
