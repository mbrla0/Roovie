
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