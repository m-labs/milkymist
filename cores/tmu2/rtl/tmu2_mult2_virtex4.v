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

module tmu2_mult2(
	input sys_clk,
	input ce,

	input [12:0] a,
	input [12:0] b,
	output [25:0] p
);

DSP48 #(
	.AREG(1), // Number of pipeline registers on the A input, 0, 1 or 2
	.BREG(1), // Number of pipeline registers on the B input, 0, 1 or 2
	.B_INPUT("DIRECT"), // B input DIRECT from fabric or CASCADE from another DSP48
	.CARRYINREG(0), // Number of pipeline registers for the CARRYIN input, 0 or 1
	.CARRYINSELREG(0), // Number of pipeline registers for the CARRYINSEL, 0 or 1
	.CREG(0), // Number of pipeline registers on the C input, 0 or 1
	.LEGACY_MODE("MULT18X18"), // Backward compatibility, NONE, MULT18X18 or MULT18X18S
	.MREG(0), // Number of multiplier pipeline registers, 0 or 1
	.OPMODEREG(0), // Number of pipeline regsiters on OPMODE input, 0 or 1
	.PREG(1), // Number of pipeline registers on the P output, 0 or 1
	.SUBTRACTREG(0) // Number of pipeline registers on the SUBTRACT input, 0 or 1
) DSP48_inst (
	.BCOUT(), // 18-bit B cascade output
	.P(p), // 48-bit product output
	.PCOUT(), // 48-bit cascade output
	.A(a), // 18-bit A data input
	.B(b), // 18-bit B data input
	.BCIN(18'd0), // 18-bit B cascade input
	.C(48'd0), // 48-bit cascade input
	.CARRYIN(1'b0), // Carry input signal
	.CARRYINSEL(2'd0), // 2-bit carry input select
	.CEA(ce), // A data clock enable input
	.CEB(ce), // B data clock enable input
	.CEC(1'b1), // C data clock enable input
	.CECARRYIN(1'b1), // CARRYIN clock enable input
	.CECINSUB(1'b1), // CINSUB clock enable input
	.CECTRL(1'b1), // Clock Enable input for CTRL regsiters
	.CEM(1'b1), // Clock Enable input for multiplier regsiters
	.CEP(ce), // Clock Enable input for P regsiters
	.CLK(sys_clk), // Clock input
	.OPMODE(7'h35), // 7-bit operation mode input
	.PCIN(48'd0), // 48-bit PCIN input
	.RSTA(1'b0), // Reset input for A pipeline registers
	.RSTB(1'b0), // Reset input for B pipeline registers
	.RSTC(1'b0), // Reset input for C pipeline registers
	.RSTCARRYIN(1'b0), // Reset input for CARRYIN registers
	.RSTCTRL(1'b0), // Reset input for CTRL registers
	.RSTM(1'b0), // Reset input for multiplier registers
	.RSTP(1'b0), // Reset input for P pipeline registers
	.SUBTRACT(1'b0) // SUBTRACT input
);

endmodule
