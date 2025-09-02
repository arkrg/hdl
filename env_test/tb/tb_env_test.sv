module tb_env_test();

wire a, b, c;

assign a = 0;
assign b = 1;
env_test dut (.a, .b, .c);

initial begin
	#10
	$display("************RESULT************");
	$display("REF:	a: %d, b: %d, c: %d", a, b, a&b);
	$display("OUT:	a: %d, b: %d, c: %d", a, b, c);
	$finish;
end

initial begin
	$dumpfile("waveform.vcd");
	$dumpvars();
end
endmodule
