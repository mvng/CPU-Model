module tc140l (
		clock,
		reset,
		program_counter,
		register_A, 
		memory_data_register_out, 
		instruction_register,
		out
	      );

input clock,reset;
output [7:0] program_counter;
output [15:0] register_A, memory_data_register_out, instruction_register, out;

reg  [15:0] register_A,  instruction_register, out;
reg  [7:0] program_counter;
reg  [4:0] state;

reg [7:0] ind_add;

// State Encodings
parameter	reset_pc	= 5'h0,
		fetch			= 5'h1,
		decode			= 5'h2,
		execute_add 	= 5'h3,
		execute_store 	= 5'h4,
		execute_store2 	= 5'h5,
		execute_store3	 = 5'h6,
		execute_load	= 5'h7,
		execute_jump	= 5'h8,
		execute_jump_n = 5'h9,
		execute_out		= 5'ha,
		execute_xor		= 5'hb,
		execute_or		= 5'hc,
		execute_and		= 5'hd,
		execute_jpos	= 5'he,
		execute_jzero	= 5'hf,
		execute_addi	= 5'h10,
		execute_shl		= 5'h11,
		execute_shr		= 5'h12,
		execute_sub    = 5'h13,
		execute_rand 	=5'h14,
		execute_addind  = 5'h15,
		execute_addpcr  = 5'h16
;

reg [7:0] memory_address_register;
reg memory_write;
reg [3:0] doge = 4'h0;
integer x = 0;


wire [15:0] memory_data_register;
wire [15:0] memory_data_register_out = memory_data_register;
wire [15:0] memory_address_register_out = memory_address_register;
wire memory_write_out = memory_write;
wire [15:0] instruction_register_fetch;
wire [4:0] state_from_decode_unit;
wire [7:0] incremented_program_counter;
wire acc_is_zero;

instruction_fetch IF(
				instruction_register_fetch,
				memory_data_register,
				program_counter,
				incremented_program_counter
			);

instruction_decoder ID(
				state_from_decode_unit,
				instruction_register
			);

// Use Altsynram function for computer's memory (256 16-bit words)
altsyncram	RAM (
					.wren_a 	(memory_write_out),
					.clock0 	(clock),
					.address_a 	(memory_address_register_out),
					.data_a 	(register_A),
					.q_a 		(memory_data_register)
				     );
defparam
	RAM.operation_mode	= "SINGLE_PORT",
	RAM.width_a 		= 16,
	RAM.widthad_a 		= 8,
	RAM.outdata_reg_a 	= "UNREGISTERED",
	RAM.lpm_type 		= "altsyncram",
	RAM.init_file 		= "addpcr.mif",
	RAM.intended_device_family = "Cyclone";

