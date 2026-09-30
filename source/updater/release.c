/* Version comparison adapted from the supplied AmiMAIL update.c. */
#include "release.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct AmgParsedVersion {
    unsigned long parts[8];
    size_t count;
    int prerelease;
    unsigned long rc_number;
} AmgParsedVersion;

static int ascii_prefix_nocase(const char *text, const char *prefix)
{
    if (!text || !prefix) return 0;
    while (*prefix) {
        if (!*text ||
            tolower((unsigned char)*text) !=
            tolower((unsigned char)*prefix))
            return 0;
        ++text;
        ++prefix;
    }
    return 1;
}

static int parse_version(const char *text, AmgParsedVersion *version)
{
    const char *cursor;
    size_t used = 0U;
    if (!text || !*text || !version) return 0;
    memset(version, 0, sizeof(*version));
    cursor = text;
    if (*cursor == 'v' || *cursor == 'V') ++cursor;
    if (!isdigit((unsigned char)*cursor)) return 0;

    while (*cursor) {
        unsigned long value = 0UL;
        if (used >= sizeof(version->parts) / sizeof(version->parts[0]) ||
            !isdigit((unsigned char)*cursor))
            return 0;
        while (isdigit((unsigned char)*cursor)) {
            unsigned digit = (unsigned)(*cursor - '0');
            if (value > 1000000UL) return 0;
            value = value * 10UL + (unsigned long)digit;
            ++cursor;
        }
        version->parts[used++] = value;
        if (!*cursor) break;
        if (*cursor == '.') {
            ++cursor;
            if (!isdigit((unsigned char)*cursor)) return 0;
            continue;
        }
        break;
    }
    version->count = used;
    if (!used) return 0;

    while (*cursor == ' ' || *cursor == '-' || *cursor == '_') ++cursor;
    if (!*cursor) return 1;
    if (!ascii_prefix_nocase(cursor, "RC")) return 0;
    cursor += 2;
    version->prerelease = 1;
    if (*cursor) {
        unsigned long number = 0UL;
        if (!isdigit((unsigned char)*cursor)) return 0;
        while (isdigit((unsigned char)*cursor)) {
            unsigned digit = (unsigned)(*cursor - '0');
            if (number > 1000000UL) return 0;
            number = number * 10UL + (unsigned long)digit;
            ++cursor;
        }
        version->rc_number = number;
    }
    return *cursor == 0;
}

int amg_update_is_newer(const char *candidate_tag,
                        const char *current_version)
{
    AmgParsedVersion candidate, current;
    size_t i, max_count;
    if (!parse_version(candidate_tag, &candidate) ||
        !parse_version(current_version, &current))
        return 0;
    max_count = candidate.count > current.count
        ? candidate.count : current.count;
    for (i = 0U; i < max_count; ++i) {
        unsigned long a = i < candidate.count ? candidate.parts[i] : 0UL;
        unsigned long b = i < current.count ? current.parts[i] : 0UL;
        if (a > b) return 1;
        if (a < b) return 0;
    }
    /* For the same numeric version a final release supersedes an RC. */
    if (candidate.prerelease != current.prerelease)
        return current.prerelease && !candidate.prerelease;
    if (candidate.prerelease && current.prerelease)
        return candidate.rc_number > current.rc_number;
    return 0;
}

/* Bounded structural JSON reader: only direct members of the requested object
 * are considered. Strings in release notes and nested uploader objects cannot
 * supply a version or URL. Unknown JSON fields are skipped, not searched. */
