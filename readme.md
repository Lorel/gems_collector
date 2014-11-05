# GemCollector

## Goal
- Define gem requirements called in ruby files by AST analysis
- Generate Gemfile at runtime by code injection

## Usage

### processor.rb
Product list of required gem names and dot file for gem dependencies graph production with Graphvitz
```
ruby processor.rb path/to/files
```
You can pass as argument several path

### injector.rb
Inject some code in processed files to output in a generated Gemfile which gem and which version is required on each `:require` call
```
ruby injector.rb path/to/files
``` 