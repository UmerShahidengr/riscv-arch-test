# ######################################################################################################## 
#  Verification Goal: Set PMM = 10 in the mseccfg and test whether or not pointer masking with PMLEN = 7 #
#                     is enabled or not in Machine Mode in sv57      			         	 #
#                                                                            			         #
#                                                                                                        #
# Description:       If Pointer Masking is enabled, then the Effective Address will be masked according	 #
#                    raise page fault exception of the corresponding access type.           	         #
# ########################################################################################################   
#define PMM_EXT_ENAB
#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV64I_Zicsr")

# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN
#ifdef TEST_CASE_1

    RVTEST_CASE(1,"//check ISA:=regex(.*64.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def rvtest_strap_routine=True; def TEST_CASE_1=True",pte_access_bit_15)

RVTEST_SIGBASE( x13,signature_x13_1)


main:

j _start

.align 3
rvtest_data:
	.dword 0xdeadbeefdeadbeef
_start:
# -------------------------------------------------------------------------
#ifdef rvtest_mtrap_routine							// Verification of existance of rvtest_mtrap_routine
	LI a4, 0xceed
	RVTEST_SIGUPD(x13,a4)
#endif
#ifdef rvtest_strap_routine					         	// Verification of existance of rvtest_strap_routine
	LI a4, 0xbeed
	RVTEST_SIGUPD(x13,a4)
#endif
# -------------------------Set the all mem PMP-----------------------------	
	ALL_MEM_PMP
# -------------------------------------------------------------------------
	csrw satp, zero								// write zero to the satp (bare mode)
# --------------------------Setting Addresses-------------------------------
	.set va,       	 0x080000000000000                                      // 57 bits virtual address						
	.set pa,       	 0x80000000000000                                       // 56 bits physical address
	.set va_data,  	 0x060000000000628                                      // 57 bits virtual address of data
	.set sig_data,   0x080000000180118					// 57 bits of VA address of signature

# -------------------------Set the PTE for level3 for sv48-----------------

	// level 3 PTE setup for pa (0x200000000000 -> 0x80000000000000)	

	LI (a0, pa)                                                             // loads the address in a0
	LI a1, ( PTE_V | PTE_A | PTE_W | PTE_R | PTE_D | PTE_X )       		// sets the permission bits
	PTE_SETUP_RV64(a0, a1, t0, t1, va, LEVEL4,sv57)                         // setup the PTE for level 3 for sv48
							        
	// level 3 PTE setup for rvtest_data (0x210000000000 -> rvtest_data)

	LA (a0, rvtest_data)	
	LI a1, ( PTE_D | PTE_A | PTE_R | PTE_W | PTE_X | PTE_V )         	// sets the permission bits
	PTE_SETUP_RV64(a0, a1, t0, t1, va_data, LEVEL4,sv57)                    // setup the PTE for level 3 for sv48

# -------------------------Set the PTE for signature update-----------------
	// level 3 PTE setup for rvtest_slvl1_pg_tbl (0x280000180118-> rvtest_slvl1_pg_tbl)	

	LA (a0, rvtest_slvl1_pg_tbl)                                            // loads the address in a0
	LI a1, ( PTE_V )                                                        // sets the permission bits
	PTE_SETUP_RV64(a0, a1, t0, t1, sig_data, LEVEL4,sv57)                   // setup the PTE for level 3 for sv48

	// level 3 PTE setup for rvtest_slvl1_pg_tbl (0x280000180118-> rvtest_slvl1_pg_tbl)	

	LA (a0, rvtest_slvl2_pg_tbl)                                            // loads the address in a0
	LI a1, ( PTE_V )                                                        // sets the permission bits
	PTE_SETUP_RV64(a0, a1, t0, t1, sig_data, LEVEL3,sv57)                   // setup the PTE for level 3 for sv48

        // level 2 PTE setup for rvtest_slvl1_pg_tbl (0x280000180118 -> rvtest_slvl2_pg_tbl)	

	LA (a0, rvtest_slvl3_pg_tbl)                                            // loads the address in a0
	LI a1, ( PTE_V )                                                        // sets the permission bits
	PTE_SETUP_RV64(a0, a1, t0, t1, sig_data, LEVEL2,sv57)                   // setup the PTE for level 2 for sv48

        // level 1 PTE setup for rvtest_slvl1_pg_tbl (0x280000180118 -> rvtest_slvl3_pg_tbl)	

	LA (a0, rvtest_slvl4_pg_tbl)                                            // loads the address in a0
	LI a1, ( PTE_V )                                                        // sets the permission bits
	PTE_SETUP_RV64(a0, a1, t0, t1, sig_data, LEVEL1,sv57)                   // setup the PTE for level 1 for sv48

        // PTE setup for 0x0900080000 -> rvtest_sig_begin

	la a0, rvtest_sig_begin   						// Physical address of signature area
	li a1, ( PTE_D | PTE_A | PTE_R | PTE_W | PTE_X | PTE_V )         	// sets the permissions bits 
	PTE_SETUP_RV64(a0, a1, t0, t1, sig_data, LEVEL0,sv57) 			// PTE Setup for signature area address at pgtbl0
	
	LI (t0, sig_data)                                                       
	LA (t1, rvtest_sig_begin)                                                      
	sub t0, t0, t1 					        		// (VA-PA) Note: VA > PA 
	add x13, x13, t0				        		// Translation of Signature reg	

