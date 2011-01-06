# types.rb - Classes generated by an XDR definition
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

module XDR::Types
    class InvalidStateError < RuntimeError; end

    class Basic
        class << self; attr_accessor :xdrmethod; end

        attr_accessor :value

        def initialize(value = nil)
            self.value = value unless value.nil?
        end

        def read(xdr)
            self.value = xdr.send(self.class.xdrmethod)
        end

        def write(xdr)
            raise InvalidStateError if @value.nil?
            xdr.send(self.class.xdrmethod, @value)
        end

        def to_s
            @value.to_s
        end

        def to_i
            @value.to_i
        end

        def coerce(o)
            @value.coerce(o)
        end
    end

    class Enumeration
        class << self; attr_accessor :values; end

        attr_accessor :value

        def initialize(value = nil)
            self.value = value unless value.nil?
        end

        def read(xdr)
            self.value = xdr.int32()
        end

        def write(xdr)
            raise InvalidStateError if @value.nil?
            xdr.int32(@value)
        end

        def value=(value)
            raise ArgumentError, "#{value} is not a permitted " +
                "value for enumeration" \
                unless self.class.values.include?(value)
            @value = value
        end

        def to_s
            @value.to_s
        end

        def to_i
            @value.to_i
        end

        def coerce(o)
            @value.coerce(o)
        end
    end

    class Opaque
        class << self; attr_accessor :length; end

        attr_accessor :value

        def initialize(value = nil)
            self.value = value unless value.nil?
        end

        def read(xdr)
            @value = xdr.bytes(self.class.length)
        end

        def write(xdr)
            raise InvalidStateError if @value.nil?
            xdr.bytes(@value)
        end

        def value=(value)
            raise ArgumentError, "Value of this opaque " +
                "must be #{self.class.length} bytes" \
                unless value.length == self.class.length

            @value = value
        end

        def to_s
            @value.to_s
        end
    end

    class VarOpaque
        class << self; attr_accessor :maxlen; end

        attr_accessor :value

        def initialize(value = nil)
            self.value = value unless value.nil?
        end

        def read(xdr)
            self.value = xdr.var_bytes()
        end

        def write(xdr)
            raise InvalidStateError if @value.nil?
            xdr.var_bytes(@value)
        end

        def value=(value)
            raise ArgumentError, "Value of this opaque must not " +
                "exceed #{self.class.maxlen} bytes" \
                if !self.class.maxlen.nil? &&
                   value.length > self.class.maxlen

            @value = value
        end

        def to_s
            @value.to_s
        end
    end

    class String
        class << self; attr_accessor :maxlen; end

        attr_accessor :value

        def initialize(value = nil)
            self.value = value unless value.nil?
        end

        def read(xdr)
            self.value = xdr.string()
        end

        def write(xdr)
            raise InvalidStateError if @value.nil?
            xdr.string(@value)
        end

        def value=(value)
            raise ArgumentError, "Value of this string must not " +
                "exceed #{self.class.maxlen} bytes" \
                if !self.class.maxlen.nil? &&
                   value.length > self.class.maxlen

            @value = value
        end

        def to_s
            @value.to_s
        end

        def to_i
            @value.to_i
        end
    end

    class GenericArray
        class << self; attr_accessor :type; end

        attr_accessor :value

        def initialize(value = nil)
            @value = []

            if !value.nil? then
                raise ArgumentError, "Initial value of array " +
                    "type must be an array" \
                    unless value.is_a?(Object::Array)

                value.each { |i|
                    self.push(i)
                }
            end
        end

        def push(*o)
            o.each { |i|
                i = self.class.type.new(i) unless i.is_a?(self.class.type)
                @value.push(i)
            }
        end

        def []=(i, o)
            o = self.class.type.new(o) unless o.is_a?(self.class.type)
            @value[i] = o
        end

        def [](i)
            @value[i]
        end

        def length
            @value.length
        end

        def to_s
            @value.to_s
        end

        def to_a
            @value.to_a
        end

        private

        def readraw(xdr, length)
            (1..length).each { |i|
                element = xdr.read(self.class.type)
                value.push(element)
            }
            value
        end

        def writeraw(xdr)
            @value.each { |i|
                xdr.write(i)
            }
        end
    end

    class Array < GenericArray
        class << self; attr_accessor :length; end

        def read(xdr)
            readraw(xdr, self.class.length)
        end

        def write(xdr)
            raise InvalidStateError, "Value of array type must be an " +
                "array of length #{self.class.length}" \
                unless @value.length == self.class.length

            writeraw(xdr)
        end
    end

    class VarArray < GenericArray
        class << self; attr_accessor :maxlen; end

        def read(xdr)
            length = xdr.uint32()
            checklen(length)
            readraw(xdr, length)
        end

        def write(xdr)
            checklen(@value.length)
            xdr.uint32(@value.length)
            writeraw(xdr)
        end

        private

        def checklen(length)
            raise InvalidStateError, "Value of array type must be an " +
                "array of maximum length #{self.class.maxlen}" \
                if !self.class.maxlen.nil? && length > self.class.maxlen
        end
    end

    class Structure
        class << self; attr_accessor :fields, :classes; end

        # fields is an array of [class, name] pairs
        def self.init(fields)
            self.fields = []
            self.classes = []

            # Create an accessor pair for each defined field
            fields.each { |i|
                klass = i.first
                name = i.last

                # Skip over voids
                next if name.nil?

                self.fields.push(name)
                self.classes.push(klass)

                var = ("@" + name.to_s).to_sym

                attr_reader(name)

                # The setter will instantiate a new object of the correct type
                # if required
                define_method((name.to_s + "=").to_sym, lambda { |value|
                    value = klass.new(value) unless value.is_a?(klass)
                    instance_variable_set(var, value)
                })
            }
        end

        def initialize(values = nil)
            values.each_pair { |name,value|
                method = (name.to_s + "=").to_sym

                raise ArgumentError, "Field #{name.to_s} has not been " +
                    "defined for this class" \
                    unless self.class.method_defined?(method)

                self.send(method, value)
            } unless values.nil?
        end

        def read(xdr)
            i = 0
            while (i < self.class.fields.length) do
                field = self.class.fields[i]
                klass = self.class.classes[i]

                method = (field.to_s + "=").to_sym
                self.send(method, xdr.read(klass))

                i += 1
            end
        end

        def write(xdr)
            i = 0
            while (i < self.class.fields.length) do
                field = self.class.fields[i]
                klass = self.class.classes[i]

                value = self.send(field)
                raise InvalidStateError, "Field #{field.to_s} has not been " +
                    "set" \
                    if value.nil?

                xdr.write(value)

                i += 1
            end
        end
    end
end
