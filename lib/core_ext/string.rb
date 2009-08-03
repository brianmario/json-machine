# encoding: UTF-8

# This was ported from Yajl (http://github.com/lloyd/yajl)
# The reason for this is because Ruby 1.8's pack/unpack("U"), nor 1.9's native Unicode
# implementation seemed to support surrogate characters (I may be wrong about that...)
# The example below would throw exceptions on *every* attempt I'd tried to decode it.
# But Yajl decodes it fine, so I ported it's decoding logic into pure Ruby for us all
# to enjoy :)
#
#
# Ruby 1.8
#  puts "\u004d\u0430\u4e8c\ud800\udf02".split("\u").map {|char|
#         [char.to_i(16)].pack("U") unless char == ""
#       }.compact.join("")
#  => MÐ°äºŒ??????
#
# Ruby 1.9
#  puts "\u004d\u0430\u4e8c\ud800\udf02"
#  => MÐ°äºŒ??????
#
# Ruby 1.8 or 1.9 using this method
#  puts "\u004d\u0430\u4e8c\ud800\udf02".unescape_utf8
#  => MÐ°äºŒí €í¼‚
#

class String
  # This method takes an escaped string such as:
  #   "\u004d\u0430\u4e8c\ud800\udf02"
  #
  # And returns a new unescaped UTF-8 string like:
  #   MÐ°äºŒí €í¼‚
  def unescape_utf8
    utf8Buf = ""
    utf8Buf.force_encoding("binary") if utf8Buf.respond_to?(:force_encoding)
    scanner = StringScanner.new(self)
    while !scanner.eos?
      if scanner.getch == "\\" && scanner.getch == "u"
        codepoint = scanner.peek(4).hex
        scanner.pos += 4
        
        # check if this is a surrogate
        if ((codepoint & 0xFC00) == 0xD800)
          if scanner.getch == "\\" && scanner.getch == "u"
            surrogate = scanner.peek(4).hex
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
    utf8Buf == "" ? self : utf8Buf
  end
end