/* memcmp - compare memory
 *
 * Copyright (c) 2013-2021, Arm Limited.
 * SPDX-License-Identifier: MIT OR Apache-2.0 WITH LLVM-exception
 */

/* Assumptions:
 *
 * ARMv8-a, AArch64, Advanced SIMD, unaligned accesses.
 */

	src1	.req	x0
	src2	.req	x1
	limit	.req	x2
	result	.req	w0
	data1	.req	x3
	data1w	.req	w3
	data2	.req	x4
	data2w	.req	w4
	data3	.req	x5
	data3w	.req	w5
	data4	.req	x6
	data4w	.req	w6
	tmp	.req	x6
	src1end	.req	x7
	src2end	.req	x8

	.section ".text", "ax", %progbits
	.globl	memcmp
	.globl	bcmp
memcmp:
bcmp:
	cmp	limit, 16
	b.lo	.Lless16
	ldp	data1, data3, [src1]
	ldp	data2, data4, [src2]
	ccmp	data1, data2, 0, ne
	ccmp	data3, data4, 0, eq
	b.ne	.Lreturn2

	add	src1end, src1, limit
	add	src2end, src2, limit
	cmp	limit, 32
	b.ls	.Llast_bytes
	cmp	limit, 160
	b.hs	.Lloop_align
	sub	limit, limit, 32

	.p2align 4
.Lloop32:
	ldp	data1, data3, [src1, 16]
	ldp	data2, data4, [src2, 16]
	cmp	data1, data2
	ccmp	data3, data4, 0, eq
	b.ne	.Lreturn2
	cmp	limit, 16
	b.ls	.Llast_bytes

	ldp	data1, data3, [src1, 32]
	ldp	data2, data4, [src2, 32]
	cmp	data1, data2
	ccmp	data3, data4, 0, eq
	b.ne	.Lreturn2
	add	src1, src1, 32
	add	src2, src2, 32
.Llast64:
	subs	limit, limit, 32
	b.hi	.Lloop32

	/* Compare last 1-16 bytes using unaligned access.  */
.Llast_bytes:
	ldp	data1, data3, [src1end, -16]
	ldp	data2, data4, [src2end, -16]
.Lreturn2:
	cmp	data1, data2
	csel	data1, data1, data3, ne
	csel	data2, data2, data4, ne

	/* Compare data bytes and set return value to 0, -1 or 1.  */
.Lreturn:
#ifndef __AARCH64EB__
	rev	data1, data1
	rev	data2, data2
#endif
	cmp	data1, data2
	cset	result, ne
	cneg	result, result, lo
	ret

	.p2align 4
.Lless16:
	add	src1end, src1, limit
	add	src2end, src2, limit
	tbz	limit, 3, .Lless8
	ldr	data1, [src1]
	ldr	data2, [src2]
	ldr	data3, [src1end, -8]
	ldr	data4, [src2end, -8]
	b	.Lreturn2

	.p2align 4
.Lless8:
	tbz	limit, 2, .Lless4
	ldr	data1w, [src1]
	ldr	data2w, [src2]
	ldr	data3w, [src1end, -4]
	ldr	data4w, [src2end, -4]
	b	.Lreturn2

.Lless4:
	tbz	limit, 1, .Lless2
	ldrh	data1w, [src1]
	ldrh	data2w, [src2]
	cmp	data1w, data2w
	b.ne	.Lreturn
.Lless2:
	mov	result, 0
	tbz	limit, 0, .Lreturn_zero
	ldrb	data1w, [src1end, -1]
	ldrb	data2w, [src2end, -1]
	sub	result, data1w, data2w
.Lreturn_zero:
	ret

.Lloop_align:
	ldp	data1, data3, [src1, 16]
	ldp	data2, data4, [src2, 16]
	cmp	data1, data2
	ccmp	data3, data4, 0, eq
	b.ne	.Lreturn2

	/* Align src2 and adjust src1, src2 and limit.  */
	and	tmp, src2, 15
	sub	tmp, tmp, 16
	sub	src2, src2, tmp
	add	limit, limit, tmp
	sub	src1, src1, tmp
	sub	limit, limit, 64 + 16

	.p2align 4
.Lloop64_:
	ldr	q0, [src1, 16]
	ldr	q1, [src2, 16]
	subs	limit, limit, 64
	ldr	q2, [src1, 32]
	ldr	q3, [src2, 32]
	eor	v0.16b, v0.16b, v1.16b
	eor	v1.16b, v2.16b, v3.16b
	ldr	q2, [src1, 48]
	ldr	q3, [src2, 48]
	umaxp	v0.16b, v0.16b, v1.16b
	ldr	q4, [src1, 64]!
	ldr	q5, [src2, 64]!
	eor	v1.16b, v2.16b, v3.16b
	eor	v2.16b, v4.16b, v5.16b
	umaxp	v1.16b, v1.16b, v2.16b
	umaxp	v0.16b, v0.16b, v1.16b
	umaxp	v0.16b, v0.16b, v0.16b
	fmov	tmp, d0
	ccmp	tmp, 0, 0, hi
	b.eq	.Lloop64_

	/* If equal, process last 1-64 bytes using scalar loop.  */
	add	limit, limit, 64 + 16
	cbz	tmp, .Llast64

	/* Determine the 8-byte aligned offset of the first difference.  */
#ifdef __AARCH64EB__
	rev16	tmp, tmp
#endif
	rev	tmp, tmp
	clz	tmp, tmp
	bic	tmp, tmp, 7
	sub	tmp, tmp, 48
	ldr	data1, [src1, tmp]
	ldr	data2, [src2, tmp]
#ifndef __AARCH64EB__
	rev	data1, data1
	rev	data2, data2
#endif
	mov	result, 1
	cmp	data1, data2
	cneg	result, result, lo
	ret

	.unreq	src1
	.unreq	src2
	.unreq	limit
	.unreq	result
	.unreq	data1
	.unreq	data1w
	.unreq	data2
	.unreq	data2w
	.unreq	data3
	.unreq	data3w
	.unreq	data4
	.unreq	data4w
	.unreq	tmp
	.unreq	src1end
	.unreq	src2end

