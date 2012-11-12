`include "lm32_include.v"

module soc();

integer i;

reg sys_rst;
reg sys_clk;
reg [31:0] interrupt;

reg i_ack;
wire [31:0] i_adr;
wire i_cyc;
wire [31:0] i_dat;
wire i_stb;

reg d_ack;
wire [31:0] d_adr;
wire d_cyc;
wire [31:0] d_dat_i;
wire [31:0] d_dat_o;
wire [3:0] d_sel;
wire d_stb;

lm32_top lm32(
	.clk_i(sys_clk),
	.rst_i(sys_rst),

	.interrupt(interrupt),

	.I_ACK_I(i_ack),
	.I_ADR_O(i_adr),
	.I_BTE_O(),
	.I_CTI_O(),
	.I_CYC_O(i_cyc),
	.I_DAT_I(i_dat),
	.I_DAT_O(),
	.I_ERR_I(1'b0),
	.I_LOCK_O(),
	.I_RTY_I(1'b0),
	.I_SEL_O(),
	.I_STB_O(i_stb),
	.I_WE_O(),

	.D_ACK_I(d_ack),
	.D_ADR_O(d_adr),
	.D_BTE_O(),
	.D_CTI_O(),
	.D_CYC_O(d_cyc),
	.D_DAT_I(d_dat_i),
	.D_DAT_O(d_dat_o),
	.D_ERR_I(1'b0),
	.D_LOCK_O(),
	.D_RTY_I(1'b0),
	.D_SEL_O(d_sel),
	.D_STB_O(d_stb),
	.D_WE_O(d_we)
);

// clock
initial sys_clk = 1'b0;
always #5 sys_clk = ~sys_clk;

// reset
initial begin
	sys_rst = 1'b1;
	#20
	sys_rst = 1'b0;
end

// data memory
reg [7:0] dmem[0:65536];
wire [31:0] dmem_dat_i;
reg [31:0] dmem_dat_o;
wire [13:0] dmem_adr;
wire [3:0] dmem_we;
initial begin
	for(i=0;i<65536;i=i+1)
		dmem[i] = 8'b0;
end
always @(posedge sys_clk) begin
	if(dmem_we[0]) dmem[{dmem_adr, 2'b11}] <= dmem_dat_i[7:0];
	if(dmem_we[1]) dmem[{dmem_adr, 2'b10}] <= dmem_dat_i[15:8];
	if(dmem_we[2]) dmem[{dmem_adr, 2'b01}] <= dmem_dat_i[23:16];
	if(dmem_we[3]) dmem[{dmem_adr, 2'b00}] <= dmem_dat_i[31:24];
	dmem_dat_o[7:0]   <= dmem[{dmem_adr, 2'b11}];
	dmem_dat_o[15:8]  <= dmem[{dmem_adr, 2'b10}];
	dmem_dat_o[23:16] <= dmem[{dmem_adr, 2'b01}];
	dmem_dat_o[31:24] <= dmem[{dmem_adr, 2'b00}];
end

// program memory
reg [7:0] pmem[0:65536];
wire [31:0] pmem_dat_i;
reg [31:0] pmem_dat_o;
wire [13:0] pmem_adr;
initial begin
	for(i=0;i<65536;i=i+1)
		pmem[i] = 8'b0;
end
always @(posedge sys_clk) begin
	pmem_dat_o[7:0]   <= pmem[{pmem_adr, 2'b11}];
	pmem_dat_o[15:8]  <= pmem[{pmem_adr, 2'b10}];
	pmem_dat_o[23:16] <= pmem[{pmem_adr, 2'b01}];
	pmem_dat_o[31:24] <= pmem[{pmem_adr, 2'b00}];
end

// uart
always @(posedge sys_clk) begin
	if(d_cyc & d_stb & d_we & d_ack)
		if(d_adr == 32'hff000000)
			$write("%c", d_dat_o[7:0]);
end

// wishbone interface for instruction bus
always @(posedge sys_clk) begin
	if(sys_rst)
		i_ack <= 1'b0;
	else begin
		i_ack <= 1'b0;
		if(i_cyc & i_stb & ~i_ack)
			i_ack <= 1'b1;
	end
end

assign i_dat = pmem_dat_o;
assign pmem_adr = i_adr[15:2];

// wishbone interface for data bus
always @(posedge sys_clk) begin
	if(sys_rst)
		d_ack <= 1'b0;
	else begin
		d_ack <= 1'b0;
		if(d_cyc & d_stb & ~d_ack)
			d_ack <= 1'b1;
	end
end

assign d_dat_i = dmem_dat_o;
assign dmem_dat_i = d_dat_o;
assign dmem_adr = d_adr[15:2];
assign dmem_we = {4{d_cyc & d_stb & d_we}} & d_sel;

// interrupts
initial interrupt = 32'b0;

// simulation end request
always @(posedge sys_clk) begin
	if(d_cyc & d_stb & d_we & d_ack)
		if(d_adr == 32'hdead0000 && d_dat_o == 32'hbeef)
			$finish;
end

// traces
`ifdef TB_ENABLE_WB_TRACES
always @(posedge sys_clk) begin
	if(i_cyc & i_stb & i_ack)
		$display("i load  @%08x %08x", i_adr, i_dat);
	if(d_cyc & d_stb & ~d_we & d_ack)
		$display("d load  @%08x %08x", d_adr, d_dat_o);
	if(d_cyc & d_stb & d_we & d_ack)
		$display("d store @%08x %08x", d_adr, d_dat_o);
