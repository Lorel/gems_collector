require "ruby_parser"
require "ruby2ruby"

class Injector
    def intialize(); end

    def browse(directory)
        require "pp"
        files = Dir[directory + "/*"]
        parser = RubyParser.new
        modules = Array.new
	rubier = Ruby2Ruby.new
	out_dir = './spooned'
	Dir.mkdir(out_dir) rescue nil
        for file in files
            if File.directory?(file)
                modules = modules + browse(file)
            elsif file.end_with? ".rb"
                content = File.read(file)
                tree = parser.parse(content)
                modules = modules + browseTree(tree)
		newFile = out_dir + "/" + File.basename(file)
		fout = File.new(newFile, "w")
		fout.write(rubier.process(tree))
		fout.close
            end
        end
        return modules
    end

    def browseTree(tree)
        modules = Array.new
	i = 0
	tree.each_index do |index|
	    node = tree[index + i]
            if node.class != Sexp
                next
            end
            if node.sexp_type == :call and node[2] == :require
                #TODO handle local require (eg: "diranme + ../my_script.rb") where module_required is a sexp
                module_required = node[3][1]
                modules << module_required
		i = i + 1
		tree.insert(index + i, s(:call, nil, :puts, s(:call, s(:const, :Gem), :loaded_specs)))
            else
                modules = modules + browseTree(node)
            end
        end
        return modules
    end
end


directory = ARGV[0]
if directory == nil
    exit 0
end

browser = Injector.new()
modules = browser.browse(directory)
 puts("MODULES required : ")   	

for required_module in  modules
   if required_module.class == Sexp
       pp required_module
    else
       puts("\t" + required_module)
    end
end
