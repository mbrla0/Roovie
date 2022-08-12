use core::mem::MaybeUninit;
use arrayvec::ArrayVec;
use crate::KernelImage;
use crate::table::SystemTable;
use crate::trap::critical;

/// Runtime state for the memory subsystem.
struct State {
	/// Information on the kernel memory region.
	kernel: Kernel,

	/// Heaps of shared memory.


	/// Protected memory buckets on the main heap.
	buckets: ArrayVec<AllocationBucket, 16>
}

/// A structure containing the state of the kernel memory region.
struct Kernel {
	base: usize,
	size: usize,

	ro_base: usize,
	ro_size: usize,

	rw_base: usize,
	rw_size: usize,

	stack_top: usize,
	stack_size: usize,
}

/// A structure containing the state of a protected bucket of memory.
struct AllocationBucket {

}

/// Instance holding the runtime state for the current subsystem.
static mut STATE: MaybeUninit<State> = MaybeUninit::uninit();

/// Initialize the memory management structures in the system.
pub unsafe fn init(system_table: &SystemTable, image: &KernelImage) {
	let protection = system_table.memory();

	critical(|| {
		STATE = MaybeUninit::new(State {
			buckets: Default::default()
		})
	})
}



