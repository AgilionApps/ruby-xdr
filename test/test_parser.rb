require 'test/unit'
require 'stringio'

require 'xdr'
require 'xdr/parser'

class ParserTest < Test::Unit::TestCase
    # A set of definitions intended to test every branch of the BNF at least
    # once
    SUCCESS_TESTS = [
        #
        'typedef int a;
         typedef unsigned int b;',

        #
        'typedef hyper a1[5];',

        #
        'typedef unsigned hyper A_<b>;',

        #
        'typedef float abc<>;',

        #
        'typedef opaque a[071];',

        #
        'typedef opaque a<5>;',

        #
        'typedef opaque a<>;',

        #
        'typedef string a<>;',

        #
        'typedef string a<>;',

        #
        'typedef double *a;',

        #
        'typedef void;',

        #
        'enum foo {
            A = 1
         };',

        #
        'enum foo {
            A = 1,
            B,
            C = 5,
            D,
            LAST
         };',

        #
        'const myconst = 0xF;

         enum foo {
            A = 1,
            B = myconst
         };',

        #
        'struct foo {
            bool a;
         };',

        #
        'typedef string mystring<>;

         struct foo {
             enum { A = 1, B = 2 } a;
             struct {
                 int a;
             } b;
             union switch (bool a) {
                 case TRUE: int b;
             } c;
             union switch (int a) {
                 case -1:
                 case -0x1:    int b;
                 case -07:     int c;
                 case FALSE:   int d;
                 case 2:
                 case 3:       int e;
                 default: int d;
             } d;
             mystring e;
         };',

         #
         'union foo switch (enum { A = 1, B = 2 } a) {
             case 800: int b;
          };'
    ]

    FAILURE_TESTS = [
        #
        'const a = 1;
         const b = 2;
         const a = 3;',

        #
        'typedef int a;
         enum { a = 1, b = 2 } b;
         struct {
             int a;
             int b;
         } a;'
    ]

    def test_success
        SUCCESS_TESTS.each { |i|
            p = XDR::Parser.new(StringIO.new(i))
            assert_nothing_raised do
                p.parse
            end
        }
    end

    def test_failure
        FAILURE_TESTS.each { |i|
            p = XDR::Parser.new(StringIO.new(i))
            assert_raise(XDR::ParseError) do
                p.parse
            end
        }
    end
end
