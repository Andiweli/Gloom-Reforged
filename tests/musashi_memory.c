/* Host-only glue for running assembled routines with stubbed Amiga libraries.
 * Build with Musashi (MIT) sources; never linked into game/benchmark. */
#include "m68k.h"
#include <string.h>
#ifdef _WIN32
#define API __declspec(dllexport)
#else
#define API
#endif
static unsigned char memory[0x1000000];
static unsigned faults;
unsigned m68k_read_memory_8(unsigned a) { if(a>=sizeof memory){faults++;return 0;} return memory[a]; }
unsigned m68k_read_memory_16(unsigned a) { return (m68k_read_memory_8(a)<<8)|m68k_read_memory_8(a+1); }
unsigned m68k_read_memory_32(unsigned a) { return (m68k_read_memory_16(a)<<16)|m68k_read_memory_16(a+2); }
void m68k_write_memory_8(unsigned a,unsigned v) { if(a>=sizeof memory){faults++;return;} memory[a]=(unsigned char)v; }
void m68k_write_memory_16(unsigned a,unsigned v) { m68k_write_memory_8(a,v>>8);m68k_write_memory_8(a+1,v); }
void m68k_write_memory_32(unsigned a,unsigned v) { m68k_write_memory_16(a,v>>16);m68k_write_memory_16(a+2,v); }
API unsigned char *test_memory(void) { return memory; }
API unsigned test_faults(void) { return faults; }
API void test_reset(unsigned cpu) { memset(memory,0,sizeof memory);faults=0;m68k_init();m68k_set_cpu_type(cpu);m68k_write_memory_32(0,0x800000);m68k_write_memory_32(4,0x10000);m68k_pulse_reset(); }
API unsigned test_get(unsigned reg) { return m68k_get_reg(0,(m68k_register_t)reg); }
API void test_set(unsigned reg,unsigned value) { m68k_set_reg((m68k_register_t)reg,value); }
API void test_step(void) { m68k_execute(1); }
API unsigned test_until(unsigned target,unsigned limit) { while(limit--) { if(m68k_get_reg(0,M68K_REG_PC)==target)return 1;m68k_execute(1); } return 0; }
