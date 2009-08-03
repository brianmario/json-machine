# encoding: UTF-8

class String
  
  # This was ported from Yajl (http://github.com/lloyd/yajl)
  # The reason for this is because Ruby 1.8's Iconv class, nor 1.9's native Unicode
  # implementation seemed to support surrogate characters (I may be wrong about that)
  # The example below would throw exceptions on *every* attempt I'd tried to decode it.
  # But Yajl decodes it fine, so I ported it's decoding logic into pure Ruby for us all
  # to enjoy :)
  #
  # Takes an escaped string such as:
  #   "\u004d\u0430\u4e8c\ud800\udf02"
  #
  # And returns a new unescaped UTF-8 string like:
  #   MÐ°äºŒí €í¼‚
  #
  def unescape_utf8
    utf8Buf = nil
    scanner = StringScanner.new(self)
    while !scanner.eos?
      if scanner.getch == "\\" && scanner.getch == "u"
        utf8Buf ||= ""
        codepoint = scanner.peek(4).to_i(16)
        scanner.pos += 4
        
        # check if this is a surrogate
        if ((codepoint & 0xFC00) == 0xD800)
          if scanner.getch == "\\" && scanner.getch == "u"
            surrogate = scanner.peek(4).to_i(16)
            scanner.pos += 4
            codepoint = (((codepoint & 0x3F) << 10) |
                        ((((codepoint >> 6) & 0xF) + 1) << 16) |
                        (surrogate & 0x3FF))
          end
        end
        
        if (codepoint < 0x80)
          utf8Buf << codepoint
        elsif (codepoint < 0x0800)
          utf8Buf << ((codepoint >> 6) | 0xC0)
          utf8Buf << ((codepoint & 0x3F) | 0x80)
        elsif (codepoint < 0x10000)
          utf8Buf << ((codepoint >> 12) | 0xE0)
          utf8Buf << (((codepoint >> 6) & 0x3F) | 0x80)
          utf8Buf << ((codepoint & 0x3F) | 0x80)
        elsif (codepoint < 0x200000)
          utf8Buf << ((codepoint >> 18) | 0xF0)
          utf8Buf << (((codepoint >> 12) & 0x3F) | 0x80)
          utf8Buf << (((codepoint >> 6) & 0x3F) | 0x80)
          utf8Buf << ((codepoint & 0x3F) | 0x80)
        else
          utf8Buf << '?'
        end
        
      end
    end
    utf8Buf.nil? ? self : utf8Buf
  end
end