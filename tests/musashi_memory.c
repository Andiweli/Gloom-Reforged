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
/* Opt-in host model: changing beam counter and byte-level Paula/CIA writes.
 * This does not simulate audio DMA, CIA interrupt timing or analogue output. */
static unsigned hw_mode,beam,hw_count;
static struct { unsigned address,value,pc; } hw_writes[16384];
static struct { unsigned start,end,kind; } guards[8];
static unsigned guard_count;
static int guarded(unsigned a,unsigned kind) {
    unsigned i;
    for(i=0;i<guard_count;i++)
        if((guards[i].kind&kind) && a>=guards[i].start && a<guards[i].end) { faults++;return 1; }
    return 0;
}
API void test_guard(unsigned start,unsigned end,unsigned kind) {
    if(guard_count>=8 || start>end) { faults++;return; }
    guards[guard_count].start=start;guards[guard_count].end=end;
    guards[guard_count++].kind=kind;
}
unsigned m68k_read_memory_8(unsigned a) { if(a>=sizeof memory){faults++;return 0;} if(guarded(a,1))return 0;if(hw_mode && a==0xdff007)return (++beam)&255;return memory[a]; }
unsigned m68k_read_memory_16(unsigned a) { return (m68k_read_memory_8(a)<<8)|m68k_read_memory_8(a+1); }
unsigned m68k_read_memory_32(unsigned a) { return (m68k_read_memory_16(a)<<16)|m68k_read_memory_16(a+2); }
void m68k_write_memory_8(unsigned a,unsigned v) {
    if(a>=sizeof memory){faults++;return;} if(guarded(a,2))return;
    if(hw_mode && ((a>=0xdff000 && a<0xdff200) || (a>=0xbfd000 && a<0xbff000))) {
        if(hw_count>=16384){faults++;return;}
        hw_writes[hw_count].address=a;hw_writes[hw_count].value=v&255;
        hw_writes[hw_count++].pc=m68k_get_reg(0,M68K_REG_PC);
    }
    memory[a]=(unsigned char)v;
}
void m68k_write_memory_16(unsigned a,unsigned v) { m68k_write_memory_8(a,v>>8);m68k_write_memory_8(a+1,v); }
void m68k_write_memory_32(unsigned a,unsigned v) { m68k_write_memory_16(a,v>>16);m68k_write_memory_16(a+2,v); }
API unsigned char *test_memory(void) { return memory; }
API unsigned test_faults(void) { return faults; }
API void test_reset(unsigned cpu) { memset(memory,0,sizeof memory);faults=0;guard_count=0;hw_mode=beam=hw_count=0;m68k_init();m68k_set_cpu_type(cpu);m68k_write_memory_32(0,0x800000);m68k_write_memory_32(4,0x10000);m68k_pulse_reset(); }
API void test_hw_mode(unsigned enabled) { hw_mode=enabled;hw_count=0; }
API void test_hw_clear(void) { hw_count=0; }
API unsigned test_hw_count(void) { return hw_count; }
API unsigned test_hw_address(unsigned i) { return i<hw_count?hw_writes[i].address:0; }
API unsigned test_hw_value(unsigned i) { return i<hw_count?hw_writes[i].value:0; }
API unsigned test_hw_pc(unsigned i) { return i<hw_count?hw_writes[i].pc:0; }
API unsigned test_get(unsigned reg) { return m68k_get_reg(0,(m68k_register_t)reg); }
API void test_set(unsigned reg,unsigned value) { m68k_set_reg((m68k_register_t)reg,value); }
API void test_step(void) { m68k_execute(1); }
API unsigned test_until(unsigned target,unsigned limit) { while(limit--) { if(faults)return 0;if(m68k_get_reg(0,M68K_REG_PC)==target)return 1;m68k_execute(1); } return 0; }
unsigned m68k_read_disassembler_8(unsigned a) { return m68k_read_memory_8(a); }
unsigned m68k_read_disassembler_16(unsigned a) { return m68k_read_memory_16(a); }
unsigned m68k_read_disassembler_32(unsigned a) { return m68k_read_memory_32(a); }
API unsigned test_disassemble(unsigned pc,char *output) {
    return m68k_disassemble_raw(output,pc,memory+pc,memory+pc,M68K_CPU_TYPE_68040);
}
