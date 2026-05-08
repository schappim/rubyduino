#!/usr/bin/env ruby
# Arduino UNO codegen layer for Spinel.
#
# This file intentionally leaves spinel_codegen.rb unchanged. Spinel's codegen
# file is CLI-oriented, so we load only its Compiler definition and keep the
# same AST-file input/output-file flow as the upstream footer.

ROOT = File.expand_path("../..", __dir__)
SPINEL_ROOT = File.join(ROOT, "vendor/spinel")

def load_spinel_compiler
  path = File.join(SPINEL_ROOT, "spinel_codegen.rb")
  source = File.read(path)
  marker = "\n# ---- Main ----\n"
  split_at = source.index(marker)
  unless split_at
    warn "spinel_arduino_codegen: cannot find codegen main marker"
    exit(1)
  end

  TOPLEVEL_BINDING.eval(source[0...split_at], path)
end

load_spinel_compiler

module SpinelArduinoCodegen
  def compile_no_recv_call_expr(nid, mname)
    case mname
    when "sleep"
      compile_arduino_sleep(nid)
      "0"
    when "rand"
      arduino_rand = compile_arduino_rand(nid)
      return arduino_rand if arduino_rand

      super
    else
      super
    end
  end

  private

  def compile_arduino_sleep(nid)
    args_id = @nd_arguments[nid]
    return if args_id < 0

    arg_ids = get_args(args_id)
    return if arg_ids.empty?

    arg = arg_ids.first
    if numeric_literal_node?(arg)
      emit_arduino_delay_literal(numeric_literal_value(arg))
    else
      emit("  sp_arduino_sleep_seconds(" + compile_expr(arg) + ");")
    end
  end

  def compile_arduino_rand(nid)
    args_id = @nd_arguments[nid]
    return nil if args_id < 0

    arg_ids = get_args(args_id)
    return nil unless arg_ids.length == 1

    arg = arg_ids.first
    return nil unless @nd_type[arg] == "RangeNode"

    left = @nd_left[arg]
    right = @nd_right[arg]
    return nil unless integer_literal_node?(left) && integer_literal_node?(right)

    first = @nd_value[left].to_i
    last = @nd_value[right].to_i
    return "0" if last < first

    @needs_rand = 1
    span = last - first + 1
    "((mrb_int)(#{first} + (rand() % #{span})))"
  end

  def emit_arduino_delay_literal(seconds)
    ms = (seconds * 1000.0).round
    parts = []
    while ms >= 250
      parts << "_delay_ms(250.0)"
      ms -= 250
    end
    parts << "_delay_ms(#{ms}.0)" if ms > 0
    emit("  " + parts.join("; ") + ";") unless parts.empty?
  end

  def integer_literal_node?(nid)
    nid && nid >= 0 && @nd_type[nid] == "IntegerNode"
  end

  def numeric_literal_node?(nid)
    nid && nid >= 0 && %w[IntegerNode FloatNode].include?(@nd_type[nid])
  end

  def numeric_literal_value(nid)
    if @nd_type[nid] == "IntegerNode"
      @nd_value[nid].to_f
    else
      @nd_content[nid].to_f
    end
  end
end

Compiler.prepend(SpinelArduinoCodegen)

ast_file = ARGV[0]
out_file = ARGV[1]

if ast_file.nil?
  warn "Usage: ruby spinel_arduino_codegen.rb ast.txt output.c"
  exit(1)
end

compiler = Compiler.new
compiler.read_text_ast(File.read(ast_file))
compiler.compile

result = compiler.build_output
if out_file
  File.write(out_file, result)
else
  print result
end
