# encoding: UTF-8

require 'rubygems'
require 'benchmark'
require 'yajl'
require 'stringio' unless defined?(StringIO)

class JsonMachine
  
  def self.parse(str_or_io)
    new.parse(str_or_io)
  end
  
  def initialize
    @state = :wants_anything
  end
  
  def found_start_hash
    puts "start hash"
  end
  
  def found_hash_key(key)
    puts "hash key: #{key}"
  end
  
  def found_end_hash
    puts "end hash"
  end
  
  def found_start_array
    puts "start array"
  end
  
  def found_end_array
    puts "end array"
  end
  
  def found_number(number_str)
    puts "found number: #{number_str}"
  end
  
  def found_string(str)
    puts "found string: #{str}"
  end
  
  def found_boolean(bool)
    puts "boolean"
  end
  
  def found_nil
    puts "nil"
  end
  
  def parse(str_or_io)
    str_or_io = StringIO.new(str_or_io) if str_or_io.is_a?(String)
    current_value = ""
    while char = str_or_io.read(1)
      case @state
      when :wants_hash_key
        parse_string(str_or_io, current_value)
        found_hash_key(current_value)
        current_value.replace('')
        @state = :wants_hash_value
      when :wants_hash_value
        case char
        when ':'
        when ' '
        else
          @state = :at_hash_value
          redo
        end
      when :at_hash_value
        case char
        when '"' # value is a string
          parse_string(str_or_io, current_value)
          found_string(current_value)
          current_value.replace('')
          @state = :wants_another_hash_key
        when '{' # value is another hash
          found_start_hash
          str_or_io.read(1) # read off the '"' char
          @state = :wants_hash_key
        when '[' # value is an array
        when 'n' # value is probably 'null'
          val = char
          val << str_or_io.read(3)
          found_nil if val == 'null'
          @state = :wants_another_hash_key
        when 't' # value is probably 'true'
          val = char
          val << str_or_io.read(3)
          found_boolean(true) if val == 'true'
          @state = :wants_another_hash_key
        when 'f' # value is probably 'false'
          val = char
          val << str_or_io.read(3)
          found_boolean(false) if val == 'false'
          @state = :wants_another_hash_key
        when /[0-9]/, '-' # value is probably a number
          current_value << char
        end
      when :wants_anything, :wants_array_value, :wants_another_hash_key
        case char
        when '{'
          found_start_hash
          str_or_io.read(1) # read off the '"' char
          @state = :wants_hash_key
        when '['
          found_start_array
          @state = :wants_array_value
        when '}'
          found_end_hash
        when ']'
          found_end_array
        when ','
          if @state == :wants_array_value
            puts "array value"
            # char = str_or_io.read(1)
          elsif @state == :wants_another_hash_key
            @state = :wants_hash_key
          end
        end
      end
    end
  end
  
  protected
    def parse_number(io, out_str)
      while char = str_or_io.read(1)
        return if char == ','
        out_str << char
      end
    end
    
    def parse_bool(io, out_str)
      out_str << io.read(3)
    end
    
    def parse_null(io, out_str)
      out_str << io.read(3)
    end
    
    # Assumes it's being handed the IO at the position
    def parse_string(io, out_str)
      while char = str_or_io.read(1)
        return if char == '"'
        out_str << char
      end
    end
end

json = '{"item": {"name": "generated", "cached_tag_list": "", "updated_at": "2009-03-24T05:25:09Z", "updated_by_id": null, "price": 1.99, "delta": false, "cost": 0.597, "account_id": 16, "unit": null, "import_tag": null, "taxable": true, "id": 1, "created_by_id": null, "description": null, "company_id": 0, "sku": "06317-0306", "created_at": "2009-03-24T05:25:09Z", "active": true}}'
# puts json
Benchmark.bm do |x|
  x.report do
    JsonMachine.parse(json)
  end
  x.report do
    Yajl::Parser.parse(json)
  end
end