typedef struct Json { const unsigned char *p, *end; unsigned depth; } Json;
static void ws(Json *j) { while(j->p<j->end && (*j->p && strchr(" \t\r\n",*j->p))) ++j->p; }
static int string(Json *j,char *out,size_t cap)
{
    size_t n=0; unsigned c;
    if(j->p==j->end || *j->p++!='"') return 0;
    while(j->p<j->end) {
        c=*j->p++;
        if(c=='"') { if(out) out[n]=0; return 1; }
        if(c<32) return 0;
        if(c=='\\') {
            if(j->p==j->end) return 0;
            c=*j->p++;
            if(c=='u') {
                unsigned k,v=0;
                for(k=0;k<4;++k) { unsigned h;
                    if(j->p==j->end) return 0;
                    h=*j->p++;
                    if(h>='0'&&h<='9') h-='0';
                    else if(h>='a'&&h<='f') h=h-'a'+10;
                    else if(h>='A'&&h<='F') h=h-'A'+10;
                    else return 0;
                    v=(v<<4)|h;
                }
                if(out && (v<32 || v>126)) return 0;
                c=v;
            } else if(c=='n') c='\n'; else if(c=='r') c='\r';
            else if(c=='t') c='\t'; else if(c=='b') c='\b';
            else if(c=='f') c='\f';
            else if(c!='"' && c!='\\' && c!='/') return 0;
        }
        if(out) { if(n+1>=cap) return 0; out[n++]=(char)c; }
    }
    return 0;
}
static int skip(Json *j)
{
    unsigned char close; ws(j);
    if(j->p==j->end || j->depth>=32) return 0;
    if(*j->p=='"') return string(j,NULL,0);
    if(*j->p=='{' || *j->p=='[') {
        int obj=*j->p=='{'; close=obj?'}':']'; ++j->p; ++j->depth; ws(j);
        if(j->p<j->end && *j->p==close) { ++j->p; --j->depth; return 1; }
        for(;;) {
            ws(j);
            if(obj) { if(!string(j,NULL,0)) return 0; ws(j); if(j->p==j->end||*j->p++!=':')return 0; }
            if(!skip(j)) return 0;
            ws(j); if(j->p==j->end)return 0;
            if(*j->p==close) { ++j->p; --j->depth; return 1; }
            if(*j->p++!=',')return 0;
        }
    }
    {
        const unsigned char *a=j->p; size_t n;
        while(j->p<j->end && !strchr(",]} \t\r\n",*j->p)) ++j->p;
        n=(size_t)(j->p-a);
        if((n==4&&!memcmp(a,"true",4))||(n==5&&!memcmp(a,"false",5))||(n==4&&!memcmp(a,"null",4)))return 1;
        /* JSON number grammar. */
        if(a<j->p && *a=='-')++a;
        if(a==j->p || !isdigit(*a))return 0;
        if(*a=='0')++a;else while(a<j->p&&isdigit(*a))++a;
        if(a<j->p&&*a=='.'){++a;if(a==j->p||!isdigit(*a))return 0;while(a<j->p&&isdigit(*a))++a;}
        if(a<j->p&&(*a=='e'||*a=='E')){++a;if(a<j->p&&(*a=='+'||*a=='-'))++a;if(a==j->p||!isdigit(*a))return 0;while(a<j->p&&isdigit(*a))++a;}
        return a==j->p;
    }
}
static int member(Json object,const char *key,Json *value)
{
    int found=0;
    ws(&object); if(object.p==object.end||*object.p++!='{')return 0;
    ws(&object);
    if(object.p<object.end&&*object.p=='}')return 0;
    for(;;) {
        char name[128]; Json v; ws(&object);
        if(!string(&object,name,sizeof(name)))return 0;
        ws(&object);if(object.p==object.end||*object.p++!=':')return 0;
        ws(&object);v=object;if(!skip(&object))return 0;v.end=object.p;
        if(!strcmp(name,key)) { if(found)return 0;*value=v;found=1; }
        ws(&object);if(object.p==object.end)return 0;
        if(*object.p++=='}')return found;
        if(object.p[-1]!=',')return 0;
    }
}
static int field(Json object,const char *key,char *out,size_t size)
{ Json v;return member(object,key,&v)&&string(&v,out,size)&&v.p==v.end; }
static int is_false(Json object,const char *key)
{ Json v;return member(object,key,&v)&&v.end-v.p==5&&!memcmp(v.p,"false",5); }
int gru_validate_release(const GruRelease *r)
{
    AmgParsedVersion v; size_t i,n; const char *tail;
    if(!parse_version(r->tag,&v)||v.prerelease||strlen(r->tag)>15)return 0;
    if(!r->size||r->size>GRU_ARCHIVE_MAX)return 0;
    n=strlen(r->name);
    if(n<20||strncmp(r->name,"GloomReforged-",13)||strcmp(r->name+n-4,".lha")||strstr(r->name,".."))return 0;
    for(i=0;i<n;++i) if(!(isalnum((unsigned char)r->name[i])||strchr("._-",r->name[i])))return 0;
    if(strncmp(r->url,GRU_PREFIX,strlen(GRU_PREFIX)))return 0;
    tail=r->url+strlen(GRU_PREFIX);
    if(strncmp(tail,r->tag,strlen(r->tag))||tail[strlen(r->tag)]!='/')return 0;
    if(strcmp(tail+strlen(r->tag)+1,r->name))return 0;
    if(strlen(r->sha256)!=64)return 0;
    for(i=0;i<64;++i)if(!isxdigit((unsigned char)r->sha256[i]))return 0;
    return 1;
}
int gru_parse_release(const unsigned char *data,size_t length,GruRelease *r,AmgError *error)
{
    Json root,j,assets,size; AmgParsedVersion v; int found=0;
    if(!data||!r||length>GRU_JSON_MAX)return AMG_ERR_ARGUMENT;
    root.p=data;root.end=data+length;root.depth=0;j=root;
    memset(r,0,sizeof(*r));
    if(!skip(&j))goto invalid;
    ws(&j);
    if(j.p!=j.end)goto invalid;
    if(!field(root,"tag_name",r->tag,sizeof(r->tag))||!parse_version(r->tag,&v)||v.prerelease||
       !is_false(root,"draft")||!is_false(root,"prerelease")||!member(root,"assets",&assets))goto invalid;
    ws(&assets);if(assets.p==assets.end||*assets.p++!='[')goto invalid;ws(&assets);
    while(assets.p<assets.end&&*assets.p!=']') {
        GruRelease candidate;char digest[80],num[32];size_t n;
        j=assets;if(!skip(&assets))goto invalid;j.end=assets.p;
        memset(&candidate,0,sizeof(candidate));strcpy(candidate.tag,r->tag);
        if(field(j,"name",candidate.name,sizeof(candidate.name)) &&
           !strncmp(candidate.name,"GloomReforged-",13) &&
           (n=strlen(candidate.name))>=4 && !strcmp(candidate.name+n-4,".lha")) {
            char *end;
            if(!field(j,"browser_download_url",candidate.url,sizeof(candidate.url))||
               !field(j,"digest",digest,sizeof(digest))||strncmp(digest,"sha256:",7)||
               strlen(digest)!=71||!member(j,"size",&size))goto invalid;
            n=(size_t)(size.end-size.p);if(!n||n>=sizeof(num))goto invalid;
            memcpy(num,size.p,n);num[n]=0;candidate.size=strtoul(num,&end,10);
            if(*end||!isdigit((unsigned char)num[0]))goto invalid;
            strcpy(candidate.sha256,digest+7);
            if(!gru_validate_release(&candidate)||found)goto invalid;
            *r=candidate;found=1;
        }
        ws(&assets);if(assets.p==assets.end)goto invalid;
        if(*assets.p==']')break;
        if(*assets.p++!=',')goto invalid;
        ws(&assets);
    }
    if(found)return AMG_OK;
invalid:
    amg_error_set(error,AMG_ERR_PARSE,"Release has no unambiguous verified GloomReforged LHA asset.");
    return AMG_ERR_PARSE;
}
