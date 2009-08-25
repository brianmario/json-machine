# encoding: UTF-8

module JsonMachine
  class Encoder
    def initialize(opts={})
    end
    
    def encode(obj)
      case obj.class.name
      when "Hash"
        val = "{"
        val << obj.keys.map do |key|
          "\"#{key}\": #{encode(obj[key])}"
        end * ", "
        val << "}"
      when "Array"
        "[#{obj.map{|val| encode(val)} * ', '}]"
      when "NilClass"
        "null"
      when "TrueClass", "FalseClass", "Fixnum", "Float"
        obj.to_s
      else
        if obj.respond_to?(:to_json)
          obj.to_json
        else
          "\"#{obj.to_s}\""
        end
      end
    end
  end
end