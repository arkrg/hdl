module tb_env_test();

wire a, b, c;

assign a = 0;
assign b = 1;
env_test dut (.a, .b, .c);

reg t1;


initial begin

    #10
	$display("************RESULT************");
	$display("REF:	a: %d, b: %d, c: %d", a, b, a&b);
	$display("OUT:	a: %d, b: %d, c: %d", a, b, c);
t1 = $random(2);
	$display("t1:%d", t1);
  #10
	$finish;
end

initial begin
	$dumpfile("waveform.vcd");
	$dumpvars();
end
endmodule
