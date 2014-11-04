require "ruby_parser"
require "ruby2ruby"
require "pp"

class Injector
    attr_reader :modules, :out_dir

    def initialize( insert_gem_tracking = false )
        @parser = RubyParser.new
        @rubier = Ruby2Ruby.new
        @modules = []
        @insert_gem_tracking = insert_gem_tracking
        
        @out_dir = './spooned'
        Dir.mkdir out_dir rescue nil
    end

    def browse(file)
        content = File.read(file)
        tree = @parser.parse(content)
        insert_init_gem_tracking tree if @insert_gem_tracking
        @modules = @modules | browseTree(tree)
        newFile = @out_dir + "/" + File.basename(file)
        fout = File.new(newFile, "w")
        fout.write(@rubier.process(tree))
        fout.close
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

browser = Injector.new( true )

ARGV << "." if ARGV.empty? # add current path if no arg

ARGV.each do |arg|
    if File.file? arg
        browser.browse arg
    elsif File.directory? arg
        Dir.glob(arg + "/**/*").select{|f| File.extname(f) == ".rb" && ( !f.include? browser.out_dir ) }.each do |filename|
            browser.browse filename
        end
    end
end

puts("MODULES required : ")   	

for required_module in  browser.modules
   if required_module.class == Sexp
       pp required_module
    else
       puts("\t" + required_module)
    end
end
