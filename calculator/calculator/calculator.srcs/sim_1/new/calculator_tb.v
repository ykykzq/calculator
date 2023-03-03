`timescale 1ns/1ns
module calculator_tb();
	reg clk;
	reg reset;
	reg[2:0]op_code;
	reg[31:0]operand_x;
	reg[31:0]operand_y;
	wire[63:0]result;
	wire busy;
	wire overflow;
	wire carry_out;

	initial
		begin
			clk<=0;
			reset<=1'b1;
			op_code<=3'b000;
			operand_x<=0;
			operand_y<=0;
			#40
			reset<=1'b0;
			
			#100
			op_code<=3'b010;
			operand_x<=55;
			operand_y<=31;
			#2
			op_code<=3'b000;
			operand_x<=0;
			operand_y<=0;
			
			#100
			op_code<=3'b010;
			operand_x<=-2;
			operand_y<=-1;
			#2
			op_code<=3'b000;
			operand_x<=0;
			operand_y<=0;
			
			#100
			op_code<=3'b010;
			operand_x<=2147483647;
			operand_y<=-1;
			#2
			op_code<=3'b000;
			operand_x<=0;
			operand_y<=0;
		end
		
	always #1 clk<=~clk;
		
	calculator calculator_1(
		.clk(clk),
		.reset(reset),
		.op_code(op_code),
		.operand_x(operand_x),
		.operand_y(operand_y),
		.result(result),
		.busy(busy),
		.overflow(overflow),
		.carry_out(carry_out)
		);
endmodule
