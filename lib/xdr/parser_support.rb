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

require 'xdr'

module XDR
    class ParseError < XDR::Error
        def initialize(msg, context)
            super("#{msg}: line #{context[0]}, character #{context[1]}")
        end
    end

    class DuplicateConstantError < ParseError; end
    class DuplicateTypedefError < ParseError; end
    class ConstantDefinitionLoop < ParseError; end
    class TypeDefinitionLoop < ParseError; end

    class Token
        attr_reader :value, :context

        def initialize(value, context)
            @value = value
            @context = context
        end

        def eql?(o)
            @value.eql?(o)
        end

        def hash
            @value.hash
        end

        def to_s
            @value.to_s
        end

        def to_i
            @value.to_i
        end
    end

    class Parser
        def load(modname)
            p = Object
            modname.split(/::/).each { |name|
                m = nil
                begin
                    m = p.const_get(name)
                rescue NameError
                    m = Module.new
                    p.const_set(name, m)
                end

                p = m
            }

            ast = parse()

            ast.each { |i|
                i.generate(p, self)
            }
        end

        def add_constant(name, node)
            if (@constants.has_key?(name)) then
                prev = @constants[name]
                raise DuplicateConstantError.new("Duplicate definition of " +
                    "constant #{name} at line #{node.context[0]}, " +
                    "char #{node.context[1]}",
                    prev.name.context)
            end
            @constants[name] = node
        end

        def lookup_constant(name, visited)
            raise NonExistentConstantError.new("Use of undefined " +
                "constant #{name.name}", name.context) \
                unless @constants.has_key?(name.value)

            @constants[name.value].value(visited)
        end

        def add_type(name, node)
            if (@typedefs.has_key?(name)) then
                prev = @typedefs[name]
                raise DuplicateTypedefError.new("Duplicate typedef #{name} " +
                    "at line #{node.context[0]}, char #{node.context[1]}",
                    prev.name.context)
            end
            @typedefs[name] = node
        end

        def lookup_type(name)
            raise NonExistentTypeError.new("Use of undefined type " +
                "#{name.name}", name.context) \
                unless @typedefs.has_key?(name.value)

            @typedefs[name.value]
        end

        private

        def initialize(io)
            @lexer = Lexer.new(io)
            @constants = {}
            @typedefs = {}
        end

        def parse()
            # Set this to true to enable parser debugging
            @yydebug = false

            begin
                return yyparse(@lexer, :scan)
            rescue Racc::ParseError => e
                raise ParseError.new(e.message, @lexer.context)
            end
        end
    end

    class Lexer
        def scan
            tok = next_token
            until tok.nil? do
                if KEYWORDS.has_key?(tok) then
                    sym = KEYWORDS[tok]
                    yield [ sym, Token.new(sym, self.context) ]

                # An identifier is a letter followed by an optional sequence of
                # letters, digits, or underbar ('_').
                elsif tok =~ /^[a-zA-Z][a-zA-Z0-9_]*$/ then
                    yield [ :IDENT, Token.new(tok, self.context) ]

                # An integer constant in hex, decimal, or octal
                elsif tok =~ /^-?(0x[0-9a-fA-F]+|[1-9][0-9]*|0[0-7]*)$/ then
                    begin
                        val = Integer(tok)
                        yield [ :CONSTANT, Token.new(val, self.context) ]
                    rescue ArgumentError => e
                        raise ParseError.new("Invalid constant #{tok}",
                                             self.context)
                    end
                
                elsif tok =~ MATCH_SYMBOL then
                    yield [ tok, Token.new(tok, self.context) ]

                else
                    raise ParseError.new("Invalid token #{tok}", self.context)
                end

                tok = next_token
            end

            yield [false, false]
        end

        def context
            [ @line, @char ]
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

            # Symbols don't have to be separated by whitespace. Break the token
            # down into individual symbols, and the characters in between them
            @toks = tok.scan(SCAN_SYMBOLS)
            @lasttoklen = @toks.first.length
            @toks.shift
        end
    end
end