end
`endif

// dump signals
initial $dumpfile("tb_lm32.vcd");
initial $dumpvars(0, soc);

// init memory
reg [256*8:0] prog;
initial begin
	if(! $value$plusargs("prog=%s", prog)) begin
		$display("ERROR: please specify +prog=<file>.vh to start.");
		$finish;
	end
end

initial $readmemh(prog, dmem);
initial $readmemh(prog, pmem);

// trace pipeline
reg [256*8:0] tracefile;
integer trace_started;
integer trace_enabled;
integer cycle;
integer tracefd;
initial begin
	if($value$plusargs("trace=%s", tracefile)) begin
		trace_enabled = 1;
		cycle = 0;
		tracefd = $fopen(tracefile);
		trace_started = 0;
	end else
		trace_enabled = 0;
end
assign icache_ready = lm32.cpu.instruction_unit.icache.state != 1;
assign dcache_ready = lm32.cpu.load_store_unit.dcache.state != 1;
always @(posedge sys_clk) begin
	// wait until icache and dcache init is done
	if(!trace_started && icache_ready && dcache_ready)
		trace_started = 1;
	if(trace_enabled && trace_started) begin
		$fwrite(tracefd, "%-d ", cycle);
		$fwrite(tracefd, "%x ", {lm32.cpu.instruction_unit.pc_a, 2'b00});
		$fwrite(tracefd, "%1d ", lm32.cpu.valid_a);
		$fwrite(tracefd, "%x ", {lm32.cpu.instruction_unit.pc_f, 2'b00});
		$fwrite(tracefd, "%1d ", lm32.cpu.kill_f);
		$fwrite(tracefd, "%1d ", lm32.cpu.valid_f);
		$fwrite(tracefd, "%x ", {lm32.cpu.instruction_unit.pc_d, 2'b00});
		$fwrite(tracefd, "%1d ", lm32.cpu.kill_d);
		$fwrite(tracefd, "%1d ", lm32.cpu.valid_d);
		$fwrite(tracefd, "%x ", {lm32.cpu.instruction_unit.pc_x, 2'b00});
		$fwrite(tracefd, "%1d ", lm32.cpu.kill_x);
		$fwrite(tracefd, "%1d ", lm32.cpu.valid_x);
		$fwrite(tracefd, "%x ", {lm32.cpu.instruction_unit.pc_m, 2'b00});
		$fwrite(tracefd, "%1d ", lm32.cpu.kill_m);
		$fwrite(tracefd, "%1d ", lm32.cpu.valid_m);
		$fwrite(tracefd, "%x ", {lm32.cpu.instruction_unit.pc_w, 2'b00});
		$fwrite(tracefd, "%1d ", lm32.cpu.kill_w);
		$fwrite(tracefd, "%1d ", lm32.cpu.valid_w);
		$fwrite(tracefd, "\n");
		cycle = cycle + 1;
	end
end

endmodule
