
require 'coffee-script'
require 'fileutils'
require 'uglifier'
require 'jasmine-headless-webkit'
require 'listen'


COFFEE_SRC = FileList['src/*.coffee']
COFFEE_DEST = COFFEE_SRC.pathmap "/tmp/%n.js"
JAVASCRIPT_SRC = FileList['src/*.js']
JAVASCRIPT_DEST = JAVASCRIPT_SRC.pathmap "/tmp/%n.js"
DEST = 'react.min.js'

task :default => [DEST]

COFFEE_DEST.each do |jsfile|
  srcfile = File.join('src', File.basename(jsfile).ext('.coffee'))

  file jsfile => srcfile do |t|
    File.write jsfile, CoffeeScript.compile(File.read(srcfile))
  end
end

JAVASCRIPT_DEST.each do |jsfile|
  srcfile = File.join('src', File.basename(jsfile).ext('.js'))

  file jsfile => srcfile do |t|
    FileUtils.cp srcfile, jsfile
  end
end

file DEST => COFFEE_DEST + JAVASCRIPT_DEST do |t|
  source = t.prerequisites.collect { |fn| File.read(fn) }
  source = source.join ' '
  File.write t.name, Uglifier.compile(source)
end

Jasmine::Headless::Task.new('jasmine_headless') do |t|
    t.colors = true
    t.jasmine_config = 'jasmine.yaml'
    t.keep_on_error = true
end

task :clean do
  File.delete DEST
  FileUtils.rmdir 'build'
end

task :test => [DEST, :jasmine_headless] do |to|

end

task :watch do
  Listen.to 'src' do
    system 'rake test'
  end
  Listen.to 'spec' do
    system 'rake test'
  end
end

