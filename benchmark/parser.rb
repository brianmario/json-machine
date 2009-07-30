# encoding: UTF-8

require 'rubygems'
require 'benchmark'
require 'yajl'
require 'activesupport'
require 'lib/json_machine'

json = '{"item": {"name": "generated", "cached_tag_list": "", "updated_at": "2009-03-24T05:25:09Z", "updated_by_id": null, "price": 1.99, "delta": false, "cost": 0.597, "account_id": 16, "unit": null, "import_tag": null, "taxable": true, "id": 1, "created_by_id": null, "description": null, "company_id": 0, "sku": "06317-0306", "created_at": "2009-03-24T05:25:09Z", "active": true}}'
yajl = json_machine = active_support = ""
Benchmark.bm do |x|
  puts "yajl-ruby"
  x.report do
    yajl = Yajl::Parser.parse(json)
  end
  
  puts "JsonMachine"
  x.report do
    parser = JsonMachine::Parser.new
    json_machine = parser.parse(json)
  end
  
  puts "ActiveSupport"
  x.report do
    active_support = ActiveSupport::JSON.decode(json)
  end
end

puts yajl === json_machine
puts active_support === json_machine