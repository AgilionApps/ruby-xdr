require 'test/unit'
require 'stringio'

require 'xdr'
require 'xdr/parser'

class ReadWriteTest < Test::Unit::TestCase
    def test_enum
        assert_nothing_raised do
            p = XDR::Parser.new(StringIO.new("enum a { A, B };"))
            p.load('ReadWriteTest::Test_enum0')

            io = StringIO.new("")
            w = XDR::Writer.new(io)

            e0 = ReadWriteTest::Test_enum0::A.new(ReadWriteTest::Test_enum0::A::B)
            assert_equal(e0.value, 1)
            w.write(e0)

            io.flush()
            io.rewind()

            r = XDR::Reader.new(io)
            e1 = ReadWriteTest::Test_enum0::A.new()
            r.read(e1)
            assert_equal(e1.value, 1)
        end
    end
end
