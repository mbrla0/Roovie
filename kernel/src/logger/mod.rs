use core::mem::MaybeUninit;
use log::{Metadata, Record};
use crate::SystemTable;
use crate::table::SystemDevice;
use crate::trap::critical;

mod neorv32_uart;

/// The global instance of the logger.
static mut LOGGER: MaybeUninit<Logger> = MaybeUninit::uninit();

/// Initialize the system logger.
pub unsafe fn init(sys: &SystemTable) {
	let logger = sys
		.devices()
		.filter_map(|device| unsafe {
			Logger::instance(device)
		})
		.next();
	if let Some(logger) = logger {
		critical(|| {
			LOGGER = MaybeUninit::new(logger);
			let _ = log::set_logger_racy(LOGGER.assume_init_ref());
		})
	}
}

/// Available logger implementations in the system.
enum Logger {
	/// Serial implementation on top of the NEORV32 UART device.
	Serial(neorv32_uart::Serial)
}
impl Logger {
	/// Tries to instance a logger implementation from the given system device.
	pub unsafe fn instance(device: SystemDevice) -> Option<Self> {
		Some(match device.class() {
			"neorv32-uart" => Self::Serial(neorv32_uart::Serial(device.csr())),
			_ => return None
		})
	}
}
impl log::Log for Logger {
	fn enabled(&self, metadata: &Metadata) -> bool {
		match self {
			Logger::Serial(serial) => serial.enabled(metadata)
		}
	}

	fn log(&self, record: &Record) {
		match self {
			Logger::Serial(serial) => serial.log(record)
		}
	}

	fn flush(&self) {
		match self {
			Logger::Serial(serial) => serial.flush()
		}
	}
}