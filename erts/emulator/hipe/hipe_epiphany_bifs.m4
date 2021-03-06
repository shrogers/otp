changecom(`/*', `*/')dnl
/*
 * %CopyrightBegin%
 *
 * Copyright Ericsson AB 2015. All Rights Reserved.
 *
 * The contents of this file are subject to the Erlang Public License,
 * Version 1.1, (the "License"); you may not use this file except in
 * compliance with the License. You should have received a copy of the
 * Erlang Public License along with this software. If not, it can be
 * retrieved online at http://www.erlang.org/.
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 *
 * %CopyrightEnd%
 */


include(`hipe/hipe_epiphany_asm.m4')
`#include' "config.h"
`#include' "hipe_literals.h"

	.text
        .p2align 1

`#if defined(ERTS_ENABLE_LOCK_CHECK) && defined(ERTS_SMP)
        .macro _CALL_BIF_MACRO f
        mov    lr, %low(\f)
        movt   lr, %high(\f)
        str    lr, [r0, #P_BIF_CALLEE/4]
        bl     _hipe_debug_bif_wrapper
        .endm
#  define CALL_BIF(F)	_CALL_BIF_MACRO F
#else
#  define CALL_BIF(F)	bl	F
#endif'

dnl XXX: Static branch prediction failure; branches assume untaken
define(TEST_GOT_MBUF,``/* TEST_GOT_MBUF($1) */'
        ldr	r1, [P, #P_MBUF/4]
        sub	r1, r1, #0
        beq	9f
        bl	_nbif_$1_gc_after_bif
9:')

/*
 * standard_bif_interface_1(nbif_name, cbif_name)
 * standard_bif_interface_2(nbif_name, cbif_name)
 * standard_bif_interface_3(nbif_name, cbif_name)
 * standard_bif_interface_0(nbif_name, cbif_name)
 *
 * Generate native interface for a BIF with 1-3 parameters and
 * standard failure mode.
 */
define(standard_bif_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
        .global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
        str	r1, [r0, #P_ARG0/4]	/* Store BIF__ARGS in def_arg_reg[] */
	add	r1, r0, #P_ARG0
        CALL_BIF(_$2)
	TEST_GOT_MBUF(1)

	/* Restore registers. Check for exception. */
        sub	r1, r0, #THE_NON_VALUE
        RESTORE_CONTEXT_BIF
        beq	_nbif_1_simple_exception
	NBIF_RET(1)
        .size	_$1, .-_$1
        .type	_$1, %function
#endif')

define(standard_bif_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,2,0)
	NBIF_ARG(r2,2,1)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
        str	r1, [r0, #P_ARG0/4]	/* Store BIF__ARGS in def_arg_reg[] */
        str	r2, [r0, #P_ARG1/4]
	add	r1, r0, #P_ARG0
	CALL_BIF(_$2)
	TEST_GOT_MBUF(2)

	/* Restore registers. Check for exception. */
        sub	r1, r0, #THE_NON_VALUE
	RESTORE_CONTEXT_BIF
        beq	_nbif_2_simple_exception
	NBIF_RET(2)
        .size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(standard_bif_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,3,0)
	NBIF_ARG(r2,3,1)
	NBIF_ARG(r3,3,2)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
        str	r1, [r0, #P_ARG0/4]	/* Store BIF__ARGS in def_arg_reg[] */
        str	r2, [r0, #P_ARG1/4]
        str	r3, [r0, #P_ARG2/4]
	add	r1, r0, #P_ARG0
	CALL_BIF(_$2)
	TEST_GOT_MBUF(3)

	/* Restore registers. Check for exception. */
        sub	r1, r0, #THE_NON_VALUE
	RESTORE_CONTEXT_BIF
	beq	_nbif_3_simple_exception
	NBIF_RET(3)
        .size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(standard_bif_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
        .global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	/* ignore empty BIF__ARGS */
        CALL_BIF(_$2)
	TEST_GOT_MBUF(0)

	/* Restore registers. Check for exception. */
        sub	r1, r0, #THE_NON_VALUE
	RESTORE_CONTEXT_BIF
        beq	_nbif_0_simple_exception
        NBIF_RET(0)
        .size	_$1, .-_$1
        .type	_$1, %function
#endif')

/*
 * gc_bif_interface_0(nbif_name, cbif_name)
 * gc_bif_interface_1(nbif_name, cbif_name)
 * gc_bif_interface_2(nbif_name, cbif_name)
 *
 * Generate native interface for a BIF with 0-2 parameters and
 * standard failure mode.
 * The BIF may do a GC.
 */
define(gc_bif_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
	/* ignore empty BIF__ARGS */
	CALL_BIF(_$2)
	TEST_GOT_MBUF(0)

	/* Restore registers. */
	RESTORE_CONTEXT_GC
	NBIF_RET(0)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(gc_bif_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
        str     r1, [r0, #P_ARG0/4]       /* Store BIF__ARGS in def_arg_reg[] */
        add     r1, r0, #P_ARG0
	CALL_BIF(_$2)
	TEST_GOT_MBUF(1)

	/* Restore registers. Check for exception. */
        sub	r1, r0, #THE_NON_VALUE
	RESTORE_CONTEXT_GC
	beq	_nbif_1_simple_exception
	NBIF_RET(1)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(gc_bif_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,2,0)
	NBIF_ARG(r2,2,1)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
        str     r1, [r0, #P_ARG0/4]       /* Store BIF__ARGS in def_arg_reg[] */
        str     r2, [r0, #P_ARG1/4]
        add     r1, r0, #P_ARG0
	CALL_BIF(_$2)
	TEST_GOT_MBUF(2)

	/* Restore registers. Check for exception. */
        sub	r1, r0, #THE_NON_VALUE
	RESTORE_CONTEXT_GC
	beq	_nbif_2_simple_exception
	NBIF_RET(2)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

/*
 * gc_nofail_primop_interface_1(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with implicit P
 * parameter, 1 ordinary parameter and no failure mode.
 * The primop may do a GC.
 */
define(gc_nofail_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_GC
	bl	_$2

	/* Restore registers. */
	RESTORE_CONTEXT_GC
	NBIF_RET(1)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

/*
 * nofail_primop_interface_0(nbif_name, cbif_name)
 * nofail_primop_interface_1(nbif_name, cbif_name)
 * nofail_primop_interface_2(nbif_name, cbif_name)
 * nofail_primop_interface_3(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with implicit P
 * parameter, 0-3 ordinary parameters and no failure mode.
 * Also used for guard BIFs.
 */
define(nofail_primop_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	_$2
	TEST_GOT_MBUF(0)

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(0)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(nofail_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,1,0)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	_$2
	TEST_GOT_MBUF(1)

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(1)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(nofail_primop_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,2,0)
	NBIF_ARG(r2,2,1)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	_$2
	TEST_GOT_MBUF(2)

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(2)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(nofail_primop_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,3,0)
	NBIF_ARG(r2,3,1)
	NBIF_ARG(r3,3,2)

	/* Save caller-save registers and call the C function. */
	SAVE_CONTEXT_BIF
	bl	_$2
	TEST_GOT_MBUF(3)

	/* Restore registers. */
	RESTORE_CONTEXT_BIF
	NBIF_RET(3)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

/*
 * nocons_nofail_primop_interface_0(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_1(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_2(nbif_name, cbif_name)
 * nocons_nofail_primop_interface_5(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with implicit P
 * parameter, 0-3 or 5 ordinary parameters, and no failure mode.
 * The primop cannot CONS or gc.
 */
define(nocons_nofail_primop_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(_$2,0)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(nocons_nofail_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,1,0)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(_$2,1)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(nocons_nofail_primop_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,2,0)
	NBIF_ARG(r2,2,1)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(_$2,2)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(nocons_nofail_primop_interface_5,
`
#ifndef HAVE_$1
#`define' HAVE_$1
        .global	_$1
_$1:
        /* Set up C argument registers. */
	mov	r0, P
	NBIF_ARG(r1,5,0)
	NBIF_ARG(r2,5,1)
        NBIF_ARG(r3,5,2)

        /* Set up C argument stack. */
        NBIF_ARG(r4,5,3)
        NBIF_ARG(r5,5,4)
        str	r4, [sp, #2]
        str	r5, [sp, #3]

	/* Perform a quick save;call;restore;ret sequence. */
        QUICK_CALL_RET(_$2,5)
        .size	_$1, .-_$1
        .type	_$1, %function
#endif')

/*
 * noproc_primop_interface_0(nbif_name, cbif_name)
 * noproc_primop_interface_1(nbif_name, cbif_name)
 * noproc_primop_interface_2(nbif_name, cbif_name)
 * noproc_primop_interface_3(nbif_name, cbif_name)
 * noproc_primop_interface_5(nbif_name, cbif_name)
 *
 * Generate native interface for a primop with no implicit P
 * parameter, 0-3 or 5 ordinary parameters, and no failure mode.
 * The primop cannot CONS or gc.
 */
define(noproc_primop_interface_0,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	$1
$1:
	/* XXX: this case is always trivial; how to suppress the branch? */
	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET($2,0)
	.size	$1, .-$1
	.type	$1, %function
#endif')

define(noproc_primop_interface_1,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	NBIF_ARG(r0,1,0)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(_$2,1)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(noproc_primop_interface_2,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	NBIF_ARG(r0,2,0)
	NBIF_ARG(r1,2,1)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(_$2,2)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(noproc_primop_interface_3,
`
#ifndef HAVE_$1
#`define' HAVE_$1
	.global	_$1
_$1:
	/* Set up C argument registers. */
	NBIF_ARG(r0,3,0)
	NBIF_ARG(r1,3,1)
	NBIF_ARG(r2,3,2)

	/* Perform a quick save;call;restore;ret sequence. */
	QUICK_CALL_RET(_$2,3)
	.size	_$1, .-_$1
	.type	_$1, %function
#endif')

define(noproc_primop_interface_5,
`
#ifndef HAVE_$1
#`define' HAVE_$1
        .global	_$1
_$1:
	/* Set up C argument registers. */
	NBIF_ARG(r0,5,0)
	NBIF_ARG(r1,5,1)
	NBIF_ARG(r2,5,2)
	NBIF_ARG(r3,5,3)
	NBIF_ARG(r4,5,4)
        str	r4, [sp, #2]

	/* Perform a quick save;call;restore;ret sequence. */
        QUICK_CALL_RET(_$2,5)
        .size	_$1, .-_$1
        .type	_$1, %function
#endif')

include(`hipe/hipe_bif_list.m4')

`#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",%progbits
#endif'
