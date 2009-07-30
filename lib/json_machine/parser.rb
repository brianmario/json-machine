# encoding: UTF-8

module JsonMachine
  class ParseError < StandardError; end
  
  class Parser
    NULL = "null".freeze
    TRUE = "true".freeze
    FALSE = "false".freeze
    NUMBER_MATCHER = /[-+]?\d*\.?\d+([eE][-+]?\d+)?/.freeze
    
    def initialize(opts={})
      # TODO: setup options
      @builder_stack = []
      @options = opts
      @state = :wants_anything
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
    
    def parse(str_or_io, &block)
      if str_or_io.is_a?(String)
        internal_parse(str_or_io)
      elsif str_or_io.respond_to?(:read)
        # TODO: not supported yet
        # while str = str_or_io.read(READ_BUFFER_SIZE)
        #   internal_parse(str)
        # end
      end
    end
    
    protected
      def internal_parse(str)
        scanner = StringScanner.new(str)
        while !scanner.eos? && (char = scanner.peek(1))
          case char
          when '"'
            scanner.pos += 1
            current_string = ""
            while check = scanner.check_until(/(\\"|[":,\\])/)
              if check[check.size-2,2] == "\\\"" # end of an escaped string
                current_string << check
                scanner.pos += check.size
              elsif check[check.size-1,1] == "\"" # end of a string
                current_string << check
                scanner.pos += check.size
                found_string(current_string[0, current_string.size-1])
                break
              else
                current_string << check
                scanner.pos += check.size
              end
            end
          when /[0-9]/
            if scanner.check_until(NUMBER_MATCHER)
              found_number(scanner.scan_until(NUMBER_MATCHER))
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
            found_hash_start
            scanner.pos = scanner.pos+1
            @state = :wants_hash_key
            next
          when '}'
            found_hash_end
            scanner.pos = scanner.pos+1
            next
          when '['
            found_array_start
            scanner.pos = scanner.pos+1
            @state = :wants_array_value
            next
          when ']'
            found_array_end
            scanner.pos = scanner.pos+1
            next
          else
            scanner.pos = scanner.pos+1
            next
          end
        end
        @builder_stack.pop
      end
    
      def set_value(value)
        len = @builder_stack.size
        if len > 0
          last_entry = @builder_stack.last
          case last_entry.class.name
          when 'Array'
            last_entry << value
            if value.is_a?(Hash) or value.is_a?(Array)
              @builder_stack << value
            end
          when 'Hash'
            last_entry[value] = nil
            @builder_stack << value
          when 'String', 'Symbol'
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