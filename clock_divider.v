module clock_divider (clk, rst_n, sw, clk_o);

integer DIV_CONST    = 10000000;

input clk;

input rst_n;
input sw;

output reg clk_o;

reg [31:0] div;
reg en;

always @ (*) begin
if(sw == 1)
	DIV_CONST = 2000000;
else
	DIV_CONST = 10000000;
end
always @ (posedge clk or negedge rst_n)
begin

	if (!rst_n)
	begin
		div <= 0;
		en <= 0;
	end	
	else
	begin
		if (div == DIV_CONST)
		begin
			div <= 0;
			en <= 1;
		end
		else
		begin
			div <= div + 1;
			en <= 0;
		end
	end
	
end

always @ (posedge clk or negedge rst_n)
begin
if (!rst_n)
begin
	clk_o <= 1'b0;
end
else if (en)
	clk_o <= ~clk_o;
end

endmodule
