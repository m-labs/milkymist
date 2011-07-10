/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
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

module ac97_ctlif #(
	parameter csr_addr = 4'h0
) (
	input sys_clk,
	input sys_rst,

	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,
	
	output reg crrequest_irq,
	output reg crreply_irq,
	output reg dmar_irq,
	output reg dmaw_irq,
	
	input down_en,
	input down_next_frame,
	output reg down_addr_valid,
	output reg [19:0] down_addr,
	output reg down_data_valid,
	output reg [19:0] down_data,

	input up_en,
	input up_next_frame,
	input up_frame_valid,
	input up_addr_valid,
	input [19:0] up_addr,
	input up_data_valid,
	input [19:0] up_data,
	
	output reg dmar_en,
	output reg [29:0] dmar_addr,
	output reg [15:0] dmar_remaining,
	input dmar_next,
	output reg dmaw_en,
	output reg [29:0] dmaw_addr,
	output reg [15:0] dmaw_remaining,
	input dmaw_next
);

wire dmar_finished = dmar_remaining == 16'd0;
reg dmar_finished_r;
always @(posedge sys_clk) begin
	if(sys_rst)
		dmar_finished_r <= 1'b1;
	else
		dmar_finished_r <= dmar_finished;
end
wire dmaw_finished = dmaw_remaining == 16'd0;
reg dmaw_finished_r;
always @(posedge sys_clk) begin
	if(sys_rst)
		dmaw_finished_r <= 1'b1;
	else
		dmaw_finished_r <= dmaw_finished;
end

wire csr_selected = csr_a[13:10] == csr_addr;

reg request_en;
reg request_write;
reg [6:0] request_addr;
reg [15:0] request_data;
reg [15:0] reply_data;
always @(posedge sys_clk) begin
	if(sys_rst) begin
		csr_do <= 32'd0;
		request_en <= 1'b0;
		request_write <= 1'b0;
		request_addr <= 7'd0;
		request_data <= 16'd0;
		
		down_addr_valid <= 1'b0;
		down_data_valid <= 1'b0;
		
		dmar_en <= 1'b0;
		dmar_addr <= 30'd0;
		dmar_remaining <= 16'd0;
		dmaw_en <= 1'b0;
		dmaw_addr <= 30'd0;
		dmaw_remaining <= 16'd0;
		
		crrequest_irq <= 1'b0;
		crreply_irq <= 1'b0;
		dmar_irq <= 1'b0;
		dmaw_irq <= 1'b0;
	end else begin
		crrequest_irq <= 1'b0;
		crreply_irq <= 1'b0;
		dmar_irq <= 1'b0;
		dmaw_irq <= 1'b0;
	
		if(down_en & down_next_frame) begin
			down_addr_valid <= request_en;
			down_addr <= {20{request_en}} & {~request_write, request_addr, 12'd0};
			down_data_valid <= request_en & request_write;
			down_data <= {20{request_en & request_write}} & {request_data, 4'd0};
			
			request_en <= 1'b0;
			if(request_en)
				crrequest_irq <= 1'b1;
		end
		if(up_en & up_next_frame) begin
			if(up_frame_valid & up_addr_valid & up_data_valid) begin
				crreply_irq <= 1'b1;
				reply_data <= up_data[19:4];
			end
		end
		
		if(dmar_next) begin
			dmar_addr <= dmar_addr + 30'd1;
			dmar_remaining <= dmar_remaining - 16'd1;
		end
		if(dmaw_next) begin
			dmaw_addr <= dmaw_addr + 30'd1;
			dmaw_remaining <= dmaw_remaining - 16'd1;
		end
		
		if(dmar_finished & ~dmar_finished_r)
			dmar_irq <= 1'b1;
		if(dmaw_finished & ~dmaw_finished_r)
			dmaw_irq <= 1'b1;
	
		csr_do <= 32'd0;
		if(csr_selected) begin
			if(csr_we) begin
				case(csr_a[3:0])
					/* Codec register access */
					4'b0000: begin
						request_en <= csr_di[0];
						request_write <= csr_di[1];
					end
					4'b0001: request_addr <= csr_di[6:0];
					4'b0010: request_data <= csr_di[15:0];
					// Reply Data is read-only
					
					/* Downstream */
					4'b0100: dmar_en <= csr_di[0];
					4'b0101: dmar_addr <= csr_di[31:2];
					4'b0110: dmar_remaining <= csr_di[17:2];
					
					/* Upstream */
					4'b1000: dmaw_en <= csr_di[0];
					4'b1001: dmaw_addr <= csr_di[31:2];
					4'b1010: dmaw_remaining <= csr_di[17:2];
				endcase
			end
			case(csr_a[3:0])
				/* Codec register access */
				4'b0000: csr_do <= {request_write, request_en};
				4'b0001: csr_do <= request_addr;
				4'b0010: csr_do <= request_data;
				4'b0011: csr_do <= reply_data;
				
				/* Downstream */
				4'b0100: csr_do <= dmar_en;
				4'b0101: csr_do <= {dmar_addr, 2'b00};
				4'b0110: csr_do <= {dmar_remaining, 2'b00};

				/* Upstream */
				4'b1000: csr_do <= dmaw_en;
				4'b1001: csr_do <= {dmaw_addr, 2'b00};
				4'b1010: csr_do <= {dmaw_remaining, 2'b00};
			endcase
		end
	end
end

endmodule
