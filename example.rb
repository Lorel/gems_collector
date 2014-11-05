require "ruby_parser"
require "ruby2ruby"
require "active_record"

class Test
	def initialize
		puts Gem.location_of_caller
	end

	require "sexp"

	def foo
		puts "yo ! i'm foo"
	end
end

Test.new.foo

parser = RubyParser.new

s = parser.parse(File.read "example.rb")

puts s
