require 'ruby_parser'
require 'ruby2ruby'
require "pp"


parser = RubyParser.new
rubier = Ruby2Ruby.new
input = File.read("/home/lorel/RubySpace/example.rb")
s = parser.parse(input)
out = File.new("/home/lorel/RubySpace/out.rb","w")
out.puts( rubier.process s.deep_clone)
out.close

# pp s.deep_clone
# pp Gem.loaded_specs
# pp $LOADED_FEATURES

pp s

class RequireProcessor < SexpProcessor
	def initialize
		super
		@expected = String
	end

	def process(exp)
		puts "PROCESS"
		pp exp
		super(exp)
	end

	def process_block(exp)
		puts "PROCESS BLOCK"
		exp.shift

		result = @expected.new

		until exp.empty? do
			result << self.process(exp.shift)
		end
	end

	def process_class(exp)
		String.new
	end

	def process_defn(exp)
		String.new
	end

	def process_defs(exp)
		String.new
	end

	def process_sclass(exp)
		String.new
	end

	def process_module(exp)
		String.new
	end

	def process_require(exp)
		puts "PROCESS REQUIRE : "
		pp exp.shift
		result = "require "

		# until exp.empty? do
		# 	result << self.process(exp)
		# end

		result + exp.shift.to_s
	end

	def process_call(exp)
		puts "PROCESS CALL : "
		
		pp exp.shift
		pp exp.shift

		# receiver_node_type = exp.first.nil? ? nil : exp.first.first
		result = @expected.new
		
		until exp.empty? do
			pp exp.clone.shift
			result << self.process(exp)
		end

		result + "\n"
	end

	# def process_str(exp)
	# 	super
	# 	# puts "PROCESS STR : "

	# 	# pp exp.shift
	# 	# exp.shift.to_s
	# end
end

processor = RequireProcessor.new

# processor.process s.deep_clone