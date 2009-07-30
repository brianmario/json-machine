# encoding: UTF-8

module JsonMachine
  class Parser
    NULL = "null".freeze
    TRUE = "true".freeze
    FALSE = "false".freeze
    
    def initialize(opts={})
      # TODO: setup options
    end
    
    def parse(str_or_io)
      str_or_io = StringIO.new(str_or_io) if str_or_io.is_a?(String)
      current_value = ""
      while char = str_or_io.read(1)
        case char
        when '"'
          if parse_string(str_or_io, current_value)
            return current_value
          else
            # TODO: throw exception?
          end
        when /[0-9]/ # probably a number
          current_value = char
          if parse_number(str_or_io, current_value)
            return current_value
          else
            # TODO: raise exception?
          end
        when 'n' # probably null
          current_value = char
          if parse_null(str_or_io, current_value)
            return nil
          else
            # TODO: raise exception?
          end
        when 't' # probably true
          current_value = char
          if parse_true(str_or_io, current_value)
            return true
          else
            # TODO: raise exception?
          end
        when 'f' # probably false
          current_value = char
          if parse_false(str_or_io, current_value)
            return false
          else
            # TODO: raise exception?
          end
        when '{' # probably the start of a hash
        when '[' # probably the start of an array
        else
          if char == "'"
            # TODO: throw exception?
            # This is the case where we're parsing a string that should be wrapped with double-quotes
            # Either a hash key or string value
          end
          # TODO: something here?
        end
      end
    end
    
    protected
      def parse_string(io, out_str)
        while char = io.read(1)
          return true if char == '"'
          out_str << char
        end
        return false
      end
      
      def parse_number(io, out_str)
        while char = io.read(1)
          return if char == ','
          out_str << char
        end
      end
      
      def parse_true(io, out_str)
        out_str << io.read(3)
        if out_str != TRUE
          return false
        else
          return true
        end
      end
      
      def parse_false(io, out_str)
        out_str << io.read(4)
        if out_str != FALSE
          return false
        else
          return true
        end
      end
      
      def parse_null(io, out_str)
        out_str << io.read(3)
        if out_str != NULL
          return false
        else
          return true
        end
      end
  end
end