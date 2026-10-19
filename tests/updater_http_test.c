/* Host regression test: link with http.c, buffer.c and common.c.
 * The fake transport exercises both orderly EOF and negative read results. */
#include <stdio.h>
#include <string.h>
#include "../source/updater/release.h"
#include "../source/updater/tls.h"

struct AmgTlsConnection { size_t position; };
static struct AmgTlsConnection connection;
static const char *wire;
static int eof_result, failures;
static size_t read_chunk;

AmgTlsConnection *amg_tls_connect(const char *h, unsigned short p,
                                 unsigned long t, AmgError *e)
{ (void)h; (void)p; (void)t; (void)e; connection.position=0; return &connection; }
long amg_tls_read(AmgTlsConnection *c, void *d, size_t n, AmgError *e)
{
    size_t left=strlen(wire)-c->position;
    if (!left) {
        if (eof_result) amg_error_set(e,eof_result,"Transport failed.");
        return eof_result;
    }
    if (n>left) n=left;
    if (n>read_chunk) n=read_chunk;
    memcpy(d,wire+c->position,n); c->position+=n; return (long)n;
}
int amg_tls_write_all(AmgTlsConnection *c,const void *d,size_t n,AmgError *e)
{ (void)c; (void)d; (void)n; (void)e; return AMG_OK; }
void amg_tls_close(AmgTlsConnection *c) { (void)c; }

static void check(const char *name,const char *response,int end,size_t limit,
                  int expected,const char *expected_body)
{
    AmgBuffer body; AmgError error={0}; int result, pass;
    wire=response; eof_result=end; amg_buffer_init(&body);
    result=gru_fetch("https://example.test/",limit,&body,&error);
    pass=result==expected;
    if (expected_body) pass=pass && body.length==strlen(expected_body) &&
        !memcmp(body.data,expected_body,body.length) && error.code==AMG_OK;
    printf("%s (%zu-byte reads): %s\n",name,read_chunk,pass?"PASS":"FAIL");
    if (!pass) ++failures;
    amg_buffer_free(&body);
}
int main(void)
{
    size_t i; const size_t chunks[]={1,7,4096};
    for (i=0;i<sizeof(chunks)/sizeof(chunks[0]);++i) {
        read_chunk=chunks[i];
        check("Content-Length EOF","HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}",0,1024,AMG_OK,"{}");
        check("Content-Length unclean close","HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}",AMG_ERR_IO,1024,AMG_OK,"{}");
        check("Chunked EOF","HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n{}\r\n0\r\n\r\n",0,1024,AMG_OK,"{}");
        check("Chunked unclean close","HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n{}\r\n0\r\n\r\n",AMG_ERR_IO,1024,AMG_OK,"{}");
        check("Chunk extensions and trailers","HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2;foo=bar\r\n{}\r\n0\r\nX-Test: yes\r\n\r\n",0,1024,AMG_OK,"{}");
        check("Truncated length","HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n{}",0,1024,AMG_ERR_PROTOCOL,NULL);
        check("Truncated chunk","HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n{}\r\n",AMG_ERR_IO,1024,AMG_ERR_PARSE,NULL);
        check("Unframed orderly EOF","HTTP/1.1 200 OK\r\n\r\n{}",0,1024,AMG_OK,"{}");
        check("Unframed transport error","HTTP/1.1 200 OK\r\n\r\n{}",AMG_ERR_IO,1024,AMG_ERR_IO,NULL);
        check("Empty response","",0,1024,AMG_ERR_PROTOCOL,NULL);
        check("Missing header end","HTTP/1.1 200 OK\r\nContent-Length: 2\r\n",0,1024,AMG_ERR_PROTOCOL,NULL);
        check("Negative length","HTTP/1.1 200 OK\r\nContent-Length: -1\r\n\r\n{}",0,1024,AMG_ERR_PROTOCOL,NULL);
        check("Length overflow","HTTP/1.1 200 OK\r\nContent-Length: 999999999999999999999999999999\r\n\r\n{}",0,1024,AMG_ERR_PROTOCOL,NULL);
        check("Body limit","HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}",0,1,AMG_ERR_LIMIT,NULL);
        check("HTTP error","HTTP/1.1 404 Missing\r\nContent-Length: 0\r\n\r\n",0,1024,AMG_ERR_PROTOCOL,NULL);
    }
    return failures?1:0;
}
