#![no_std]
#![no_main]

/// Interface to system-level functionality implemented in assembly.
mod sys;

#[no_mangle]
pub unsafe extern "C" fn kernel_main() {
	sys::trap_handler_setup();

}
