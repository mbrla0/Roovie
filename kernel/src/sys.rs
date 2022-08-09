use core::ffi::{c_char, CStr};
use core::mem::size_of;
extern "C" {
	/// Performs a far jump.
	///
	/// This jump takes execution to the address given by `target`, also making
	/// it so that the stack pointer points to the address given by `stack`. It
	/// may be, therefore, used in situations such as stack relocation or task
	/// switching, where the flow of execution has to be dictated entirely by
	/// a new and foreign stack.
	#[link_name = "sys_procedure_stack_jump"]
	pub fn stack_jump(stack: *mut u32, target: *mut u32) -> !;

	/// Sets up the trap handler.
	#[link_name = "sys_procedure_trap_handler_setup"]
	pub fn trap_handler_setup();
}

/// Generates instances of section pointer getter function.
macro_rules! section_ptr_functions {
	(
		$(
			$(#[$a:meta])*
			pub unsafe fn $name:ident => $offset:expr;
		)+
	) => {
		$(
			$(#[$a])*
			pub unsafe fn $name(&self) -> *const u32 {
				let offset = self.0.offset($offset).read_unaligned();
				let offset = isize::try_from(offset).unwrap();

				self.0.offset(offset)
			}
		)+
	}
}

/// Generates instances of section size getter function.
macro_rules! section_size_functions {
	(
		$(
			$(#[$a:meta])*
			pub unsafe fn $name:ident => $offset:expr;
		)+
	) => {
		$(
			$(#[$a])*
			pub unsafe fn $name(&self) -> u32 {
				self.0.offset($offset).read_unaligned()
			}
		)+
	}
}

/// The system table handed to us by the bootloader.
#[repr(transparent)]
pub struct SystemTable(*const u32);
impl SystemTable {
	/// Size of the system table header, in 32-bit words.
	const HEADER_SIZE: usize = 6;

	/// Offset of the pointer to the loader section, in 32-bit words.
	const HEADER_LOADER_PTR_OFFSET: isize = 0;
	/// Offset of the pointer to the memory regions section, in 32-bit words.
	const HEADER_MEMREG_PTR_OFFSET: isize = 2;
	/// Offset of the pointer to the devices section, in 32-bit words.
	const HEADER_DEVICE_PTR_OFFSET: isize = 4;
	/// Offset of the pointer to the strings section, in 32-bit words.
	const HEADER_STRING_PTR_OFFSET: isize = 5;

	/// Offset to the size of the memory regions section, in 32-bit words.
	const HEADER_MEMREG_SIZE_OFFSET: isize = 1;
	/// Offset to the size of the devices section, in 32-bit words.
	const HEADER_DEVICE_SIZE_OFFSET: isize = 3;

	section_ptr_functions! {
		#[inline]
		#[doc = "Returns a pointer to the beginning of the loader section."]
		pub unsafe fn loader_section_ptr => Self::HEADER_LOADER_PTR_OFFSET;
		#[inline]
		#[doc = "Returns a pointer to the beginning of the memory regions section."]
		pub unsafe fn memory_regions_section_ptr => Self::HEADER_MEMREG_PTR_OFFSET;
		#[inline]
		#[doc = "Returns a pointer to the beginning of the devices section."]
		pub unsafe fn devices_section_ptr => Self::HEADER_DEVICE_PTR_OFFSET;
		#[inline]
		#[doc = "Returns a pointer to the beginning of the strings section."]
		pub unsafe fn strings_section_ptr => Self::HEADER_STRING_PTR_OFFSET;
	}

	section_size_functions! {
		#[inline]
		#[doc = "Returns the number of elements in the memory regions section."]
		pub unsafe fn memory_regions_section_size => Self::HEADER_MEMREG_SIZE_OFFSET;
		#[inline]
		#[doc = "Returns the number of elements in the devices section."]
		pub unsafe fn devices_section_size => Self::HEADER_DEVICE_SIZE_OFFSET;
	}

	/// Returns a handle to the loader information declared in this instance of
	/// the system table.
	pub unsafe fn loader(&self) -> SystemLoader {
		SystemLoader {
			loader: self.loader_section_ptr(),
			table: Default::default()
		}
	}

	/// Returns a handle to the memory regions declared in this instance of the
	/// system table.
	pub unsafe fn memory_regions(&self) -> SystemMemoryRegions {
		SystemMemoryRegions {
			regions: self.memory_regions_section_ptr(),
			index: 0,
			length: self.memory_regions_section_size() as usize,
			table: Default::default()
		}
	}

	/// Returns an iterator over the devices declared in this instance of the
	/// system table.
	pub unsafe fn devices(&self) -> SystemDevices {
		SystemDevices {
			devices: self.devices_section_ptr(),
			strings: self.strings_section_ptr(),
			index: 0,
			length: self.memory_regions_section_size() as usize,
			table: Default::default()
		}
	}
}

/// The description of how the loader loaded the system.
///
/// This structure always corresponds to and reads data from the loader section
/// of the system table. It provides a more convenient, and, more importantly,
/// an ABI-neutral interface to the data in that section.
///
pub struct SystemLoader<'a> {
	loader: *const u32,
	table: core::marker::PhantomData<&'a SystemTable>
}
impl<'a> SystemLoader<'a> {
	/// Size of the system device structure in 32-bit words.
	const SIZE: usize = 2;

	/// Offset of the kernel address value, in 32-bit words.
	const KERNEL_ADDRESS_OFFSET: isize = 0;
	/// Offset of the stack address value, in 32-bit words.
	const STACK_ADDRESS_OFFSET: isize = 2;

	/// Returns the address where the loader has loaded the kernel.
	pub unsafe fn kernel(&self) -> usize {
		let value = self.loader.offset(Self::KERNEL_ADDRESS_OFFSET).read_unaligned();
		usize::try_from(value).unwrap()
	}

	/// Returns the address where the loader has set up the stack.
	pub unsafe fn stack(&self) -> usize {
		let value = self.loader.offset(Self::STACK_ADDRESS_OFFSET).read_unaligned();
		usize::try_from(value).unwrap()
	}
}

/// The description of a memory region in the system.
///
/// This structure always corresponds to and reads data from one of the entries
/// in the memory regions section of the system table. It provides a more
/// convenient, and, more importantly, an ABI-neutral interface to the data in
/// that section.
///
pub struct SystemMemoryRegion<'a> {
	region: *const u32,
	table: core::marker::PhantomData<&'a SystemTable>
}
impl<'a> SystemMemoryRegion<'a> {
	/// Size of the system device structure in 32-bit words.
	const SIZE: usize = 3;

	/// Offset of the region descriptor value, in 32-bit words.
	const DESCRIPTOR_OFFSET: isize = 0;
	/// Offset of the pointer to the beginning of the region, in 32-bit words.
	const BEGINNING_PTR_OFFSET: isize = 1;
	/// Offset of the region length value, in 32-bit words.
	const LENGTH_OFFSET: isize = 2;

	/// Returns the length of this memory region, in bytes.
	pub unsafe fn len(&self) -> usize {
		let value = self.region.offset(Self::LENGTH_OFFSET).read_unaligned();
		usize::try_from(value).unwrap()
	}

	/// Returns a pointer to the beginning of this memory region.
	pub unsafe fn as_ptr(&self) -> *mut u32 {
		let address = self.region.offset(Self::BEGINNING_PTR_OFFSET).read_unaligned();
		let address = usize::try_from(address).unwrap();

		address as *mut u32
	}

	/// Returns the alignment of this memory region.
	#[inline]
	pub unsafe fn alignment(&self) -> usize {
		let leading = self.as_ptr().leading_zeros() as usize;
		1 << leading
	}
}

/// The description of a device in the system.
///
/// This structure always corresponds to and reads data from one of the entries
/// in the device section of the system table. It provides a more convenient,
/// and, more importantly, an ABI-neutral interface to the data in that section.
///
pub struct SystemDevice<'a> {
	device: *const u32,
	strings: *const u32,
	table: core::marker::PhantomData<&'a SystemTable>
}
impl<'a> SystemDevice<'a> {
	/// Size of the system device structure in 32-bit words.
	const SIZE: usize = 2;

	/// Offset of the pointer to the CSR, in 32-bit words.
	const CSR_PTR_OFFSET: isize = 1;
	/// Offset of the pointer to the class name in the string section, in 32-bit words.
	const CLASS_PTR_OFFSET: isize = 0;

	/// The base address of the memory-mapped I/O region containing the control
	/// and status registers of this instance.
	pub unsafe fn csr(&self) -> *mut u32 {
		let address = self.device.offset(Self::CSR_PTR_OFFSET).read_unaligned();
		usize::try_from(address).unwrap() as *mut u32
	}

	/// The class of device to which this particular instance belongs.
	pub unsafe fn class(&self) -> &str {
		let offset = self.device.offset(Self::CLASS_PTR_OFFSET).read_unaligned();
		let offset = isize::try_from(offset).unwrap();

		let ptr = self.strings.offset(offset) as *const c_char;
		let str = CStr::from_ptr(ptr).to_str().unwrap();

		str
	}
}

/// Iterator over the memory regions declared in the system table.
///
/// Instances of this structure are obtained through the [`memory_regions()`]
/// function in the [system table].
///
/// [`memory_regions()`]: SystemTable::memory_regions
/// [system table]: SystemTable
pub struct SystemMemoryRegions<'a> {
	regions: *const u32,
	index: usize,
	length: usize,
	table: core::marker::PhantomData<&'a SystemTable>
}
impl<'a> Iterator for SystemMemoryRegions<'a> {
	type Item = SystemMemoryRegion<'a>;
	fn next(&mut self) -> Option<Self::Item> {
		unsafe {
			if self.index >= self.length { return None }

			let region = self.index * SystemMemoryRegion::SIZE;
			let region = SystemMemoryRegion {
				region: self.regions.offset(region as isize),
				table: Default::default()
			};

			self.index += 1;
			Some(region)
		}
	}
}

/// Iterator over the devices declared in the system table.
///
/// Instances of this structure are obtained through the [`devices()`] function
/// in the [system table].
///
/// [`devices()`]: SystemTable::devices
/// [system table]: SystemTable
pub struct SystemDevices<'a> {
	devices: *const u32,
	strings: *const u32,
	index: usize,
	length: usize,
	table: core::marker::PhantomData<&'a SystemTable>
}
impl<'a> Iterator for SystemDevices<'a> {
	type Item = SystemDevice<'a>;
	fn next(&mut self) -> Option<Self::Item> {
		unsafe {
			if self.index >= self.length { return None }

			let device = self.index * SystemDevice::SIZE;
			let device = SystemDevice {
				device: self.devices.offset(device as isize),
				strings: self.strings,
				table: Default::default()
			};

			self.index += 1;
			Some(device)
		}
	}
}
