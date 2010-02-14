/*
 * Milkymist VJ SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module tmu2_writebuffer #(
	parameter fml_depth = 26
) (
	input sys_clk,
	input sys_rst,

	output busy,
	input flush,

	input pipe_stb_i,
	output pipe_ack_o,
	input [15:0] color,
	input [fml_depth-1-1:0] dadr,

	output reg [fml_depth-1:0] fml_adr,
	output reg fml_stb,
	input fml_ack,
	output reg [7:0] fml_sel,
	output [63:0] fml_do
);

/* Decode address */
wire [fml_depth-1:0] dadr8 = {dadr, 1'b0};
wire [1:0] dadr_windex = dadr8[2:1]; /* < position within the 64-bit word */
wire [1:0] dadr_index = dadr8[4:3]; /* < burst 64-bit word number */
wire [fml_depth-1-5:0] dadr_startadr = dadr8[fml_depth-1:5]; /* < burst start */

/* Memory allocation & tag logic */
wire en;

wire [1:0] tagmem_a;
wire tagmem_we;
wire [fml_depth-5+16-1:0] tagmem_di; /* < start address + 16x 16-bit word enables */
wire [fml_depth-5+16-1:0] tagmem_do;

wire [1:0] tagmem_a2;
wire [fml_depth-5+16-1:0] tagmem_do2;

tmu2_wb_tagmem #(
	.width(fml_depth-5+16)
) tagmem (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.a(tagmem_a),
	.we(tagmem_we),
	.di(tagmem_di),
	.do(tagmem_do),
	.a2(tagmem_a2),
	.do2(tagmem_do2)
);

wire [fml_depth-5-1:0] previous_startadr = tagmem_do[fml_depth-5-1+16:16];
wire hit = previous_startadr == dadr_startadr;

/* For flushing, we insert a new element with enable=0
 * this element is then ignored by the write engine.
 */
assign tagmem_di = {dadr_startadr,
	flush ? 16'd0 : ((hit ? tagmem_do[15:0] : 16'd0) | (16'h8000 >> {dadr_index, dadr_windex}))};
reg [1:0] tagmem_a_r;
assign tagmem_a = (hit & ~flush) ? tagmem_a_r : tagmem_a_r + 2'd1;
always @(posedge sys_clk) begin
	if(sys_rst)
		tagmem_a_r <= 2'd0;
	else if(en)
		tagmem_a_r <= tagmem_a;
end

assign tagmem_we = en;

reg write_done;
reg [2:0] level;
always @(posedge sys_clk) begin
	if(sys_rst)
		level = 3'd0;
	else begin
		if((en & ~hit) | flush)
			level = level + 3'd1;
		if(write_done)
			level = level - 3'd1;
		//$display("level: %d (%b %x %x) di:%x do:%x", level, hit, previous_startadr, dadr_startadr, tagmem_di, tagmem_do);
	end
end

assign pipe_ack_o = ~level[2];
assign en = pipe_ack_o & pipe_stb_i;

/* Write engine */
reg [1:0] tagmem_a2_r;
assign tagmem_a2 = write_done ? tagmem_a2_r + 2'd1 : tagmem_a2_r;
always @(posedge sys_clk) begin
	if(sys_rst)
		tagmem_a2_r <= 2'd0;
	else
		tagmem_a2_r <= tagmem_a2;
end

wire [3:0] datamem_a;
wire [3:0] datamem_we;
wire [3:0] datamem_a2;
wire [63:0] datamem_do2;
tmu2_wb_datamem datamem(
	.sys_clk(sys_clk),
	.a(datamem_a),
	.we(datamem_we),
	.di({color, color, color, color}),

	.a2(datamem_a2),
	.do2(datamem_do2)
);
assign datamem_a = {tagmem_a, dadr_index};
assign datamem_we = {4{en}} & (4'd8 >> dadr_windex);

wire burst_count;
reg [1:0] burst_counter;
wire [1:0] burst_counter_next = burst_count ? burst_counter + 2'd1 : 2'd0;
always @(posedge sys_clk)
	burst_counter <= burst_counter_next;

assign datamem_a2 = {tagmem_a2, burst_counter_next};

assign fml_do = datamem_do2;
always @(*) begin
	case(burst_counter)
		2'd0: fml_sel = {{2{tagmem_do2[15]}}, {2{tagmem_do2[14]}}, {2{tagmem_do2[13]}}, {2{tagmem_do2[12]}}};
		2'd1: fml_sel = {{2{tagmem_do2[11]}}, {2{tagmem_do2[10]}}, {2{tagmem_do2[ 9]}}, {2{tagmem_do2[ 8]}}};
		2'd2: fml_sel = {{2{tagmem_do2[ 7]}}, {2{tagmem_do2[ 6]}}, {2{tagmem_do2[ 5]}}, {2{tagmem_do2[ 4]}}};
		2'd3: fml_sel = {{2{tagmem_do2[ 3]}}, {2{tagmem_do2[ 2]}}, {2{tagmem_do2[ 1]}}, {2{tagmem_do2[ 0]}}};
	endcase
end
always @(posedge sys_clk) fml_adr <= {tagmem_do2[fml_depth-5+16-1:16], 5'd0};

wire dummy_write = tagmem_do2[15:0] == 16'd0;

wire pending_writes = |level;
assign busy = pending_writes;

reg [2:0] state;
reg [2:0] next_state;

parameter IDLE			= 3'd0;
parameter WORD1			= 3'd1;
parameter WORD2			= 3'd2;
parameter WORD3			= 3'd3;
parameter WORD4			= 3'd4;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	next_state = state;

	write_done = 1'b0;

	fml_stb = 1'b0;

	case(state)
		IDLE: begin
			if(pending_writes) begin
				if(dummy_write)
					next_state = WORD4;
				else
					next_state = WORD1;
			end
		end
		WORD1: begin
			fml_stb = 1'b1;
			if(fml_ack)
				next_state = WORD2;
		end
		WORD2: next_state = WORD3;
		WORD3: next_state = WORD4;
		WORD4: begin
			write_done = 1'b1;
			next_state = IDLE;
		end
	endcase
end

assign burst_count = fml_ack | (state == WORD2) | (state == WORD3) | (state == WORD4);

endmodule
