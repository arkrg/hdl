module counter_top #(
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter WIDTH_COUNTER = $clog2(MAX_COUNT),
    parameter DIV_1KHz = 100_000  // for fnd scanning
) (
    input        clk,
    input        rst,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);

    wire [WIDTH_COUNTER-1:0] count;
    counter_datapath #(
        .DIV(DIV),
        .MAX_COUNT(MAX_COUNT)
    ) u_datapath (
        .clk  (clk),
        .rst  (rst),
        .count(count)
    );
    fnd_controller #(
        .DIV_1KHz(DIV_1KHz),
        .MAX_COUNT(MAX_COUNT)
    ) u_fndcontroller (
        .clk(clk),
        .rst(rst),
        .count(count),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

endmodule

module counter_datapath #(
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter WIDTH_COUNTER = $clog2(MAX_COUNT)
) (
    input                      clk,
    input                      rst,
    output [WIDTH_COUNTER-1:0] count
);
    reg [3:0] _fnd_com;

    tick_generator #(
        .DIV(DIV)
    ) u_tick_generator (
        .clk (clk),
        .rst (rst),
        .tick(tick)
    );

    counter #(
        .MAX_COUNT(MAX_COUNT)
    ) u_counter (
        .rst  (rst),
        .clk  (clk),
        .tick (tick),
        .count(count)
    );

endmodule

module counter #(
    parameter MAX_COUNT = 10_000,
    parameter WIDTH = $clog2(MAX_COUNT)
) (
    input              rst,
    input              clk,
    input              tick,
    output [WIDTH-1:0] count
);
    reg [WIDTH-1:0] r_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_count <= 0;
        end else begin
            if (tick) begin
                if (r_count < MAX_COUNT -1) begin
                    r_count <= r_count + 1;
                end else r_count <= 0;
            end
        end
    end
    assign count = r_count;

endmodule

module tick_generator #(
    // 100M -> 10Hz
    parameter DIV = 10_000_000,
    parameter WIDTH_COUNTER  = $clog2(DIV)
) (
    input  clk,
    input  rst,
    output tick
);
    reg [WIDTH_COUNTER-1:0] r_count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_count <= 0;
        end else begin
            if (r_count > DIV - 1) r_count <= 0;
            else r_count <= r_count + 1;
        end
    end

    assign tick = (r_count == DIV-1);
endmodule
