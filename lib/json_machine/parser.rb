# encoding: UTF-8

require 'strscan'

module JsonMachine
  class ParseError < StandardError; end
  
  class Parser
    def self.parse(str_or_io, opts={}, &block)
      new(opts).parse(str_or_io, &block)
    end
    
    UNESCAPE_MAP = Hash.new { |h, k| h[k] = k.chr }
    UNESCAPE_MAP.update({
      ?"  => '"',
      ?\\ => '\\',
      ?/  => '/',
      ?b  => "\b",
      ?f  => "\f",
      ?n  => "\n",
      ?r  => "\r",
      ?t  => "\t",
      ?u  => nil, 
    })
    
    # These are here to prevent constantly being GC'd when used inline
    NULL =              "null"
    TRUE =              "true"
    FALSE =             "false"
    NUMBER_MATCHER =    /[-+]?\d*\.?\d+([eE][-+]?\d+)?/
    SKIP_CHARS =        /[ \*\t\r\n,]+/
    SKIP_COMMENTS =     /\*/
    NEXT_QUOTE =        /\"|\\\".+\"/m
    ESCAPED =           /\\[\\bfnrt]/
    QUOTE_CHAR =        '"'
    ANY_NUMBER =        /[0-9]/
    START_OF_NULL =     'n'
    START_OF_TRUE =     't'
    START_OF_FALSE =    'f'
    START_OF_HASH =     '{'
    END_OF_HASH =       '}'
    START_OF_ARRAY =    '['
    END_OF_ARRAY =      ']'
    START_OF_COMMENT =  '*'
    
    def initialize(opts={})
      # TODO: setup options
      @builder_stack = []
      @options = opts
      @state = :wants_anything
      @callback = nil
      @nested_array_level = 0
      @nested_hash_level = 0
      @objects_found = 0
    end
    
    def found_string(str)
      set_value(str)
    end
    
    def found_number(number_str)
      if number_str.include?('.') || number_str.include?('E') || number_str.include?('e')
        set_value(Float(number_str))
      else
        set_value(Integer(number_str))
      end
    end
    
    def found_hash_start
      @nested_hash_level += 1
      set_value({})
    end
    
    def found_hash_key(key)
      if @options[:symbolize_keys]
        key = key.to_sym unless key == ''
        set_value(key) 
      else
        set_value(key)
      end
    end
    
    def found_hash_end
      @nested_hash_level -= 1
      if @builder_stack.size > 1
        @builder_stack.pop
      end
    end
    
    def found_array_start
      @nested_array_level += 1
      set_value([])
    end
    
    def found_array_end
      @nested_array_level -= 1
      if @builder_stack.size > 1
        @builder_stack.pop
      end
      @state = :wants_anything
    end
    
    def found_boolean(bool)
      set_value(bool)
    end
    
    def found_nil
      set_value(nil)
    end
    
    def on_parse_complete=(callback)
      @callback = callback
    end
    
    def parse(str_or_io, &block)
      @callback = block if block_given?
      if str_or_io.is_a?(String)
        internal_parse(str_or_io)
      elsif str_or_io.respond_to?(:read)
        internal_parse(str_or_io.read)
        # TODO: not supported yet
        # while str = str_or_io.read(READ_BUFFER_SIZE)
        #   internal_parse(str)
        # end
      end
    end
    alias :<< :parse
    
    protected
      def internal_parse(str)
        scanner = StringScanner.new(str)
        while !scanner.eos? && (char = scanner.peek(1))
          case char
          when QUOTE_CHAR
            # grabs the contents of a string between " and ", even escaped strings
            scanner.pos += 1 # don't need the wrapping " char
            current = scanner.scan_until(NEXT_QUOTE)
            current.gsub!(ESCAPED) { |match| match if match = UNESCAPE_MAP[$&[1]] }
            current.unescape_utf8!
            current = current[0,current.size-1] if current[current.size-1,1] == "\""
            if @state == :wants_hash_key
              found_hash_key(current)
            else
              found_string(current)
            end
          when ANY_NUMBER
            if scanner.check_until(NUMBER_MATCHER)
              found_number(scanner.scan_until(NUMBER_MATCHER))
            end
          when START_OF_NULL
            if scanner.peek(4) == NULL
              found_nil
              scanner.pos = scanner.pos+4
            end
          when START_OF_TRUE
            if scanner.peek(4) == TRUE
              found_boolean(true)
              scanner.pos = scanner.pos+4
            end
          when START_OF_FALSE
            if scanner.peek(5) == FALSE
              found_boolean(false)
              scanner.pos = scanner.pos+5
            end
          when START_OF_HASH
            found_hash_start
            scanner.pos = scanner.pos+1
          when END_OF_HASH
            found_hash_end
            scanner.pos = scanner.pos+1
          when START_OF_ARRAY
            found_array_start
            scanner.pos = scanner.pos+1
          when END_OF_ARRAY
            found_array_end
            scanner.pos = scanner.pos+1
          when START_OF_COMMENT # is this a comment?
            if @options[:allow_comments]
              scanner.pos += 1
              scanner.skip_until(SKIP_COMMENTS)
            else
              raise ParseError, "Found a comment in the JSON source, but allow_comments wasn't turned on."
            end
          else
            if @state == :wants_hash_key && char == ':'
              raise ParseError, "Expected the start of a Hash key but got #{char} instead."
            end
            # try to skip multiple chars instead of just one char at a time
            # but fall back to skipping one at a time
            scanner.skip(SKIP_CHARS) || scanner.pos += 1
          end
        end
        
        unless @callback.nil?
          check_and_fire_callback
        else
          @builder_stack.pop
        end
      end
    
      def set_value(value)
        len = @builder_stack.size
        if len > 0
          if @builder_stack.last.is_a?(Array)
            @builder_stack.last << value
            if value.is_a?(Hash) or value.is_a?(Array)
              @builder_stack << value
            end
          elsif @builder_stack.last.is_a?(Hash)
            @builder_stack.last[value] = nil
            @builder_stack << value
          elsif @builder_stack.last.is_a?(String) or @builder_stack.last.is_a?(Symbol)
            hash = @builder_stack[len-2]
            if hash.is_a?(Hash)
              hash[@builder_stack.last] = value
              @builder_stack.pop
              if value.is_a?(Hash) or value.is_a?(Array)
                @builder_stack << value
              end
            end
          end
        else
          @builder_stack << value
        end
        
        if @builder_stack.last.is_a?(Hash)
          @state = :wants_hash_key
        elsif @builder_stack.last.is_a?(Array)
          @state = :wants_array_value
        else
          @state = :wants_anything
        end
      end
      
      def check_and_fire_callback
        if !@callback.nil?
          if @builder_stack.size == 1 && @nested_array_level == 0 && @nested_hash_level == 0
            @callback.call(@builder_stack.pop)
          end
        else
          if @builder_stack.size == 1 && @nested_array_level == 0 && @nested_hash_level == 0
            @objects_found += 1
            if @objects_found > 1
              raise ParseError, "Found multiple JSON objects in the stream but no block or the on_parse_complete callback was assigned to handle them."
            end
          end
        end
      end
  end
end