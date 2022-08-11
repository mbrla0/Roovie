use core::arch::asm;

/// Execute the given closure as a critical section.
///
/// When running in single-threaded mode, use this function to ensure writes and
/// reads to mutable static variables are safe. This function masks interrupts
/// for the duration of the closure, temporarily halting concurrency.
///
pub unsafe fn critical<F, T>(func: F) -> T
	where F: FnOnce() -> T {

	// Preserve interrupt enablement state and disable all interrupts.
	let state: usize;
	asm!("csrrw {}, mie, x0", out(reg) state);

	let ret = (func)();

	// Restore previous interrupt enablement.
	asm!("csrrw x0, mie, {}", in(reg) state);

	ret
}
