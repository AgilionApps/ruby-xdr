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

            assert_equal(0 + e0 + e1, 2)
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

        assert(0 + int + uint == 27)

        quad = ReadWriteTest::Test_basics0::Myquad.new()
        assert_raise NotImplementedError do
            r.read(quad)
        end

        assert(io.eof?)
    end

    def test_opaque
        p = XDR::Parser.new(StringIO.new(<<TEST))
typedef opaque myopaque[5];
TEST

        assert_nothing_raised do
            p.load('ReadWriteTest::Test_opaque0')
        end

        opaque0 = nil
        assert_raise ArgumentError do
            opaque0 = ReadWriteTest::Test_opaque0::Myopaque.new("foo")
        end
        opaque0 = ReadWriteTest::Test_opaque0::Myopaque.new()
        assert_raise ArgumentError do
            opaque0.value = "foo"
        end
        assert_nothing_raised do
            opaque0.value = "12345"
        end

        io = StringIO.new("")
        w = XDR::Writer.new(io)

        w.write(opaque0)

        io.flush()
        io.rewind()

        r = XDR::Reader.new(io)

        opaque1 = ReadWriteTest::Test_opaque0::Myopaque.new()
        r.read(opaque1)
        assert_equal(opaque1.value, "12345")

        assert(io.eof?)
    end

    def test_varopaque
        p = XDR::Parser.new(StringIO.new(<<TEST))
typedef opaque myopaque5<5>;
typedef opaque myopaque<>;
TEST

        assert_nothing_raised do
            p.load('ReadWriteTest::Test_varopaque0')
        end

        vo0 = nil
        assert_raise ArgumentError do
            vo0 = ReadWriteTest::Test_varopaque0::Myopaque5.new("123456")
        end
        vo0 = ReadWriteTest::Test_varopaque0::Myopaque5.new()
        assert_raise ArgumentError do
            vo0.value = "123456"
        end
        assert_nothing_raised do
            vo0.value = "1234"
            vo0.value = "12345"
        end

        vo1 = nil
        assert_nothing_raised do
            vo1 = ReadWriteTest::Test_varopaque0::Myopaque.new("123456")
        end

        io = StringIO.new("")
        w = XDR::Writer.new(io)

        w.write(vo0)
        w.write(vo1)

        io.flush()
        io.rewind()

        r = XDR::Reader.new(io)

        vo2 = ReadWriteTest::Test_varopaque0::Myopaque5.new()
        r.read(vo2)
        assert_equal(vo2.value, "12345")

        vo3 = ReadWriteTest::Test_varopaque0::Myopaque.new()
        r.read(vo3)
        assert_equal(vo3.value, "123456")

        assert(io.eof?)
    end

    def test_string
        p = XDR::Parser.new(StringIO.new(<<TEST))
typedef string s5<5>;
typedef string s<>;
TEST

        assert_nothing_raised do
            p.load('ReadWriteTest::Test_string0')
        end

        string0 = nil
        assert_raise ArgumentError do
            string0 = ReadWriteTest::Test_string0::S5.new("123456")
        end
        string0 = ReadWriteTest::Test_string0::S5.new()
        assert_raise ArgumentError do
            string0.value = "123456"
        end
        assert_nothing_raised do
            string0.value = "1234"
            string0.value = "12345"
        end

        string1 = nil
        assert_nothing_raised do
            string1 = ReadWriteTest::Test_string0::S.new("123456")
        end

        io = StringIO.new("")
        w = XDR::Writer.new(io)

        w.write(string0)
        w.write(string1)

        io.flush()
        io.rewind()

        r = XDR::Reader.new(io)

        string2 = ReadWriteTest::Test_string0::S5.new()
        r.read(string2)
        assert_equal(string2.value, "12345")

        string3 = ReadWriteTest::Test_string0::S.new()
        r.read(string3)
        assert_equal(string3.value, "123456")

        assert(io.eof?)
    end
end