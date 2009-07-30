# encoding: UTF-8

module JsonMachine
  class ParseError < StandardError; end
  
  class Parser
    NULL = "null".freeze
    TRUE = "true".freeze
    FALSE = "false".freeze
    NUMBER_MATCHER = /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/.freeze
    STRING_MATCHER = /\"(.*)\"/.freeze
    
    def initialize(opts={})
      # TODO: setup options
      @builder_stack = []
      @options = opts
      @state = :beginning
    end
    
    def found_string(str)
      set_value(str)
    end
    
    def found_number(number_str)
      if number_str.include?('E') || number_str.include?('e')
        if number_str.include?('.')
          # TODO: need to parse numbers with an E
          raise ParseError, "Need to implement converting a float string with exponents"
        else
          # TODO: need to parse numbers with an E
          raise ParseError, "Need to implement converting an integer string with exponents"
        end
      else
        if number_str.include?('.')
          set_value(number_str.to_f)
        else
          set_value(number_str.to_i)
        end
      end
    end
    
    def found_hash_start
      set_value({})
    end
    
    def found_hash_key(key)
      if @options[:symbolize_keys]
        set_value(key.to_sym)
      else
        set_value(key)
      end
    end
    
    def found_hash_end
      if @builder_stack.size > 1
        @builder_stack.pop
      end
    end
    
    def found_array_start
      set_value([])
    end
    
    def found_array_end
      if @builder_stack.size > 1
        @builder_stack.pop
      end
    end
    
    def found_boolean(bool)
      set_value(bool)
    end
    
    def found_nil
      set_value(nil)
    end
    
    def parse(str)
      scanner = StringScanner.new(str)
      char = scanner.peek(1)
      case char
      when '"'
        if scanner.check(STRING_MATCHER)
          string = scanner.scan_until(STRING_MATCHER)
          found_string(string[1,string.size-2])
        end
      when /[0-9]/
        if scanner.check(NUMBER_MATCHER)
          found_number(scanner.scan_until(/.*[,]?/))
        end
      when 'n'
        if scanner.peek(4) === NULL
          found_nil
          scanner.pos = scanner.pos+4
        end
      when 't'
        if scanner.peek(4) === TRUE
          found_boolean(true)
          scanner.pos = scanner.pos+4
        end
      when 'f'
        if scanner.peek(5) === FALSE
          found_boolean(false)
          scanner.pos = scanner.pos+5
        end
      when '{'
        
      when '['
        
      end
      @builder_stack.pop
    end
    
    protected
      def set_value(value)
        len = @builder_stack.size
        if len > 0
          last_entry = @builder_stack.last
          case last_entry.class
          when Array
            last_entry << value
            if value.is_a?(Hash) or value.is_a?(Array)
              @builder_stack << value
            end
          when Hash
            last_entry[value] = nil
            @builder_stack << value
          when String, Symbol
            hash = @builder_stack[len-2]
            if hash.is_a?(Hash)
              hash[last_entry] = value
              @builder_stack.pop
              if value.is_a?(Hash) or value.is_a?(Array)
                @builder_stack << value
              end
            end
          end
        else
          @builder_stack << value
        end
      end
  end
end