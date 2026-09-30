/* GloomUpdate: independent CLI process. No pointers into the game are kept.
 * CHECK <installed-version> <RAM:job-base> / GET <installed-version> <RAM:job-base>
 * Status is published by rename only after closing all output handles.
 * GPL-3.0-or-later; TLS/HTTP basis: Andreas Stuermer's AmiMAIL. */
#include "release.h"
#include "tls.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#if AMIGMAIL_AMIGA
#include <exec/libraries.h>
#include <proto/amissl.h>
#include <proto/dos.h>
#endif
#include <openssl/sha.h>

unsigned long __stack = 65536UL;
static int write_file(const char *path,const void *data,size_t length)
{
    FILE *f=fopen(path,"wb");int ok;
    if(!f)return 0;
    ok=fwrite(data,1,length,f)==length;
    if(fclose(f))ok=0;
    if(!ok)remove(path);
    return ok;
}
static int read_meta(const char *path,GruRelease *r)
{
    FILE *f=fopen(path,"rb");int ok;
    if(!f)return 0;
    ok=fread(r,1,sizeof(*r),f)==sizeof(*r)&&fgetc(f)==EOF;
    fclose(f);
    if(!ok)return 0;
    if(!memchr(r->tag,0,sizeof(r->tag))||!memchr(r->name,0,sizeof(r->name))||
       !memchr(r->url,0,sizeof(r->url))||!memchr(r->sha256,0,sizeof(r->sha256)))return 0;
    return gru_validate_release(r);
}
static int publish(const char *base,int code,const GruRelease *r,const char *detail)
{
    unsigned char status[256];char temp[128],path[128];
    memset(status,0,sizeof(status));memcpy(status,"GRU1",4);status[4]=(unsigned char)code;
    if(r)strncpy((char *)status+8,r->tag,31);
    if(detail)strncpy((char *)status+40,detail,215);
    snprintf(temp,sizeof(temp),"%s.tmp",base);snprintf(path,sizeof(path),"%s.status",base);
    if(!write_file(temp,status,sizeof(status)))return 0;
    remove(path);
    if(rename(temp,path)) { remove(temp);return 0; }
    return 1;
}
/* Native DOS output also works independently of the C stdio buffering.
 * Launcher workers write to their own NIL: handle. */
static void report(const char *message)
{
#if AMIGMAIL_AMIGA
    BPTR output=Output();
    if(output) { Write(output,(APTR)message,(LONG)strlen(message));Write(output,(APTR)"\n",1); }
#else
    puts(message);fflush(stdout);
#endif
}
static int equal_nocase(const char *a,const char *b)
{
    while(*a && *b) { if(toupper((unsigned char)*a++)!=toupper((unsigned char)*b++))return 0; }
    return *a==*b;
}
static int argument_error(const char *message)
{
    report("GloomUpdate: invalid command line.");report(message);
    report("Usage: GloomUpdate CHECK|GET <version> RAM:GRUpdate-<hex-id>");
    write_file("RAM:GloomUpdate-CLI.log",message,strlen(message));
    return 20;
}
int main(int argc,char **argv)
{
    GruRelease release;AmgError error;AmgBuffer body;
    char meta[128],temp[160],dest[160];int result=AMG_ERR_ARGUMENT,code='E',tls=0;
    const char *detail="Invalid update request.";size_t i;
    if(argc!=4) {
        char message[96];snprintf(message,sizeof(message),"Expected 3 arguments, received %d (argc=%d).",argc>0?argc-1:0,argc);
        return argument_error(message);
    }
    if(!equal_nocase(argv[1],"CHECK")&&!equal_nocase(argv[1],"GET"))
        return argument_error("First argument must be CHECK or GET (case-insensitive).");
    {
        char prefix[14];size_t length=strlen(argv[3]);
        if(length<14 || length>80)return argument_error("Job path must be RAM:GRUpdate- followed by a hexadecimal ID, maximum 80 characters.");
        memcpy(prefix,argv[3],13);prefix[13]=0;
        if(!equal_nocase(prefix,"RAM:GRUpdate-"))return argument_error("Job path must start with RAM:GRUpdate- (case-insensitive).");
    }
    for(i=13;argv[3][i];++i)if(!isxdigit((unsigned char)argv[3][i])&&argv[3][i]!='-')
        return argument_error("Job ID may contain only 0-9, A-F and hyphens.");
    report(equal_nocase(argv[1],"CHECK") ? "GloomUpdate: checking release..." : "GloomUpdate: downloading release...");
    memset(&release,0,sizeof(release));memset(&error,0,sizeof(error));amg_buffer_init(&body);
    snprintf(meta,sizeof(meta),"%s.meta",argv[3]);
    result=amg_tls_global_init(&error);if(result!=AMG_OK)goto done;tls=1;
    if(equal_nocase(argv[1],"CHECK")) {
        result=gru_fetch(GRU_API,GRU_JSON_MAX,&body,&error);
        if(result!=AMG_OK)goto done;
        result=gru_parse_release(body.data,body.length,&release,&error);
        if(result!=AMG_OK)goto done;
        if(!amg_update_is_newer(release.tag,argv[2])) { code='U';detail="Gloom Reforged is up to date!";remove(meta);goto done; }
        if(!write_file(meta,&release,sizeof(release))) { detail="Cannot write update metadata to RAM:.";goto done; }
        code='N';detail="New update available.";
    } else {
        unsigned char digest[SHA256_DIGEST_LENGTH];char hex[65];FILE *existing;
        if(!read_meta(meta,&release)||!amg_update_is_newer(release.tag,argv[2])) { detail="Update metadata is invalid. Reopen the launcher.";goto done; }
        result=gru_fetch(release.url,GRU_ARCHIVE_MAX,&body,&error);
        if(result!=AMG_OK)goto done;
        if(body.length!=release.size) { detail="Archive size does not match the release.";goto done; }
        if(body.length<7 || body.data[2]!='-' || body.data[3]!='l' ||
           (body.data[4]!='h' && body.data[4]!='z') || body.data[6]!='-') {
            detail="Downloaded file is not an LHA archive.";goto done;
        }
        if(!SHA256(body.data,body.length,digest)) { detail="SHA-256 calculation failed.";goto done; }
        for(i=0;i<32;++i)sprintf(hex+i*2,"%02x",(unsigned)digest[i]);
        for(i=0;i<64;++i)if(hex[i]!=tolower((unsigned char)release.sha256[i]))break;
        if(i!=64) { detail="Archive SHA-256 does not match the release.";goto done; }
        snprintf(dest,sizeof(dest),"RAM:%s",release.name);
        /* Never replace an existing RAM: file: use this job's unique name. */
        existing=fopen(dest,"rb");
        if(existing) { fclose(existing);snprintf(dest,sizeof(dest),"%s.lha",argv[3]); }
        snprintf(temp,sizeof(temp),"%s.part",argv[3]);
        if(!write_file(temp,body.data,body.length)) { detail="Cannot write the archive to RAM:.";goto done; }
        if(rename(temp,dest)) { remove(temp);detail="Cannot finalize the archive in RAM:.";goto done; }
        code='D';detail=dest;remove(meta);
    }
done:
    if(code=='E' && error.message[0])detail=error.message;
    if(code=='E') { char log[128];snprintf(log,sizeof(log),"%s.log",argv[3]);write_file(log,detail,strlen(detail)); }
    if(tls)amg_tls_global_cleanup();
    amg_buffer_free(&body);
    report(detail);
    if(!publish(argv[3],code,&release,detail)) {
        report("Cannot publish status in RAM:.");return 20;
    }
    return code!='E' ? 0 : 20;
}
