#ifndef GRU_RELEASE_H
#define GRU_RELEASE_H
#include "buffer.h"
#define GRU_API "https://api.github.com/repos/Andiweli/Gloom-Reforged/releases/latest"
#define GRU_PREFIX "https://github.com/Andiweli/Gloom-Reforged/releases/download/"
#define GRU_JSON_MAX (512UL*1024UL)
#define GRU_ARCHIVE_MAX (32UL*1024UL*1024UL)
typedef struct GruRelease {
    char tag[32];
    char name[96];
    char url[768];
    char sha256[65];
    unsigned long size;
} GruRelease;
int amg_update_is_newer(const char *, const char *);
int gru_parse_release(const unsigned char *, size_t, GruRelease *, AmgError *);
int gru_validate_release(const GruRelease *);
int gru_fetch(const char *, size_t, AmgBuffer *, AmgError *);
#endif
