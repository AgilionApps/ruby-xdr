require 'test/unit'
require 'stringio'

require 'xdr'
require 'xdr/parser'

class GeneratorTest < Test::Unit::TestCase
    def test_enum
        p = XDR::Parser.new(StringIO.new("enum a { A, B };"))
        p.load('GeneratorTest::Test_enum0')

        assert_equal(GeneratorTest::Test_enum0::A::A, 0)
        assert_equal(GeneratorTest::Test_enum0::A::B, 1)

        assert_nothing_raised do
            GeneratorTest::Test_enum0::A.new()
            GeneratorTest::Test_enum0::A.new(0)
            GeneratorTest::Test_enum0::A.new(1)
        end

        assert_raise(ArgumentError) do
            GeneratorTest::Test_enum0::A.new(2)
        end

        p = XDR::Parser.new(StringIO.new(<<TEST))
enum a {
    A,
    B,
    C = 5,
    D,
    E = FOO,
    F
};
const FOO = B;
TEST
        p.load('GeneratorTest::Test_enum1')

        assert_equal(GeneratorTest::Test_enum1::A::A, 0);
        assert_equal(GeneratorTest::Test_enum1::A::B, 1);
        assert_equal(GeneratorTest::Test_enum1::A::C, 5);
        assert_equal(GeneratorTest::Test_enum1::A::D, 6);
        assert_equal(GeneratorTest::Test_enum1::A::E, 1);
        assert_equal(GeneratorTest::Test_enum1::A::F, 2);

        p = XDR::Parser.new(StringIO.new(<<TEST))
enum a {
    A,
    B = FOO,
    C
};
const FOO = C;
TEST

        assert_raise(XDR::ConstantDefinitionLoop) do
            p.load('GeneratorTest::Test_enum2')
        end
    end

    def test_constant
        p = XDR::Parser.new(StringIO.new(<<TEST))
const b = a;
const a = 1;
TEST

        p.load('GeneratorTest::Test_constant')

        assert_equal(GeneratorTest::Test_constant::A, 1)
        assert_equal(GeneratorTest::Test_constant::B, 1)
    end

    def test_constant_loop
        p = XDR::Parser.new(StringIO.new(<<TEST))
const a = b;
const b = c;
const c = a;
TEST

        assert_raise(XDR::ConstantDefinitionLoop) do
            p.load('GeneratorTest::Test_constant_loop')
        end
    end

    def test_typedef
        p = XDR::Parser.new(StringIO.new(<<TEST))
enum a { A, B };
typedef a b;
TEST

        assert_nothing_raised do
            p.load('GeneratorTest::Test_typedef0')

            assert_equal(GeneratorTest::Test_typedef0::A::A, 0);
            assert_equal(GeneratorTest::Test_typedef0::B::A, 0);
        end

        p = XDR::Parser.new(StringIO.new(<<TEST))
typedef a b;
typedef b c;
typedef c a;
TEST

        assert_raise(XDR::TypeDefinitionLoop) do
            p.load('GeneratorTest::Test_typedef1')
        end
    end
end