# -------------------------Save area logic----------------------------------

	SIGNATURE_AREA (CODE, va, pa,user)                                      // signature area for code 
	SIGNATURE_AREA (DATA, va_data,rvtest_data,user)                         // signature area for data 
	SIGNATURE_AREA (SIG, sig_data, signature_x13_1,user)                    // signature area for signature
	SIGNATURE_AREA (VMEM, va_data, rvtest_data,user)                        // signature area for vmem

# # -------------------------Setting the PMM ----------------------------- 

	LI a3,0x200000000
        csrw mseccfg, a3                                                        //Enable Pointer Masking with PMLEN = 7

# # -------------------------Testing PMM on PA------------------------

	LA (t0, rvtest_data)
        LREG x2, 0(t0)                                                          // test the load access
        nop                                             
	SREG x2, 0(t0)                                                          // test the store access
	nop
	lb   x2, 0(t0)                                                          // test the load access
	nop
	sb   x2, 0(t0)                                                          // test the store access
	nop
	lh   x2, 0(t0)                                                          // test the load access
	nop
	sh   x2, 0(t0)                                                          // test the store access
	nop
	ld   x2, 0(t0)                                                          // test the load access
	nop
	sd   x2, 0(t0)                                                          // test the store access
	nop
	lbu  x2, 0(t0)                                                          // test the load access
	nop
	lhu  x2, 0(t0)                                                          // test the load access	
	nop
	lwu  x2, 0(t0)

# -------------------------Set the SATP for virtulization------------------
	sfence.vma                                                              // flush the TLB          
	SATP_SETUP_RV64 (sv57)                                                  // set the SATP for virtualization
        LI (s7, MSTATUS_MPRV)                                                   // loads the value of MSTATUS_MPRV in s7
        csrs mstatus,s7                                                         // set the mstatus.SUM = 1 	

# -------------------------Switching to S Mode------------------

	RVTEST_GOTO_MMODE		                                        // Switching back to M mode	

# -------------------------virtulization enabled----------------------------------

              #--------------Testing PMM on VA--------------#
vm_en:
	LI (a4, 0xdead)                                                         // Loads 0xdead in a4
        nop     
	LI (t0, va_data)                                                        
	LREG x2, 0(t0)                                                          // test the load access
        nop                                             
	SREG x2, 0(t0)                                                          // test the store access
	nop
	lb   x2, 0(t0)                                                          // test the load access
	nop
	sb   x2, 0(t0)                                                          // test the store access
	nop
	lh   x2, 0(t0)                                                          // test the load access
	nop
	sh   x2, 0(t0)                                                          // test the store access
	nop
	ld   x2, 0(t0)                                                          // test the load access
	nop
	sd   x2, 0(t0)                                                          // test the store access
	nop
	lbu  x2, 0(t0)                                                          // test the load access
	nop
	lhu  x2, 0(t0)                                                          // test the load access	
	nop
	lwu  x2, 0(t0)
	nop
			

	LI (a4, 0xbeef)
        nop

# -------------------------virtulization disabled----------------------------------

	RVTEST_GOTO_MMODE		                                        // Switching back to M mode

# # -------------------------Setting the PMM ----------------------------- 

	LI a3,0x200000000
        csrc mseccfg, a3                                                        
#-------------------------------------------------------------------------

	LI (t0, sig_data)                                                       
	LA (t1, rvtest_sig_begin)                                                      
	sub t0, t0, t1 					        		// (VA-PA) Note: VA > PA 
	sub x13, x13, t0				        		// Translation of Signature reg
	addi x13,x13,REGWIDTH
	nop                                                                 

	LI (a4, 0x123)
	RVTEST_SIGUPD(x13,a4)                                                   // Verification of virtualization disabled

#endif

 # ----------------------------------------------------------------------------

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
#ifdef rvtest_strap_routine
.align 12
rvtest_slvl1_pg_tbl:
        RVTEST_PTE_IDENT_MAP(0,LVLS,RVTEST_ALLPERMS)	
rvtest_slvl2_pg_tbl:
        RVTEST_PTE_IDENT_MAP(0,LVLS,RVTEST_ALLPERMS)
rvtest_slvl3_pg_tbl:
        RVTEST_PTE_IDENT_MAP(0,LVLS,RVTEST_ALLPERMS)
rvtest_slvl4_pg_tbl:
        RVTEST_PTE_IDENT_MAP(0,LVLS,RVTEST_ALLPERMS)	        
#endif
RVTEST_DATA_END
RVMODEL_DATA_BEGIN
rvtest_sig_begin:
sig_begin_canary:
CANARY;

// test signatures initialization
signature_x13_1:
    .fill 64*(XLEN/64),4,0xcafebeef

// trap signatures initialization
#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/64),4,0xdeadbeef
#endif

sig_end_canary:
CANARY;
rvtest_sig_end:
RVMODEL_DATA_END
