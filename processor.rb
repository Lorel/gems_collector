require "sexp_processor"
require "pp"
require 'ruby_parser'

class RequireProcessor < SexpProcessor
	attr_accessor :requires

	def initialize
		super
		@requires = {}
		@parser = RubyParser.new
	end

	def find_requires(file)
		@current_file  = file                          # store file name 
		@requires[file] = [] unless @requires[file]    # init key "file" in hash "@requires"
		input = File.read(file)                        # read file returned as String
		exp = @parser.parse(input)                      # parse String returned as Sexp
		self.process(exp)                              # process Sexp
		@requires[file].uniq!                          # avoid duplications
	end

	def process_call(exp)
		until exp.empty? do
			if exp.shift === :require
				sexp = exp.shift
				@requires[@current_file] << sexp.last
			end
		end
		exp
	end

	def output_files
		puts "Corresponding files :"
		print @requires.values.flatten.uniq.map{ |r| "gem #{r}:\n#{ Gem.find_files(r).empty? ? "\tdependant files not found\n" : Gem.find_files(r).map{ |f| "\t#{f}\n" }.join }" }.join
	end

	def output_gems
		puts "Found gems :"
		print @requires.keys.map{ |k| "File #{k}:\n#{ @requires[k].map{ |g| "\t#{g}\n" }.join }" }.join
	end

	def output_digraph
		out = File.open("output.dot","w")
		out.write("digraph Gems {\n")
		@requires.each_key do |k|
			@requires[k].each do |g|
				out.write("\t\"#{k}\" -> \"#{g}\";\n")
			end
		end
		out.write("}")
		out.close
	end
end


processor = RequireProcessor.new

pp "--> Inspected files :"

ARGV << "." if ARGV.empty? # add current path if no arg

ARGV.each do |arg|
	if File.file? arg
		pp arg
		processor.find_requires arg
	elsif File.directory? arg
		Dir.new(arg).select{|f| File.extname(f) == ".rb" }.each do |filename|
			pp filename
			processor.find_requires( Dir.new(arg).path + "/" + filename )
		end
	end
end

# process find requires
processor.output_gems

processor.output_files
processor.output_digraph