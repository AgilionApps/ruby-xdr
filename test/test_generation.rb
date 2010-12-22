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

        p.load('Mod::SubMod')

        assert_equal(Mod::SubMod::A, 1)
        assert_equal(Mod::SubMod::B, 1)
    end

    def test_constant_loop
        p = XDR::Parser.new(StringIO.new(<<TEST))
const a = b;
const b = c;
const c = a;
TEST

        assert_raise(XDR::ConstantDefinitionLoop) do
            p.load('Mod::SubMod')
        end
    end
end
