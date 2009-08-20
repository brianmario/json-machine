# encoding: UTF-8

require 'rubygems'
require 'benchmark'
require 'yajl'
# require 'json/pure'
# if we require activesupport, it'll unconditionally require the C version of the JSON gem
# this benchmark wants to use the pure ruby version
require 'activesupport'
require File.join(File.dirname(__FILE__), '..', 'lib', 'json_machine')

json = File.read(ARGV[0])
yajl = json_machine = active_support = json_pure = ""
Benchmark.bm do |x|
  puts "yajl-ruby"
  x.report do
    yajl = Yajl::Parser.parse(json)
  end
  
  puts "JsonMachine"
  x.report do
    json_machine = JsonMachine::Parser.new.parse(json)
  end
  
  # puts "JSON (pure)"
  # x.report do
  #   JSON.parse(json, :max_nesting => false)
  # end
  
  puts "ActiveSupport"
  x.report do
    active_support = ActiveSupport::JSON.decode(json)
  end
end