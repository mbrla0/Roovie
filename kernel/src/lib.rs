#![no_std]
#![no_main]
#![feature(unwrap_infallible)]

/// Interface to system-level functionality implemented in assembly and to
/// system structures.
mod sys;

#[no_mangle]
pub unsafe extern "C" fn kernel_main(system_table: sys::SystemTable) {
	sys::trap_handler_setup();
}
