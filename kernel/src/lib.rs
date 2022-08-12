#![no_std]
#![no_main]
#![feature(unwrap_infallible)]

use crate::sys::KernelImage;
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

/// Functionality related to logging information.
mod logger;

#[no_mangle]
pub unsafe extern "C" fn kernel_main(system_table: SystemTable, image: KernelImage) {
	sys::trap_handler_setup();

	logger::init(&system_table);
	log::info!("Booting Roovie");

	mem::init(&system_table);
}

pub unsafe extern "C" fn kernel_main_proper() {

}

#[panic_handler]
fn on_panic(_: &core::panic::PanicInfo) -> ! {
	log::error!("Panic!");
	loop {}
}
