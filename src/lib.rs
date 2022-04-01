// SPDX-License-Identifier: MIT OR Apache-2.0 WITH LLVM-exception

#![no_std]
core::arch::global_asm!(include_str!("memcmp.s"));
core::arch::global_asm!(include_str!("memcpy.s"));
core::arch::global_asm!(include_str!("memset.s"));
