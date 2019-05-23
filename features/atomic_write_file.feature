Feature: Write to a file atomically

Scenario: Write a file atomically
  When I run the following Ruby code:
    """ruby
    require 'sugar_utils'
    puts SugarUtils::File.atomic_write('dir/test', 'foobar')
    """
  Then the file named "dir/test" should contain exactly:
    """
    foobar
    """

Scenario: Overwrite a file atomically
  Given a file named "dir/test" with "deadbeef"
  When I run the following Ruby code:
    """ruby
    require 'sugar_utils'
    puts SugarUtils::File.atomic_write('dir/test', 'foobar')
    """
  Then the file named "dir/test" should contain exactly:
    """
    foobar
    """

# TODO: Fix the owner/group setting check
Scenario: Overwrite a file and reset its permissions atomically
  Given a file named "dir/test" with "deadbeef"
  When I run the following Ruby code:
    """ruby
    require 'sugar_utils'
    puts SugarUtils::File.atomic_write(
      'dir/test',
      'foobar',
      # owner: 'nobody',
      # group: 'nogroup',
      mode:  0o777
    )
    """
  Then the file named "dir/test" should contain exactly:
    """
    foobar
    """
    And the file named "dir/test" should have permissions "777"
    # And the file named "dir/test" should have owner "nobody"
    # And the file named "dir/test" should have group "nogroup"
