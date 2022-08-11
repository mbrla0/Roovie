use core::mem::MaybeUninit;
use arrayvec::ArrayVec;
use crate::table::SystemTable;
use crate::trap::critical;

/// Runtime state for the memory subsystem.
struct State {
	buckets: ArrayVec<Heap, 16>
}

/// A structure containing the state related to a single heap of memory.
struct Heap {

}

/// Instance holding the runtime state for the current subsystem.
static mut STATE: MaybeUninit<State> = MaybeUninit::uninit();

/// Initialize the memory management structures in the system.
pub unsafe fn init(system_table: &SystemTable) {
	let protection = system_table.memory();

	critical(|| {
		STATE = MaybeUninit::new(State {

		})
	})
}



