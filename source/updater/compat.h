#ifndef GRU_COMPAT_H
#define GRU_COMPAT_H
/* Standalone English messages; no AmiMAIL catalog/application dependency. */
#define amg_tr_snprintf(dst, size, id, fmt, ...) snprintf(dst, size, fmt, __VA_ARGS__)
#endif
