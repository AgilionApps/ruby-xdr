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

require 'singleton'

module XDR::AST

    # Basic types
    class Integer; include Singleton; end
    class UnsignedInteger; include Singleton; end
    class Boolean; include Singleton; end
    class Hyper; include Singleton; end
    class UnsignedHyper; include Singleton; end
    class Float; include Singleton; end
    class Double; include Singleton; end
    class Quadruple; include Singleton; end
    class Void; include Singleton; end

    class Enumeration
        attr_reader :map

        def initialize(map)
            @map = map
        end
    end

    class Opaque
        attr_reader :length

        def initialize(length)
            @length = length
        end
    end

    class VarOpaque
        attr_reader :max

        def initialize(max = nil)
            @max = max
        end
    end

    class String
        attr_reader :max

        def initialize(max = nil)
            @max = max
        end
    end

    class Array
        attr_reader :type, :length

        def initialize(type, length)
            @type = type
            @length = length
        end
    end

    class VarArray
        attr_reader :type, :max

        def initialize(type, max = nil)
            @type = type
            @max = max
        end
    end

    class Structure
        attr_reader :fields

        def initialize(fields)
            @fields = fields
        end
    end

    class Union
        attr_reader :dtype, :cases, :default

        def initialize(dtype, cases, default = nil)
            @disc = dtype
            @cases = cases
            @default = default
        end
    end

    class Optional
        attr_reader :type

        def initialize(type)
            @type = type
        end
    end

    class Constant
        attr_reader :name, :value

        def initialize(name, value)
            @name = name
            @value = value
        end
    end

    class Typedef
        attr_reader :name, :type

        def initialize(name, type)
            @name = name
            @type = type
        end
    end

    class TypeRef
        attr_reader :name

        def initialize(name)
            @name = name
        end
    end

    class ConstRef
        attr_reader :name

        def initialize(name)
            @name = name
        end
    end
end
