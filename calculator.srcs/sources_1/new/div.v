//除法器
module div(reset,clk,op_code,operand_x,operand_y,busy,quotient,x_inner);
	//计算的是x/y
	//输入
	input reset;
	input clk;
	input [2:0]op_code;//区分加(000)减(001)乘(010)除(011)
	input [31:0]operand_x;//补码
	input [31:0]operand_y;//补码
	//输出
	output reg busy;
	output reg [31:0]quotient;//商
	output reg [32:0]x_inner;// x/余数,多一位
	
	//内部信号
	reg [32:0]ADD_A,ADD_B;
	wire [32:0]ADD_RESULT;
	reg ADD_CIN;
	wire c_out_inner;
	reg [5:0]counter;
	reg [32:0]y_inner;//y,多一位
	reg sel;//选择 Y的补码/-Y的补码
	
	//////////////////////////////////////////////////
	//主要的存储单元
	
	//x_inner,被除数/余数寄存器
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			x_inner<=33'b0;
		else if(op_code==3'b011)//进入工作状态
			x_inner<={operand_x[31],operand_x};//补一位符号位
		else
			x_inner<={ADD_RESULT,1'b0};
	end
	
	//y_inner,除数寄存器
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			y_inner<=33'b0;
		else if(op_code==3'b011)//进入工作状态
			y_inner<={operand_y[31],operand_y};
		else
			y_inner<=y_inner;
	end
	
	//quotient,商寄存器
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			quotient<=33'b0;
		else if(counter==6'b0000_01)//最后一次计算，商末位置1
			quotient<={quotient[30:0],1'b1};
		else if(busy)
			quotient<={quotient[30:0],~(ADD_RESULT[32]^y_inner[32])};
		else
			quotient<=quotient;
	end
	
	//////////////////////////////////////////////////////////
	//加法器部分
	
	//加法器
	assign {c_out_inner,ADD_RESULT}=ADD_A+ADD_B+ADD_CIN;
	
	//ADD_A
	always@(x_inner)
		ADD_A<=x_inner;
		
	//ADD_B
	always@(sel or y_inner)
	begin
		if(sel)
			ADD_B<=~y_inner;
		else
			ADD_B<=y_inner;
	end
	
	//ADD_CIN
	always@(sel)
		ADD_CIN<=sel;
		
	////////////////////////////////////////////////////////////////////////
	//一些控制信号
	
	//sel,控制选择 Y的补码/-Y的补码
	always@(posedge clk)
	begin
		if(reset)
			sel<=1'b0;
		else if(op_code==3'b011)
			sel<=~(operand_x[31]^operand_y[31]);
		else if(busy)
			sel<=~sel;
		else
			sel<=sel;
	end
	
	//busy,是否处于工作状态
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			busy<=1'b0;
		else if(op_code==3'b011)
			busy<=1'b1;
		else if(busy==1'b1 && counter==6'b0000_01)
			busy<=1'b0;
		else
			busy<=busy;
	end
	
	//counter,计数器
	always@(posedge clk or posedge reset)
	begin
		if(reset)
			counter<=6'b1000_00;//32
		else if(op_code==3'b011)
			counter<=6'b1000_00;
		else if(busy)
			counter=counter-1;
		else 
			counter<=counter;
	end
	
	
	
endmodule