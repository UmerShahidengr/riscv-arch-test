// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------


#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I_Zicsr")
# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT

RVTEST_CODE_BEGIN
 # ---------------------------------------------------------------------------------------------
#ifdef TEST_CASE_1
RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def TEST_CASE_1=True; ",xyz)
RVTEST_SIGBASE( x3,signature_x3_1)

	.attribute unaligned_access, 0
	.attribute stack_align, 16
  	.align	2   
  	.option norvc
  	
#define MSIP_ADDR               0x02000000	// Address for the machine-mode pending software interrupt bit (MIP.MSIP)
main:

    	//  Enable global interrupt in mstatus
    	LI(a5, 8)		// Globally disable interrupt in mstatus.MIE 
       	csrs mstatus, a5
       	
       	//  Clear machine interrupt delegation register
    	LI(a5, -1)		// clear mideleg 
       	csrc mideleg, a5
       	
       	// Writing 1 at MSIP address to generate software interrupt
       	LI(a5, 1)		
       	LI(x5, MSIP_ADDR)
       	sw a5, 0(x5)		// Generate sofware interrupt by writing 1 at MSIP address
    	      	       	
       	// Setting up locally software and timer interrupts
    	LI(a5, 0x8)		// Locally Enable software interrupt in MIE 
       	csrs mie, a5
       	nop
	nop
	csrr a4, mip	// READ mip
	RVTEST_SIGUPD(x3,a4)
	
#endif
 # ---------------------------------------------------------------------------------------------
    # HALT
RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4

rvtest_data:
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
RVTEST_DATA_END


RVMODEL_DATA_BEGIN
rvtest_sig_begin:
sig_begin_canary:
CANARY;
signature_x3_1:
    .fill 12*(XLEN/32),4,0xdeadbeef

#ifdef rvtest_mtrap_routine

tsig_begin_canary:
CANARY;
mtrap_sigptr:
    .fill 12*(XLEN/32),4,0xdeadbeef
tsig_end_canary:
CANARY;

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef

#endif

sig_end_canary:
CANARY;
rvtest_sig_end:
RVMODEL_DATA_END