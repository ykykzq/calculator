//加减法
//当op_code为3'b001时执行减法，否则均执行加法
module Add_Sub(operand_x,operand_y,op_code,result,carry_out,overflow);
	input [2:0]op_code;
	input [31:0]operand_x;
	input [31:0]operand_y;
	output carry_out;
	output [31:0]result;
	output overflow;
	//内部变量
	reg [31:0]B;//对第二个操作数处理后的结果
	reg carry_in;

	//B
	always@(operand_y or op_code)
		if(op_code==3'b001)//减法
			B=~operand_y;
		else				//加法
			B=operand_y;

	//carry_in
	always@(op_code)
		if(op_code==3'b001)
			carry_in<=1'b1;
		else
			carry_in<=1'b0;
	
	//result
	assign {carry_out,result}=carry_in+B+operand_x;
	
	//overflow
	assign overflow=((operand_x[31]^operand_y[31])^(~op_code[0]))//值为1的条件为001(/110，同号加法)或100(/010，异号减法)
						&(operand_x[31]^result[31]);//值为1的条件为结果与第一个数符号相反
	
endmodule


//乘法
module mul(reset,clk,op_code,operand_x,operand_y,result,busy,overflow,
				ADD_A,ADD_B,op_code_inner,ADD_RESULT,overflow_inner);
				
	//计算的是x*y
	//输入
	input reset;
	input clk;
	input [2:0]op_code;//区分加(000)减(001)乘(010)除(011)
	input [31:0]operand_x;//补码
	input [31:0]operand_y;//补码
	//输出
	output reg[64:0]result;//补码
	output reg busy;
	output reg overflow;
	
	//加法器变量
	output reg [31:0]ADD_A;
	output reg [31:0]ADD_B;
	output reg [2:0]op_code_inner;//内部调用加法器时的参数,区分加(000)减(001),零(010)
	input wire [31:0]ADD_RESULT;
	input wire overflow_inner;
	
	//内部信号
	reg [5:0]counter;
	reg [31:0]Multiplicand;//被乘数
	
	///////////////////////////////////////////////////////////////
	//加法部分
	
	//ADD_A
	always@(result)
			ADD_A<=result[64:33];
	
		
	//ADD_B
	always@(Multiplicand or op_code_inner)
	begin
		if(op_code_inner==3'b000||op_code_inner==3'b001)
			ADD_B<=Multiplicand;
		else//op_code_inner=010,即零的情况
			ADD_B=32'b0;
	end
	
	///////////////////////////////////////////////////
	//一些控制信号
	//计数器
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			counter<=6'b0;
		else if(op_code==3'b010)
			counter<=6'b1000_00;
		else if(busy)
			counter<=counter-1;
		else	
			counter<=counter;
	end
	
	//busy信号
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			busy<=1'b0;
		else if(op_code==3'b010)//乘法
			busy<=1'b1;
		else if(busy==1'b1 && counter==6'b0000_00)
			busy<=1'b0;
		else
			busy<=busy;
	end
	
	//op_code_inner
	always@(result or busy or counter or op_code)
	begin
		if(busy)//乘法状态
		begin
			if(result[1:0]==2'b00 || result[1:0]==2'b11 || counter==6'b0)
				op_code_inner<=3'b010;//零
			else if(result[1:0]==2'b01)
				op_code_inner<=3'b000;//加乘数
			else
				op_code_inner<=3'b001;//减乘数
				
		end
		else//加减法
			op_code_inner=op_code;
	end
	
	//overflow
	always@(posedge clk or posedge reset)
		if(reset)
			overflow<=1'b0;
		else if(overflow_inner)//先判断是否加法溢出，再判断是否为第一次加法的情况
			overflow<=1'b1;
		else if(op_code==3'b010)
			overflow<=1'b0;
		else
			overflow<=1'b0;
	
	/////////////////////////////////////////////////////////////////////////
	//两个主要的数据存储寄存器
	//被乘数(x)寄存器,Multiplicand
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			Multiplicand<=32'b0000_0000_0000_0000_0000_0000_0000_0000;
		else if(op_code==3'b010)
			Multiplicand<=operand_x;
		else 
			Multiplicand<=Multiplicand;
	end
	
	//65位的result寄存器
	always@(posedge reset or posedge clk)
	begin
		if(reset)
			result<=65'b0;
		else if(op_code==3'b010)//进入工作状态
			result<={32'b0,operand_y,1'b0};//放入乘数
		else if(busy)
			result<={ADD_RESULT[31],ADD_RESULT,result[32:1]};//带符号数右移
	end

endmodule 




  //计算器
module calculator(clk,reset,op_code,operand_x,operand_y,result,busy,overflow,carry_out);
	//输入
	input clk;
	input reset;
	input [2:0]op_code;//区分加(000)减(001)乘(010)除(011)
	input [31:0]operand_x;//补码
	input [31:0]operand_y;//补码
	//输出
	output reg[31:0]result;//补码
	output reg busy;
	output reg overflow;//是否溢出
	output reg carry_out;//进位输出

	//加法器变量
	reg[31:0] as_operand_x;
	reg[31:0] as_operand_y;
	reg[2:0]  as_op_code;
	wire[31:0]as_result;
	wire      as_carry_out;
	wire      as_overflow;

	//乘法器变量
	wire[64:0]mul_result;
	wire      mul_busy;
	wire      mul_overflow;
	wire[31:0]mul_ADD_A;
	wire[31:0]mul_ADD_B;
	wire[2:0] mul_op_code_inner;
	reg [31:0]mul_ADD_RESULT;
	reg       mul_overflow_inner;
	
	
	
	//调用加法器
	Add_Sub AS_inner(
		.operand_x(as_operand_x),
		.operand_y(as_operand_y),
		.op_code(as_op_code),
		.result(as_result),
		.carry_out(as_carry_out),
		.overflow(as_overflow)
		);
	
	//调用乘法器
	mul mul_inner(
		.reset(reset),
		.clk(clk),
		.op_code(op_code),
		.operand_x(operand_x),
		.operand_y(operand_y),
		.result(mul_result),
		.busy(mul_busy),
		.overflow(mul_overflow),
		.ADD_A(mul_ADD_A),
		.ADD_B(mul_ADD_B),
		.op_code_inner(mul_op_code_inner),
		.ADD_RESULT(mul_ADD_RESULT),
		.overflow_inner(mul_overflow_inner)
		);
		
	/////////////////////////////////////////
	//控制加法器的输入
	
	//as_operand_x
	always@(mul_ADD_A)
		as_operand_x<=mul_ADD_A;
		
	//as_operand_y
	always@(mul_ADD_B)
		as_operand_y<=mul_ADD_B;
		
	//as_op_code
	always@(mul_op_code_inner)
		as_op_code<=mul_op_code_inner;
	
	
	/////////////////////////////////////////
	//控制乘法器内嵌的加法器结果输入
	
	//mul_ADD_RESULT
	always@(as_result)
		mul_ADD_RESULT<=as_result;
		
	//mul_overflow_inner
	always@(as_overflow)
		mul_overflow_inner<=as_overflow;
		
		
	//////////////////////////////////////////
	//控制计算器的输出
	
	//result
	always@(mul_result)
		result<=mul_result[63:0];
		
	//busy	
	always@(mul_busy)
		busy<=mul_busy;
	
	//overflow
	always@(mul_overflow)
		overflow<=mul_overflow;
	
endmodule 
