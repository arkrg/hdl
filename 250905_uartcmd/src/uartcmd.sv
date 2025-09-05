module uartcmd#(
    parameter OSR           = 16,
    parameter BAUD          = 9600,
    parameter DATALEN       = 8,
    parameter SYS_FREQUENCY = 100_000_000,
    //******
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter DIV_1KHz = 100_000  // for fnd scanning
)(
    input clk,
    input rst,
    input  rx
);
    reg [DATALEN-1:0] ucmd;
    reg ucmd_ud, ucmd_clr, ucmd_rnstp;
    wire [DATALEN-1:0] trx_data;
    wire rx_done_tx_start;

    uart #(
        .OSR(OSR),
        .BAUD(BAUD),
        .DATALEN(DATALEN),
        .SYS_FREQUENCY(SYS_FREQUENCY)
    ) u_uart (
        .clk     (clk),
        .rst     (rst),
        .tx_data (trx_data),
        .tx_start(rx_done_tx_start),
        .rx      (rx),
        .tx      (tx),
        .tx_busy (tx_busy),
        .rx_data (trx_data),
        .rx_busy (rx_busy),
        .rx_done (rx_done_tx_start)
    );

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ucmd <= 0;
        end else begin
            if(rx_done_tx_start) begin
                ucmd <= trx_data
            end else
                ucmd <= 0;
        end
    end
    
    always @(*) begin
        {ucmd_ud, ucmd_clr, ucmd_rnstp} = 3'b000;
        case(ucmd)
            "m": {ucmd_ud, ucmd_clr, ucmd_rnstp} = 3'b100;
            "c": {ucmd_ud, ucmd_clr, ucmd_rnstp}= 3'b010;
            "r": {ucmd_ud, ucmd_clr, ucmd_rnstp}= 3'b001;
        endcase
    end

    uart_cmd_counter #(
        .DIV(DIV),
        .DIV_1KHz (DIV_1KHz),
        .MAX_COUNT(MAX_COUNT)
    )(
 .clk           ( clk       ),  
 .rst           ( rst       ),  
 .ucmd_ud       ( ucmd_ud   ),  
 .ucmd_clr      ( ucmd_clr  ),  
 .ucmd_rnstp    ( ucmd_rnstp),  
 .fnd_data      ( fnd_data  ),  
 .fnd_com       ( fnd_com   )    
        );
endmodule


module uart_cmd_counter #(
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter DIV_1KHz = 100_000  // for fnd scanning
)(
    input        clk,
    input        rst,
    input        ucmd_ud,
    input        ucmd_clr,
    input        ucmd_rnstp,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);
    localparam WIDTH_COUNTER = $clog2(MAX_COUNT),
    updn_counter_controller u_controller (
        .clk(clk),
        .rst(rst),
        .ud(updn_debounce),
        .rnstp(rnstp_debounce),
        .clr(clr_debounce),
        .ctrl_ud(ctrl_ud),
        .ctrl_clr(ctrl_clr),
        .ctrl_en(ctrl_en)
    );

    updn_counter_datapath #(
        .DIV(DIV),
        .MAX_COUNT(MAX_COUNT)
    ) u_datapath (
        .clk(clk),
        .rst(rst),
        .ud(ctrl_ud),
        .clr(ctrl_clr),
        .en(ctrl_en),
        .count(count)
    );

    fnd_controller #(
        .DIV_1KHz (DIV_1KHz),
        .MAX_COUNT(MAX_COUNT)
    ) u_fndcontroller (
        .clk(clk),
        .rst(rst),
        .count(count),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    
endmodule
