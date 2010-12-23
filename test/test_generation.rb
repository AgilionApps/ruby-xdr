require 'test/unit'
require 'stringio'

require 'xdr'
require 'xdr/parser'

class ParserTest < Test::Unit::TestCase
    def test_constant
        p = XDR::Parser.new(StringIO.new(<<TEST))
const b = a;
const a = 1;
TEST

        p.load('ParserTest::Test_constant')

        assert_equal(ParserTest::Test_constant::A, 1)
        assert_equal(ParserTest::Test_constant::B, 1)
    end

    def test_constant_loop
        p = XDR::Parser.new(StringIO.new(<<TEST))
const a = b;
const b = c;
const c = a;
TEST

        assert_raise(XDR::ConstantDefinitionLoop) do
            p.load('ParserTest::Test_constant_loop')
        end
    end
end
