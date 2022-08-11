#![no_std]
#![no_main]
#![feature(unwrap_infallible)]

use crate::table::SystemTable;

/// Interface to system-level functionality implemented in assembly and to
/// system structures.
mod sys;

/// Memory allocation and protection functionality.
mod mem;

/// Trap handling and management functionality.
mod trap;

/// Functionality related to the parsing of the system table.
mod table;

#[no_mangle]
pub unsafe extern "C" fn kernel_main(system_table: SystemTable) {
	sys::trap_handler_setup();

	mem::init(&system_table);
}

#[panic_handler]
fn on_panic(_: &core::panic::PanicInfo) -> ! {
	loop {}
}
