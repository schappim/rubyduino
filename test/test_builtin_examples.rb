# frozen_string_literal: true

require "test_helper"
require "support/compile_helper"

class TestBuiltinExamples < Minitest::Test
  ROOT_EXAMPLES = File.expand_path("../examples", __dir__)

  Dir.glob(File.join(ROOT_EXAMPLES, "{builtin,hardware}", "**", "*.rb")).sort.each do |path|
    rel = path.sub("#{File.dirname(ROOT_EXAMPLES)}/", "")
    test_name = "test_#{rel.gsub(%r{[/.]}, "_")}_compiles"
    define_method(test_name) do
      skip "avr-gcc not installed" unless CompileHelper.avr_gcc_available?
      sketch = File.read(path)
      obj = CompileHelper.compile_ruby_to_avr_obj(sketch)
      refute_empty obj, "empty obj for #{rel}"
    end
  end

  def test_examples_dirs_have_sketches
    builtin = Dir.glob(File.join(ROOT_EXAMPLES, "builtin", "*", "*.rb"))
    hardware = Dir.glob(File.join(ROOT_EXAMPLES, "hardware", "*.rb"))
    assert_operator builtin.length, :>=, 35, "expected at least 35 builtin example sketches"
    assert_operator hardware.length, :>=, 7, "expected at least 7 hardware example sketches"
  end
end
