# frozen_string_literal: true

require "test_helper"
require "support/compile_helper"

class TestBuiltinExamples < Minitest::Test
  EXAMPLES_DIR = File.expand_path("../examples/builtin", __dir__)

  Dir.glob(File.join(EXAMPLES_DIR, "*", "*.rb")).sort.each do |path|
    rel = path.sub("#{File.dirname(EXAMPLES_DIR)}/", "")
    test_name = "test_#{rel.gsub(%r{[/.]}, "_")}_compiles"
    define_method(test_name) do
      skip "avr-gcc not installed" unless CompileHelper.avr_gcc_available?
      sketch = File.read(path)
      obj = CompileHelper.compile_ruby_to_avr_obj(sketch)
      refute_empty obj, "empty obj for #{rel}"
    end
  end

  def test_examples_dir_has_translations
    rb_files = Dir.glob(File.join(EXAMPLES_DIR, "*", "*.rb"))
    assert_operator rb_files.length, :>=, 35, "expected at least 35 example sketches"
  end
end
