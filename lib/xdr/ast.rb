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

module XDR::AST
    class Type
        attr_reader :context

        def initialize(context)
            @context = context
        end
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
            values.each { |i|
                name = i[0]
                value = i[1]

                @values.push(EnumerationConstant.new(name.context, parser,
                                                     name, value))
            }
        end
    end

    class EnumerationConstant < Type
        attr_reader :name, :value

        def initialize(context, parser, name, value)
            super(context)
            @name = name
            @value = value

            parser.add_constant(name.value, self)
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
        attr_reader :dtype, :cases, :default

        def initialize(context, dtype, cases, default = nil)
            super(context)
            @disc = dtype
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
        attr_reader :name, :value

        def initialize(context, parser, name, value)
            super(context)
            @name = name
            @value = value

            parser.add_constant(name.value, self)
        end
    end

    class ConstRef < Type
        attr_reader :name

        def initialize(context, name)
            super(context)
            @name = name
        end
    end

    class Typedef < Type
        attr_reader :name, :type

        def initialize(context, parser, name, type)
            super(context)
            @name = name
            @type = type

            # 'typedef void;' is valid, if pointless, syntax
            # Don't bother doing anything with it
            parser.add_typedef(name.value, self) unless name.nil?
        end
    end

    class TypeRef < Type
        attr_reader :name

        def initialize(context, name)
            super(context)
            @name = name
        end
    end
end
