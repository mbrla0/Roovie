use core::fmt::Write;
use log::{Metadata, Record};
use crate::trap::critical;

/// Serial implementation on top of the NEORV32 UART device.
pub struct Serial(pub *mut u32);
impl log::Log for Serial {
	fn enabled(&self, metadata: &Metadata) -> bool {
		true
	}
	fn log(&self, record: &Record) {
		let _ = write!(Interface(self.0), "{}", record.args());
	}
	fn flush(&self) {
		unsafe {
			critical(|| loop {
				let busy = self.0.read_volatile() & 0x40000;
				if busy == 0 { break }
			})
		}
	}
}
unsafe impl Send for Serial {}
unsafe impl Sync for Serial {}

struct Interface(*mut u32);
impl Interface {
	/// Calling this function may be unsafe outside of a critical section.
	#[inline]
	unsafe fn write_byte(&self, byte: u8) {
		unsafe {
			/* Wait until the interface buffer can handle more bytes. */
			loop {
				let busy = self.0.read_volatile() & 0x40000;
				if busy == 0 { break }
			}

			/* Write the character to the data register. */
			self.0.write_volatile(byte as u32);
		}
	}
}
impl Write for Interface {
	fn write_str(&mut self, s: &str) -> core::fmt::Result {
		unsafe {
			critical(|| for i in s.as_bytes() {
				self.write_byte(*i)
			})
		}
		Ok(())
	}
}