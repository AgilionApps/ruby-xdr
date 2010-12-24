# ast.rb - An AST for the XDR language
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

require 'set'

module XDR::AST
    class Type
        attr_reader :context

        def initialize(context)
            @context = context
        end

        def generate(mod, parser, visited = nil); end
    end

    # Basic types
    class Integer < Type; end
    class UnsignedInteger < Type; end
    class Boolean < Type; end
    class Hyper < Type; end
    class UnsignedHyper < Type; end
    class Float < Type; end
    class Double < Type; end
    class Quadruple < Type; end
    class Void < Type; end

    # Complex types
    class Enumeration < Type
        attr_reader :values

        def initialize(context, parser, values)
            super(context)
            @values = []
            prev = nil
            values.each { |i|
                name = i[0]
                value = i[1]

                c = EnumerationConstant.new(name.context, parser,
                                            prev, name, value)
                prev = c
                @values.push(c)
            }
            @klass = nil
        end

        def generate(mod, parser, visited = nil)
            return @klass unless @klass.nil?

            @klass = Class.new()
            @klass.class_eval do
                class << self; attr_accessor :values; end

                def initialize(value = nil)
                    @value = value
                    unless value.nil?
                        raise ArgumentError, "#{value} is not a permitted " +
                            "value for enumeration" \
                            unless self.class.values.include?(value)
                    end
                end
            end
            @klass.values = Set.new()
            @values.each { |i|
                val = i.value

                @klass.const_set(i.name.value, val)
                @klass.values.add(val)
            }

            @klass
        end
    end


    class EnumerationConstant < Type
        attr_reader :name

        def initialize(context, parser, prev, name, value)
            super(context)
            @prev = prev
            @name = name
            @value = value

            parser.add_constant(name.value, self)
        end

        def value(visited = Set.new())
            raise XDR::ConstantDefinitionLoop.new("Loop detected in " +
                "definition of constant #{@name.value}", @name.context) \
                if visited.include?(self)
            visited.add(self)

            if @value.nil? then
                # No explicit value. 1 greater than the previous value.
                val = @prev.nil? ? 0 : @prev.value(visited) + 1

                # Cache the value
                @value = XDR::Token.new(val, nil)
                return val
            end

            if @value.is_a?(XDR::Token) then
                return @value.value
            else
                return @value.value(visited)
            end
        end
    end

    class Opaque < Type
        attr_reader :length

        def initialize(context, length)
            super(context)
            @length = length
        end
    end

    class VarOpaque < Type
        attr_reader :max

        def initialize(context, max = nil)
            super(context)
            @max = max
        end
    end

    class String < Type
        attr_reader :max

        def initialize(context, max = nil)
            super(context)
            @max = max
        end
    end

    class Array < Type
        attr_reader :type, :length

        def initialize(context, type, length)
            super(context)
            @type = type
            @length = length
        end
    end

    class VarArray < Type
        attr_reader :type, :max

        def initialize(context, type, max = nil)
            super(context)
            @type = type
            @max = max
        end
    end

    class Structure < Type
        attr_reader :fields

        def initialize(context, fields)
            super(context)
            @fields = fields
        end
    end

    class Union < Type
        attr_reader :switch, :cases, :default

        def initialize(context, switch, cases, default = nil)
            super(context)
            @switch = switch
            @cases = cases
            @default = default
        end
    end

    class Optional < Type
        attr_reader :type

        def initialize(context, type)
            super(context)
            @type = type
        end
    end

    class Constant < Type
        attr_reader :name

        def initialize(context, parser, name, value)
            super(context)
            @name = name
            @value = value

            parser.add_constant(name.value, self)
        end

        def generate(mod, parser, visited = nil)
            mod.const_set(name.value.capitalize(), @value.value)
        end

        def value(visited = nil)
            if @value.is_a?(XDR::Token) then
                @value.value
            else
                @value.value(visited)
            end
        end
    end

    class ConstRef < Type
        attr_reader :name

        def initialize(context, parser, name)
            super(context)
            @parser = parser
            @name = name
            @value = nil
        end

        def value(visited = Set.new())
            return @value unless @value.nil?

            raise XDR::ConstantDefinitionLoop.new("Loop detected in " +
                "definition of constant #{@name.value}", @name.context) \
                if visited.include?(self)
            visited.add(self)

            @value = @parser.lookup_constant(name).value(visited)
            @value
        end
    end

    class Typedef < Type
        attr_reader :name, :type

        def initialize(context, parser, name, type)
            super(context)
            @name = name
            @type = type
            @klass = nil

            # 'typedef void;' is valid, if pointless, syntax
            # Don't bother doing anything with it
            parser.add_type(name.value, self) unless name.nil?
        end

        def generate(mod, parser, visited = Set.new())
            return @klass unless @klass.nil?

            @klass = @type.generate(mod, parser, visited)
            # XXX type can only be nil because the implementation is not yet
            # complete. Remove this once the implementation is complete.
            mod.const_set(@name.value.capitalize(), @klass) unless @klass.nil?
            @klass
        end
    end

    class TypeRef < Type
        attr_reader :name

        def initialize(context, name)
            super(context)
            @name = name
            @type = nil
        end

        def generate(mod, parser, visited = Set.new())
            return @type unless @type.nil?

            raise XDR::TypeDefinitionLoop.new("Loop detected in " +
                "definition of type #{@name.value}", @name.context) \
                if visited.include?(self)
            visited.add(self)

            @type = parser.lookup_type(@name).generate(mod, parser, visited)
            @type
        end
    end
end
