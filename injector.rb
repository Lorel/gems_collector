require "ruby_parser"
require "ruby2ruby"
require "pp"

class Injector
    def initialize( insert_gem_tracking = false )
        @parser = RubyParser.new
        @rubier = Ruby2Ruby.new
        @insert_gem_tracking = insert_gem_tracking
    end

    def browse(directory)
        files = Dir[directory + "/*"]
        modules = []
    	
    	out_dir = './spooned'
    	Dir.mkdir(out_dir) rescue nil
        files.each do |file|
            if File.directory?(file)
                modules = modules + browse(file)
            elsif file.end_with? ".rb"
                content = File.read(file)
                tree = @parser.parse(content)
                insert_init_gem_tracking tree if @insert_gem_tracking
                modules = modules | browseTree(tree)
                newFile = out_dir + "/" + File.basename(file)
                fout = File.new(newFile, "w")
                fout.write(@rubier.process(tree))
                fout.close
            end
        end
        modules
    end

    def browseTree(tree)
        modules = []
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

                if @insert_gem_tracking
                    i = i + 1
                    tree.insert(index + i, s(:call, nil, :track_required_gems, node[3].deep_clone))
                end
            else
                modules = modules + browseTree(node)
            end
        end
        modules
    end

    def insert_init_gem_tracking tree
        s_to_insert = @parser.parse( File.read( File.dirname(__FILE__) + "/track_required_gems.to_inject" ) )
        tree.insert(1, s_to_insert)
    end
end

directory = ARGV[0]
if directory == nil
    exit 0
end

browser = Injector.new( true )
modules = browser.browse(directory)
 puts("MODULES required : ")   	

for required_module in  modules
   if required_module.class == Sexp
       pp required_module
    else
       puts("\t" + required_module)
    end
end
