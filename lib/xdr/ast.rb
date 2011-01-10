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
require 'xdr/types'

module XDR::AST
    class Type
        attr_reader :context

        def initialize(context, base)
            @context = context
            @baseclass = base
            @generated = false
            @klass = nil
        end

        # Return the class which will be returned by generate()
        # It need not have been properly initialized
        # This method MUST NOT RECURSE, or it will lead to errors generating
        # recursive data structures
        def base()
            return nil if @baseclass.nil?

            return @klass unless @klass.nil?

            @klass = Class.new(@baseclass) if @klass.nil?
            @klass
        end


        def cached()
            self.base() if @klass.nil?
            return @klass if @generated

            @generated = true
            nil
        end
    end

    class Basic < Type
        def initialize(context, xdrmethod)
            super(context, XDR::Types::Basic)
            @xdrmethod = xdrmethod
        end

        def generate(mod, parser);
            # XXX: Only required because implementation is incomplete
            return nil if @xdrmethod.nil?

            raise RuntimeError, "Attempt to use default generator for " +
                "#{self.class.name} without being passed xdrmethod" \
                if @xdrmethod.nil?

            cached = self.cached()
            return cached unless cached.nil?

            @klass.xdrmethod = @xdrmethod
            @klass
        end
    end

    # Basic types
    class Integer < Basic;
        def initialize(context)
            super(context, :int32)
        end
    end

    class UnsignedInteger < Basic;
        def initialize(context)
            super(context, :uint32)
        end
    end

    class Boolean < Basic;
        def initialize(context)
            super(context, :bool)
        end
    end

    class Hyper < Basic;
        def initialize(context)
            super(context, :int64)
        end
    end

    class UnsignedHyper < Basic;
        def initialize(context)
            super(context, :uint64)
        end
    end

    class Float < Basic;
        def initialize(context)
            super(context, :float32)
        end
    end

    class Double < Basic;
        def initialize(context)
            super(context, :float64)
        end
    end

    class Quadruple < Basic;
        def initialize(context)
            super(context, :float128)
        end
    end

    class Void < Type;
        def initialize(context)
            super(context, nil)
        end

        def generate(mod, parser)
        end
    end

    # Complex types
    class Enumeration < Type
        attr_reader :values

        def initialize(context, parser, values)
            super(context, XDR::Types::Enumeration)
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
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.values = Set.new()
            @values.each { |i|
                val = i.value

                @klass.const_set(i.name.value, val)
                @klass.values.add(val)
            }

            @klass
        end
    end

    class EnumerationConstant
        attr_reader :name, :context

        def initialize(context, parser, prev, name, value)
            @context = context
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
            super(context, XDR::Types::Opaque)
            @length = Integer(length.value)
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.length = @length
            @klass
        end
    end

    class VarOpaque < Type
        attr_reader :max

        def initialize(context, maxlen = nil)
            super(context, XDR::Types::VarOpaque)
            @maxlen = Integer(maxlen.value) unless maxlen.nil?
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.maxlen = @maxlen
            @klass
        end
    end

    class String < Type
        attr_reader :max

        def initialize(context, maxlen = nil)
            super(context, XDR::Types::String)
            @maxlen = Integer(maxlen.value) unless maxlen.nil?
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.maxlen = @maxlen
            @klass
        end
    end

    class Array < Type
        attr_reader :type, :length

        def initialize(context, type, length)
            super(context, XDR::Types::Array)
            @type = type
            @length = Integer(length.value)
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.length = @length
            @klass.type = @type.generate(mod, parser)
            @klass
        end
    end

    class VarArray < Type
        attr_reader :type, :max

        def initialize(context, type, maxlen = nil)
            super(context, XDR::Types::VarArray)
            @type = type
            @maxlen = Integer(maxlen.value) unless maxlen.nil?
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.type = @type.generate(mod, parser)
            @klass.maxlen = @maxlen
            @klass
        end
    end

    class Structure < Type
        attr_reader :fields

        def initialize(context, fields)
            super(context, XDR::Types::Structure)
            @fields = fields
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            fields = []
            @fields.each { |i|
                type = i.first
                name = i.last.value.to_sym

                klass = type.generate(mod, parser)
                fields.push([klass, name])
            }
            @klass.init(fields)
            @klass
        end
    end

    class Union < Type
        attr_reader :switch, :cases, :default

        def initialize(context, switch, cases, default = nil)
            super(context, XDR::Types::Union)
            @switch = switch
            @cases = cases
            @default = default
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @switch[0] = @switch.first.generate(mod, parser)
            @switch[1] = @switch.last.to_s.to_sym

            @cases = @cases.map { |i|
                caselist = i.first.map { |j| j.value }
                decl = i.last
                klass = decl.first.generate(mod, parser)
                field = decl.last.to_s.to_sym unless decl.last.nil?

                [caselist, [klass, field]]
            }

            unless @default.nil? then
                @default[0] = @default.first.generate(mod, parser)
                @default[1] = @default.last.to_s.to_sym \
                    unless @default.last.nil?
            end

            @klass.init(@switch, @cases, @default)
            @klass
        end
    end

    class Optional < Type
        attr_reader :type

        def initialize(context, type)
            super(context, XDR::Types::Optional)
            @type = type
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            @klass.type = type.generate(mod, parser)
            @klass
        end
    end

    class Constant < Type
        attr_reader :name

        def initialize(context, parser, name, value)
            super(context, nil)
            @name = name
            @value = value

            parser.add_constant(name.value, self)
        end

        def generate(mod, parser)
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
            super(context, nil)
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

            @value = @parser.lookup_constant(@name).value(visited)
            @value
        end
    end

    class Typedef < Type
        attr_reader :name, :type

        def initialize(context, parser, name, type)
            super(context, nil)
            @name = name
            @type = type

            # 'typedef void;' is valid, if pointless, syntax
            # Don't bother doing anything with it
            parser.add_type(name.value, self) unless name.nil?
        end

        def generate(mod, parser)
            # Ignore 'typedef void'
            return if name.nil?

            cache = self.cached()
            return cache unless cache.nil?

            # Populate @klass before recursing
            @klass = @type.base

            @klass = @type.generate(mod, parser)
            # XXX type can only be nil because the implementation is not yet
            # complete. Remove this once the implementation is complete.
            mod.const_set(@name.value.capitalize(), @klass) unless @klass.nil?
            @klass
        end
    end

    class TypeRef < Type
        attr_reader :name

        def initialize(context, name)
            super(context, nil)
            @name = name
        end

        def generate(mod, parser)
            cache = self.cached()
            return cache unless cache.nil?

            typedef = resolve(parser)
            @klass = typedef.generate(mod, parser)
            @klass
        end

        private

        # Resolve this typeref into a typedef which isn't itself a typeref
        def resolve(parser)
            visited = Set.new()
            i = self
            loop do
                i = parser.lookup_type(i.name)

                return i unless i.type.is_a?(TypeRef)

                raise XDR::TypeDefinitionLoop.new("Loop detected in " +
                    "definition of type #{i.name.value}", i.name.context) \
                    if visited.include?(i)
                visited.add(i)
            end
        end
    end
end
