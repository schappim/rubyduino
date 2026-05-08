# frozen_string_literal: true

require "test_helper"

class TestRubyduino < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rubyduino::VERSION
  end

  def test_spinel_snapshot_is_available
    assert_equal "a70208094343b9d4cd306218c909d99781661c2f", Rubyduino::Spinel::COMMIT
    assert_path_exists File.join(Rubyduino::Spinel::ROOT, "README.md")
  end

  def test_gemspec_packages_spinel_files
    spec = Gem::Specification.load(File.expand_path("../rubyduino.gemspec", __dir__))

    assert_includes spec.files, "bin/rubyduino"
    assert_includes spec.files, "lib/rubyduino/spinel_arduino_codegen.rb"
    assert_includes spec.files, "vendor/spinel/README.md"
    assert_includes spec.files, "vendor/spinel/spinel_codegen.rb"
    refute_includes spec.files, "vendor/spinel/.git"
  end
end
