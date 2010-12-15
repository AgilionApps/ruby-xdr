# parser_support.rb - Support for XDR language parsing
# Copyright (C) 2010 Red Hat Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

require 'strscan'

class XDR::Parser
    def parse()
        # Set this to true to enable parser debugging
        @yydebug = false

        begin
            yyparse(@lexer, :scan)
        rescue Racc::ParseError => e
            raise XDR::ParseError, @lexer.errormsg(e.message)
        end
    end

    private

    def initialize(io)
        @lexer = XDR::Lexer.new(io)
    end
end

class XDR::Lexer
    def scan
        tok = next_token
        until tok.nil? do
            if KEYWORDS.has_key?(tok) then
                sym = KEYWORDS[tok]
                yield [ sym, sym]

            # An identifier is a letter followed by an optional sequence of
            # letters, digits, or underbar ('_').
            elsif tok =~ /^[a-zA-Z][a-zA-Z0-9_]*$/ then
                yield [ :IDENT, tok ]

            # An integer constant in hex, decimal, or octal
            elsif tok =~ /^-?(0x[0-9a-fA-F]+|[1-9][0-9]*|0[0-7]*)$/ then
                begin
                    val = Integer(tok)
                    yield [ :CONSTANT, val ]
                rescue ArgumentError => e
                    raise XDR::ParseError, \
                        self.errormsg("Invalid constant #{tok}")
                end
            
            elsif tok =~ MATCH_SYMBOL then
                yield [ tok, tok ]

            else
                raise XDR::ParseError, \
                    self.errormsg("Invalid token #{tok}")
            end

            tok = next_token
        end

        yield [false, false]
    end

    def errormsg(msg)
        msg + " at line #{@line}, character #{@char}"
    end

    private

    KEYWORDS = {
        # Keywords from RFC 4506
        'bool'      => :BOOL,
        'case'      => :CASE,
        'const'     => :CONST,
        'default'   => :DEFAULT,
        'double'    => :DOUBLE,
        'enum'      => :ENUM,
        'float'     => :FLOAT,
        'hyper'     => :HYPER,
        'int'       => :INT,
        'opaque'    => :OPAQUE,
        'quadruple' => :QUADRUPLE,
        'string'    => :STRING,
        'struct'    => :STRUCT,
        'switch'    => :SWITCH,
        'typedef'   => :TYPEDEF,
        'union'     => :UNION,
        'unsigned'  => :UNSIGNED,
        'void'      => :VOID,

        # Keywords from RFC 5531, reserved but not used
        'program'   => :PROGRAM,
        'version'   => :VERSION,

        # Keywords implicit in definition of Boolean
        'FALSE'     => :FALSE,
        'TRUE'      => :TRUE
    }

    SYMBOLS = '\[\]<>*{}=,;():'
    MATCH_SYMBOL = /[#{SYMBOLS}]/
    SCAN_SYMBOLS = /[#{SYMBOLS}]|[^#{SYMBOLS}]+/

    def initialize(io)
        @io = io
        @line = 0
        @char = 0
        @scanner = nil
        @toks = []
        @lasttoklen = 0
    end

    def next_token
        if @toks.length > 0 then
            @char += @lasttoklen
            @lasttoklen = @toks.first.length
            return @toks.shift
        end

        tok = nil
        while tok.nil? do
            if @scanner.nil? || @scanner.eos? then
                begin
                    buf = @io.readline
                    @scanner = StringScanner.new(buf)
                    @line += 1
                rescue EOFError
                    return nil
                end
            end

            # Skip whitespace
            @scanner.scan(/\s*/)
            @char = @scanner.pos 
            tok = @scanner.scan(/\S+/)
        end

        # Symbols don't have to be separated by whitespace. Break the token down
        # into individual symbols, and the characters in between them
        @toks = tok.scan(SCAN_SYMBOLS)
        @lasttoklen = @toks.first.length
        @toks.shift
    end
end