// Control Block : Control State Machine
// ALU operations can be seen as state actions in EXECUTE control state
   always @(posedge clock or posedge reset)  begin
	if (reset)  begin
          state           <= reset_pc;
	       program_counter <= 8'b00000000;
   	    register_A      <= 16'b0000000000000000;
	       out             <= 16'h0 ;
   end
   else  begin
	   case (state)
		// reset the computer, need to clear some registers
       		reset_pc :
       		begin
					doge = 4'h0;
					
					
					program_counter <= 8'b00000000;
					register_A <= 16'b0000000000000000;
					out <= 16'h0;
					state <= fetch;
					
       		end
		// Fetch instruction from memory and add 1 to program counter
       		fetch :
       		begin
					instruction_register <= instruction_register_fetch;
					program_counter <= incremented_program_counter;
					state <= decode;
       		end
		// Decode instruction and send out address of any required data operands
       		decode :
       		begin
					state <= state_from_decode_unit;
       		end
		// Execute the ADD instruction
       		execute_add :
       		begin
					register_A <= register_A + memory_data_register;
					state <= fetch;
       		end
		// Execute the STORE instruction (needs three clock cycles for memory write)
       		execute_store :
       		begin
		// write register_A to memory
 					state <= execute_store2;
       		end
		// This state ensures that the memory address is valid until after memory_write goes low
       		execute_store2 :
       		begin
				state <= execute_store3;
       		end
		// Execute the LOAD instruction
       		execute_load :
       		begin
				register_A <= memory_data_register;
				state <= fetch;
       		end
 		// Execute the JUMP instruction
       		execute_jump :
       		begin
				program_counter <= instruction_register[7:0];
				state <= fetch;
       		end
	 	// Execute the JUMP A negative instruction      		
       		execute_jump_n :
       		begin
				program_counter <= (register_A[15]==1'h1)? instruction_register[7:0] : program_counter ;
				state <= fetch;
       		end
		// Execute the SUB instruction
       		execute_sub :
       		begin
					register_A <= register_A - memory_data_register;
					state <= fetch;
       		end
		// Execute the XOR instruction
       		execute_xor :
       		begin
					register_A <= register_A ^ memory_data_register;
					state <= fetch;
       		end
		// Execute the OR instruction
       		execute_or :
       		begin
					register_A <= register_A | memory_data_register;
					state <= fetch;
       		end
		// Execute the AND instruction
       		execute_and :
       		begin
					register_A <= register_A & memory_data_register;
					state <= fetch;
       		end
	 	// Execute the JUMP A positive instruction      		
       		execute_jpos :
       		begin
				program_counter <= (register_A[15]==1'h0)? instruction_register[7:0] : program_counter ;
				state <= fetch;
       		end
	 	// Execute the JUMP A ZERO instruction      		
       		execute_jzero:
       		begin
				program_counter <= (acc_is_zero==1'b1)? instruction_register[7:0] : program_counter ;
				state <= fetch;
       		end
	 	// Execute the ADD Immediate instruction      		
       		execute_addi :
       		begin
				register_A <= register_A + instruction_register[7:0];
				state <= fetch;
       		end
	 	// Execute the SHIFT LEFT instruction      		
       		execute_shl :
       		begin
				register_A <= register_A << instruction_register[3:0];
				state <= fetch;
       		end
	 	// Execute the SHIFT RIGHT instruction      		
       		execute_shr :
       		begin
				register_A <= register_A >> instruction_register[3:0];
				state <= fetch;
       		end
		// Execute the OUT instruction      		
       		execute_out :
       		begin
				out <= register_A ;
				state <= fetch ;
       		end   		
       		
     // Execute the RANDOM instruction
			execute_rand:
			begin
				
					doge = doge + 1;
			
				if(doge == 4'h0)begin
					doge = 4'h1;
					end
					
				case(doge) 
					4'h1: register_A<= 4'h5;
					4'h2: register_A<= 4'hA;
					4'h3: register_A<= 4'h4;
					4'h4: register_A<= 4'h8;
					4'h5: register_A<= 4'h0;
					4'h6: register_A<= 4'h1;
					4'h7: register_A<= 4'h3;
					4'h8: register_A<= 4'h7;
					4'h9: register_A<= 4'he;
					4'ha: register_A<= 4'hd;
					4'hb: register_A<= 4'hb;
					4'hc: register_A<= 4'h6;
					4'hd: register_A<= 4'hC;
					4'he: register_A<= 4'h9;
					4'hf: register_A<= 4'h2;				
				endcase

				//out <= register_A;
				state <= fetch;
			end
		       	
 	// Execute the ADDIND instruction
	
			execute_addind:
			begin
			
			//0210 4611 4613 4611 4613 4611
			//10 = 03       
			//11 = 12   -> 09
			//12 = 09  
			//13 = 10   -> 03
		
			//memory data = 3 12 10 12 10 12
			//memory wan = 03 09 03 09 03 09
			
			//out <= memory_data_register;
			
			state<=execute_add;
			
			end
			
	//Execute the ADDPCR instruction
			execute_addpcr:
			begin
				out<=memory_address_register;
				state<=execute_add;
			end
			
			
       		default :
       		begin
				state <= fetch;
       		end
		endcase
		
	end // end of else begin...
     
	end // end of always begin...
	

     
	  
	  assign acc_is_zero = ((			 register_A[15]	|
						 register_A[14]	|
						 register_A[13]	|
						 register_A[12]	|
						 register_A[11]	|
						 register_A[10]	|
						 register_A[9]	|
						 register_A[8]	|
						 register_A[7]	|
						 register_A[6]	|
						 register_A[5]	|
						 register_A[4]	|
						 register_A[3]	|
						 register_A[2]	|
						 register_A[1]	|
						 register_A[0]
						) ==1'h0);
// Memory Address Register Update Block:     
// Block to enable Memory Write
 //always @(state or program_counter or instruction_register)
 always @( * )
   begin


		
	case (state)
		reset_pc: 		memory_address_register <= 8'h 00;
		fetch:			memory_address_register <= program_counter;
		decode:			memory_address_register <= instruction_register[7:0];
		execute_add: 	memory_address_register <= program_counter;
		execute_store:  memory_address_register <= instruction_register[7:0];
		execute_store2: memory_address_register <= program_counter;
		execute_load:	memory_address_register <= program_counter;
		execute_jump:	memory_address_register <= instruction_register[7:0];
		execute_jump_n:	memory_address_register <= (register_A[15]==1'h1)? instruction_register[7:0] : program_counter ;
		execute_sub: 	memory_address_register <= program_counter;
		execute_xor: 	memory_address_register <= program_counter;
		execute_or: 	memory_address_register <= program_counter;
		execute_and: 	memory_address_register <= program_counter;
		execute_jpos:	memory_address_register <= (register_A[15]==1'h0)? instruction_register[7:0] : program_counter ;
		execute_jzero:	memory_address_register <= (acc_is_zero==1'h1)? instruction_register[7:0] : program_counter ;
		execute_addi: 	memory_address_register <= program_counter;
		execute_shl: 	memory_address_register <= program_counter;
		execute_shr: 	memory_address_register <= program_counter;
		execute_out:	memory_address_register <= program_counter;
		execute_rand:   memory_address_register <= program_counter;
		execute_addind: memory_address_register <= memory_data_register;
		execute_addpcr: memory_address_register <= program_counter + instruction_register[7:0];
						


		default: 		memory_address_register <= program_counter;
	endcase
	case (state)
		execute_store: 		memory_write <= 1'b 1;
		default:	 	memory_write <= 1'b 0;
	endcase

  end		
endmodule
