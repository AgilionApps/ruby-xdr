#include <rpc/xdr.h>
#include <stdio.h>
#include <string.h>

int
main(int argc, char *argv[])
{
    XDR xdr;

    FILE *test = fopen("test/test.ref", "w");

    xdrstdio_create(&xdr, test, XDR_ENCODE);

    int32_t i;
    uint32_t ui;
    int64_t h;
    uint64_t uh;
    float f;
    double d;
    char *buf = malloc(16);

    i = 0;      xdr_int32_t(&xdr, &i);
    i = 1;      xdr_int32_t(&xdr, &i);
    i = -1;     xdr_int32_t(&xdr, &i);

    ui = 0;     xdr_uint32_t(&xdr, &ui);
    ui = 1;     xdr_uint32_t(&xdr, &ui);

    h = 0;      xdr_int64_t(&xdr, &h);
    h = 1;      xdr_int64_t(&xdr, &h);
    h <<= 32;   xdr_int64_t(&xdr, &h);
    h = -h;     xdr_int64_t(&xdr, &h);
    h = -1;     xdr_int64_t(&xdr, &h);

    uh = 0;     xdr_uint64_t(&xdr, &uh);
    uh = 1;     xdr_uint64_t(&xdr, &uh);
    uh <<= 32;  xdr_uint64_t(&xdr, &uh);

    f = 0;      xdr_float(&xdr, &f);
    f = 1.0;    xdr_float(&xdr, &f);
    f = -1.0;   xdr_float(&xdr, &f);
    f = 0x10000000; xdr_float(&xdr, &f);

    d = 0;      xdr_double(&xdr, &d);
    d = 1.0;    xdr_double(&xdr, &d);
    d = -1.0;   xdr_double(&xdr, &d);
    d = 0x10000000; xdr_double(&xdr, &d);

    strcpy(buf, "12341234");
    xdr_string(&xdr, &buf, 256);
    strcpy(buf, "123412341");
    xdr_string(&xdr, &buf, 256);
    strcpy(buf, "1234123");
    xdr_string(&xdr, &buf, 256);

    memcpy(buf, "\0\1\2\3\0\1\2\3\0", 9);
    xdr_opaque(&xdr, buf, 8);
    xdr_opaque(&xdr, buf, 9);
    xdr_opaque(&xdr, buf, 7);

    unsigned int size;

    size = 8; xdr_bytes(&xdr, &buf, &size, 128);
    size = 9; xdr_bytes(&xdr, &buf, &size, 128);
    size = 7; xdr_bytes(&xdr, &buf, &size, 128);

    xdr_destroy(&xdr);

    return 0;
}
