# AArch64 compiler intrinsics

This crate provides implementations of compiler intrinsics such as memcpy and
memset, using optimized ARM assembly. These will supersede the generic Rust
versions at link time.

The optimized routines are taken from the (ARM optimized-routines GitHub repo)[https://github.com/ARM-software/optimized-routines].

Declare using `extern crate aarch64_intrinsics;` in the crate root to pull it
into a build.
