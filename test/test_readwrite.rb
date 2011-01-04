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

    def test_basics
        p = XDR::Parser.new(StringIO.new(<<TEST))
typedef int myint;
typedef unsigned int myuint;
typedef hyper myhyper;
typedef unsigned hyper myuhyper;
typedef float myfloat;
typedef double mydouble;
typedef quadruple myquad;
TEST

        assert_nothing_raised do
            p.load('ReadWriteTest::Test_basics0')
        end

        io = StringIO.new("")
        w = XDR::Writer.new(io)

        int = ReadWriteTest::Test_basics0::Myint.new(13)
        assert_equal(int.value, 13)
        w.write(int)

        uint = ReadWriteTest::Test_basics0::Myuint.new(14)
        assert_equal(uint.value, 14)
        w.write(uint)

        hyper = ReadWriteTest::Test_basics0::Myhyper.new(15)
        assert_equal(hyper.value, 15)
        w.write(hyper)

        uhyper = ReadWriteTest::Test_basics0::Myuhyper.new(16)
        assert_equal(uhyper.value, 16)
        w.write(uhyper)

        float = ReadWriteTest::Test_basics0::Myfloat.new(17)
        assert_equal(float.value, 17)
        w.write(float)

        double = ReadWriteTest::Test_basics0::Mydouble.new(18)
        assert_equal(double.value, 18)
        w.write(double)

        quad = ReadWriteTest::Test_basics0::Myquad.new(19)
        assert_equal(quad.value, 19)
        assert_raise NotImplementedError do
            w.write(quad)
        end

        io.flush()
        io.rewind()

        r = XDR::Reader.new(io)

        int = ReadWriteTest::Test_basics0::Myint.new()
        r.read(int)
        assert_equal(int.value, 13)

        uint = ReadWriteTest::Test_basics0::Myuint.new()
        r.read(uint)
        assert_equal(uint.value, 14)

        hyper = ReadWriteTest::Test_basics0::Myhyper.new()
        r.read(hyper)
        assert_equal(hyper.value, 15)

        uhyper = ReadWriteTest::Test_basics0::Myuhyper.new()
        r.read(uhyper)
        assert_equal(uhyper.value, 16)

        float = ReadWriteTest::Test_basics0::Myfloat.new()
        r.read(float)
        assert_equal(float.value, 17)

        double = ReadWriteTest::Test_basics0::Mydouble.new()
        r.read(double)
        assert_equal(double.value, 18)

        quad = ReadWriteTest::Test_basics0::Myquad.new()
        assert_raise NotImplementedError do
            r.read(quad)
        end

        assert(io.eof?)
    end
end
