// this is a simple pipelining code
// read pipe_ex.txt for notes

module pipe_ex (zout, rs1, rs2, rd, func, addr, clk1, clk2);

	input [3:0] rs1, rs2, rd, func;
	input [7:0] addr;
	input clk1, clk2;
	output [15:0] zout;
	
	reg [15:0] L12_A, L12_B, L23_z, L34_z;
	reg [3:0] L12_rd, L12_func, L23_rd;
	reg [7:0] L12_addr, L23_addr, L34_addr;
	
	reg [15:0] regbank [0:15];
	reg [15:0] mem [0:255];   // 256 x 16 bit memory
	
	assign zout = L34_z;
	
	always @ (posedge clk1)  //stage 1
		begin
		L12_A <= #2 regbank[rs1];
		L12_B <= #2 regbank[rs2];
		L12_rd <= #2 rd;
		L12_func <= #2 func;
		L12_addr <= #2 addr; 
		end
		
	always @ (negedge clk2)  //stage 2
		begin
			case (func)
			0 : L23_z <= #2 L12_A + L12_B;
			1 : L23_z <= #2 L12_A - L12_B;
			2 : L23_z <= #2 L12_A * L12_B;
			3 : L23_z <= #2 L12_A;
			4 : L23_z <= #2 L12_B;
			5 : L23_z <= #2 L12_A & L12_B;
			6 : L23_z <= #2 L12_A | L12_B;
			7 : L23_z <= #2 L12_A ^ L12_B;
			8 : L23_z <= #2 - L12_A;
			9 : L23_z <= #2 - L12_B;
			10 : L23_z <= #2 L12_A >> 1;
			11 : L23_z <= #2 L12_A << 1;
			default: L23_z <= #2 16'hxxxx;
			endcase
			
			L23_rd <= #2 L12_rd;
			L23_addr <= #2 L12_addr;
		end
		
		always @ (posedge clk1) //stage 3
			begin
			regbank [L23_rd] <= #2 L23_z;
			L34_z <= #2 L23_z;
			L34_addr <= #2 L23_addr;
			end
			
		always @ (negedge clk2) //stage 4
			begin
			mem [L34_addr] <= #2 L34_z;
			end


endmodule
	

module pipe_ex_tb;

	wire [15:0] zout;
	reg [3:0] rs1, rs2, rd, func;
	reg [7:0] addr;
	reg clk1, clk2;
	integer k;
	
	pipe_ex m (zout, rs1, rs2, rd, func, addr, clk1, clk2);
	
	initial
		begin 
		clk1 = 0; clk2 = 0;
		repeat(20)
			begin
			#5 clk1 = 1; #5 clk1 = 0;
			#5 clk2 = 1; #5 clk2 = 0;
			end
		end
		
	initial 
		for (k = 0; k <16; k = k + 1)
			m.regbank [k] = k;
			
	initial
		begin
		#5 rs1 = 2; rs2 = 3; rd = 4; func = 0; addr = 109;
		#20 rs1 = 4; rs2 = 5; rd = 2; func = 8; addr = 100;
		#20 rs1 = 2; rs2 = 1; rd = 7; func = 3; addr = 101;
		#20 rs1 = 9; rs2 = 10; rd = 11; func = 2; addr = 102;
		
		#60 for (k = 95; k < 115; k = k + 1)
			$display ("Mem[%d] = %d", k, m.mem[k]);
		end
		
	initial
		begin
		$monitor ("Time: %d, F = %d", $time, zout);
		#300 $finish;
		end
		
endmodule