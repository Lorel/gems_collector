require 'sexp_processor'
require 'pp'
require 'ruby_parser'

class RequireProcessor < SexpProcessor
	attr_accessor :requires

	def initialize
		super
		@requires = {}
		@parser = RubyParser.new
	end

	def find_requires(file)
		@current_file  = File.basename file                     # store file name 
		@requires[@current_file] = [] unless @requires[file]    # init key "file" in hash "@requires"
		input = File.read(file)                                 # read file returned as String
		begin
			exp = @parser.parse(input)                              # parse String returned as Sexp
			self.process(exp)                                       # process Sexp
		rescue
			pp "Error on " + file
		end
		@requires[@current_file].uniq!                          # avoid duplications
	end

	def process_call(exp)
		exp.shift                                               # pop :call
		if sexp = exp.shift										# case when second element is a sexp for const or lvar
			until exp.empty? do
				exp.shift
			end
		else													# case when second element in sexp is nil
			until exp.empty? do
				case exp.shift
				when :require
					sexp = exp.shift
					@requires[@current_file] << sexp.last
				end
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
				out.write("\t\"#{k}\" -> \"#{g}\";\n") if g.is_a? String
			end
		end
		out.write("rankdir=LR;}")
		out.close
	end
end


processor = RequireProcessor.new

pp "--> Inspected files :"

ARGV << "." if ARGV.empty? # add current path if no arg

ARGV.each do |arg|
	if File.file? arg
		processor.find_requires arg
		pp arg
	elsif File.directory? arg
		Dir.glob(arg + "/**/*").select{|f| File.extname(f) == ".rb" }.each do |filename|
			pp (filename)
			processor.find_requires filename 
		end
	end
end

# outputs
processor.output_gems
processor.output_files rescue nil
processor.output_digraph