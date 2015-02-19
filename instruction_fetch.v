module instruction_fetch (
				instruction_register,
				memory_data_register,
				program_counter,
				incremented_program_counter
			);

input [15:0] memory_data_register;
input [7:0] program_counter;
output [15:0] instruction_register;
output [7:0] incremented_program_counter;

reg [15:0] instruction_register;
reg [7:0] incremented_program_counter;

always @(*)
begin
	instruction_register <= memory_data_register;
	incremented_program_counter <= program_counter + 1;
end
endmodule
