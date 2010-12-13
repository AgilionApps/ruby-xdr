require 'test/unit'
require 'stringio'
require 'fileutils'

require 'xdr'

FILENAME = "test/test.out"

# Test values for each type
INT32   = [ 0, 1, -1 ]                              # 00
UINT32  = [ 0, 1 ]                                  # 0C
INT64   = [ 0, 1, 2**32, -2**32, -1 ]               # 14
UINT64  = [ 0, 1, 2**32 ]                           # 3C
FLOAT32 = [ 0, 1, -1, 0x10000000 ]                  # 4C
FLOAT64 = [ 0, 1, -1, 0x10000000 ]                  # 5C
STRING  = [ "12341234", "123412341", "1234123" ]
BYTES   = [ "\000\001\002\003\000\001\002\003",
            "\000\001\002\003\000\001\002\003\000",
            "\000\001\002\003\000\001\002" ]

#
# Generate test output to be compared to the output of test.ref
#

class RefTest < Test::Unit::TestCase
    def test_all
        testout = ""
        xdr = XDR::Writer.new(StringIO.new(testout, "w"))

        # Write the same data as is written by the reference generator
        INT32.each      { |n| check_write(n, xdr, 'int32') }
        UINT32.each     { |n| check_write(n, xdr, 'uint32') }
        INT64.each      { |n| check_write(n, xdr, 'int64') }
        UINT64.each     { |n| check_write(n, xdr, 'uint64') }
        FLOAT32.each    { |n| check_write(n, xdr, 'float32') }
        FLOAT64.each    { |n| check_write(n, xdr, 'float64') }
        STRING.each     { |n| check_write(n, xdr, 'string') }
        BYTES.each      { |n| check_write(n, xdr, 'bytes') }
        BYTES.each      { |n| check_write(n, xdr, 'var_bytes') }

        # Check we can read our own test output
        xdr = XDR::Reader.new(StringIO.new(testout, "r"))

        INT32.each      { |n| check_read(n, xdr, 'int32') }
        UINT32.each     { |n| check_read(n, xdr, 'uint32') }
        INT64.each      { |n| check_read(n, xdr, 'int64') }
        UINT64.each     { |n| check_read(n, xdr, 'uint64') }
        FLOAT32.each    { |n| check_read(n, xdr, 'float32') }
        FLOAT64.each    { |n| check_read(n, xdr, 'float64') }
        STRING.each     { |n| check_read(n, xdr, 'string') }
        BYTES.each      { |n| check_read(n, xdr, 'bytes', n.length) }
        BYTES.each      { |n| check_read(n, xdr, 'var_bytes') }

        # Check that the output is identical to the reference output
        ref = File.open("test/test.ref", "r")
        assert(FileUtils.compare_stream(ref, StringIO.new(testout, "r")))
    end

    private

    def check_write(n, xdr, type)
        assert_nothing_raised do
            c = xdr.method(type)
            c.call(n)
        end
    end

    def check_read(n, xdr, type, arg=nil)
        c = xdr.method(type)

        r = arg.nil? ? c.call() : c.call(arg)
        assert_equal(n, r)
    end
end
