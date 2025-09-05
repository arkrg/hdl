`define S_SIM
module tb_uart_rx ();
    parameter CASE_TIME = 5;
`ifdef S_SIM
    parameter OSR = 5;
    parameter BAUD = 1_000_000;
    parameter DIV = 10_000,
    parameter MAX_COUNT = 10_000,
    parameter DIV_1KHz = 100
`else
    parameter OSR = 16;
    parameter BAUD = 9600;
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter DIV_1KHz = 100_000  // for fnd scanning
`endif
    parameter DATALEN = 8;
    parameter SYS_FREQUENCY = 100_000_000;
    parameter PERIOD_BIT =  SYS_FREQUENCY/BAUD*10;
   
    
    localparam FAIL = 0, PASS= 1;
    reg [DATALEN-1:0] case_data, case_golden, case_recieved_data;
    integer case_fail, case_pass;

    reg clk, rst;
    reg rx;      
    
    wire tx;
    wire [DATALEN -1:0] rx_to_tx_data; 
    wire rx_done_tx_start;  
    wire rx_busy;
    
    integer i;
    integer case_index;
    // integer i, j;

    uartcmd #(
        .OSR          (OSR),
        .DATALEN      (DATALEN),
        .BAUD         (BAUD),
        .SYS_FREQUENCY(SYS_FREQUENCY)
        .DIV(DIV),
        .MAX_COUNT(MAX_COUNT),
        .DIV_1KHz(DIV_1KHz)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .rx      (rx)
        // .rx_data (rx_to_tx_data),
        // .rx_busy (rx_busy),
        // .rx_done (rx_done_tx_start),
        // .tx_data (rx_to_tx_data),
        // .tx_start(rx_done_tx_start),
        // .tx      (tx),
        // .tx_busy (tx_busy)
    );
    initial begin 
        clk <= 0;
        rst <= 0;
        rx <= 1;
        case_fail <= 0;
        case_pass <= 0;
        # 10;
        rst <= 1;
        # 10;
        rst <= 0;
        #(PERIOD_BIT);
        $display("[%t] reset released", $time);

        // for (case_index = 0; case_index < CASE_TIME; case_index++) begin
        //     case_data = {$random} % 2**DATALEN;
        //     verification();
        // end
        #(PERIOD_BIT);
        
        $display("**********-**********-**********-**********-**********");
        $display("                        REPORT");
        $display("**********-**********-**********-**********-**********");
        $display("FAIL : %d", case_fail );
        $display("PASS : %d", case_pass);
        $display("**********-**********-**********-**********-**********");


        $finish;
    end

    always #5 clk <= ~clk;
    initial begin 
        $dumpfile("waves.vcd");
        $dumpvars();
    end

    task verification();
    fork
        send_uart(case_data);
        monitor_uart();
    join
    endtask: verification


    task send_uart(
        input [DATALEN-1:0] case_data
    );
        begin
            case_golden = case_data;
            @(negedge clk); 
            $display("[%t] SEND_UART: rx de-asserted, START", $time);
            rx = 0;
            #(PERIOD_BIT);
            for (i = 0; i < DATALEN; i++) begin
                $display("[%d] SEND_UART: send %dth bit: %d", $time, i, case_data[i]);
                rx = case_data[i];
                #(PERIOD_BIT);
            end
            $display("[%t] SEND_UART: keep rx asserted for 1 bit-period", $time);
            rx = 1;
            #(PERIOD_BIT);

            $display("[%t] SEND_UART: single rx transaction is done", $time);

            end
        endtask: send_uart

        task monitor_uart();
            begin
                integer bitcnt;
            case_recieved_data = 0;
            @(negedge tx);
            $display("[%t] MONITOR_UART: UART_TX starts sending data", $time);
            #(PERIOD_BIT);
            #(PERIOD_BIT/2);
            for (bitcnt = 0; bitcnt < DATALEN; bitcnt++) begin
                $display("[%d] MONITOR_UART: sampled %dth bit: %d", $time, bitcnt, tx);
                case_recieved_data[bitcnt] = tx;
                #(PERIOD_BIT);
            end
            $display("[%t] MONITOR_UART: UART_TX finished sending data", $time);
            #(PERIOD_BIT/2);
            if (case_recieved_data == case_golden) begin
                case_pass = case_pass +1;
                $display("*PASS, REC:%b, GOLDEN: %b", case_recieved_data, case_golden);
            end else begin
                case_fail = case_fail +1;
                $display("*FAIL, REC:%b, GOLDEN: %b", case_recieved_data, case_golden);
            end
        end
    endtask:monitor_uart 

endmodule

