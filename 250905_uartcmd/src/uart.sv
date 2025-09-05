module uart_cloop #(
    parameter OSR           = 16,
    parameter BAUD          = 9600,
    parameter DATALEN       = 8,
    parameter SYS_FREQUENCY = 100_000_000
) (
    input  clk,
    input  rst,
    input  rx,
    output tx
);
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
endmodule

module uart #(
    parameter OSR           = 16,
    parameter BAUD          = 9600,
    parameter DATALEN       = 8,
    parameter SYS_FREQUENCY = 100_000_000
) (
    input                clk,
    input                rst,
    input  [DATALEN-1:0] tx_data,
    input                tx_start,
    input                rx,
    output               tx,
    output               tx_busy,
    output [DATALEN-1:0] rx_data,
    output               rx_busy,
    output               rx_done
);
    uart_bdgen #(
        .OSR(OSR),
        .BAUD(BAUD),
        .SYS_FREQUENCY(SYS_FREQUENCY)
    ) u_bdgen (
        .clk  (clk),
        .rst  (rst),
        .btick(btick)
    );
    uart_tx #(
        .OSR(OSR),
        .DATALEN(DATALEN)
    ) u_tx (
        .clk(clk),
        .rst(rst),
        .btick(btick),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );
    uart_rx #(
        .OSR(OSR),
        .BAUD(BAUD),
        .DATALEN(DATALEN)
    ) u_rx (
        .clk    (clk),
        .rst    (rst),
        .btick  (btick),
        .rx     (rx),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
    );

endmodule

module uart_tx #(
    parameter OSR = 16,
    parameter DATALEN = 8
) (
    input                clk,
    input                rst,
    input                btick,
    input  [DATALEN-1:0] tx_data,
    input                tx_start,
    output               tx,
    output               tx_busy
);
    localparam WIDTH_TICKCNT = $clog2(OSR);
    localparam WIDTH_BITCNT = $clog2(DATALEN);
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] c_state, n_state;
    reg [WIDTH_BITCNT-1:0] c_bitcnt, n_bitcnt;
    reg [WIDTH_TICKCNT-1:0] c_tickcnt, n_tickcnt;
    reg [DATALEN-1:0] c_txsr, n_txsr;
    reg n_tx, c_tx;
    reg n_busy, c_busy;

    assign tx = c_tx;
    assign tx_busy = c_busy;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state   <= IDLE;
            c_tx      <= 0;
            c_bitcnt  <= 0;
            c_tickcnt <= 0;
            c_busy    <= 0;
            c_txsr    <= 0;
        end else begin
            c_state   <= n_state;
            c_tx      <= n_tx;
            c_bitcnt  <= n_bitcnt;
            c_tickcnt <= n_tickcnt;
            c_busy    <= n_busy;
            c_txsr    <= n_txsr;
        end
    end

    always @(*) begin
        n_state   = c_state;
        n_tx      = c_tx;
        n_bitcnt  = c_bitcnt;
        n_tickcnt = c_tickcnt;
        n_txsr    = c_txsr;
        n_busy    = c_busy;
        case (c_state)
            IDLE: begin
                n_tx = 1;
                n_state = (tx_start) ? START : IDLE;
            end
            START: begin
                n_tx   = 0;
                n_busy = 1;
                n_txsr = tx_data;
                if (btick) begin
                    if (c_tickcnt == OSR - 1) begin
                        n_state   = DATA;
                        n_tickcnt = 0;
                    end else begin
                        n_tickcnt = c_tickcnt + 1;
                    end
                end
            end
            DATA: begin
                n_tx = c_txsr[0];
                if (btick) begin
                    if (c_tickcnt == OSR - 1) begin
                        n_tickcnt = 0;
                        if (c_bitcnt == DATALEN - 1) begin
                            n_bitcnt = 0;
                            n_state  = STOP;
                        end else begin
                            n_bitcnt = c_bitcnt + 1;
                            n_txsr   = c_txsr >> 1;
                        end
                    end else begin
                        n_tickcnt = c_tickcnt + 1;
                    end
                end
            end
            STOP: begin
                n_tx = 1;
                if (btick) begin
                    if (c_tickcnt == OSR - 1) begin
                        n_tickcnt = 0;
                        n_state = IDLE;
                        n_busy = 0;
                    end else begin
                        n_tickcnt = c_tickcnt + 1;
                    end
                end
            end
        endcase
    end
endmodule

module uart_bdgen #(
    parameter OSR = 16,
    parameter BAUD = 9600,
    parameter SYS_FREQUENCY = 100_000_000
) (
    input  clk,
    input  rst,
    output btick
);
    localparam BAUD_TICK_COUNT = SYS_FREQUENCY / BAUD / OSR;
    localparam WIDTH_COUNT = $clog2(BAUD_TICK_COUNT);
    reg [WIDTH_COUNT-1:0] r_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_count <= 0;
        end else begin
            if (r_count == BAUD_TICK_COUNT - 1) begin
                r_count <= 0;
            end else begin
                r_count <= r_count + 1;
            end
        end
    end

    assign btick = (r_count == BAUD_TICK_COUNT - 1);
endmodule


module uart_rx #(
    parameter OSR = 16,
    parameter BAUD = 9600,
    parameter DATALEN = 8,
    parameter SYS_FREQUENCY = 100_000_000
) (
    input                clk,
    input                rst,
    input                btick,
    input                rx,
    output [DATALEN-1:0] rx_data,
    output               rx_busy,
    output               rx_done
);
    localparam WIDTH_TICKCNT = $clog2(OSR);
    localparam WIDTH_BITCNT = $clog2(DATALEN);
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] c_state, n_state;
    reg [DATALEN-1:0] c_data, n_data;
    reg c_done, n_done;
    reg c_busy, n_busy;
    reg [WIDTH_TICKCNT-1:0] c_tickcnt, n_tickcnt;
    reg [WIDTH_BITCNT-1:0] c_bitcnt, n_bitcnt;

    assign rx_data = c_data;
    assign rx_done = c_done;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state   <= IDLE;
            c_done    <= 0;
            c_busy <= 0;
            c_data    <= 0;
            c_tickcnt <= 0;
            c_bitcnt  <= 0;
        end else begin
            c_state   <= n_state;
            c_done    <= n_done;
            c_busy <= n_busy;
            c_data    <= n_data;
            c_tickcnt <= n_tickcnt;
            c_bitcnt  <= n_bitcnt;
        end
    end

    always @(*) begin
        n_state   = c_state;
        n_done    = c_done;
        n_busy = c_busy;
        n_data    = c_data;
        n_tickcnt = c_tickcnt;
        n_bitcnt  = c_bitcnt;
        case (c_state)
            IDLE: begin
                n_state = (rx == 0) ? START : IDLE;
                n_done  = 0;
                n_busy  = 0;
            end
            START: begin
                n_busy = 1;
                if (btick) begin
                    if (c_tickcnt == OSR / 2 - 1) begin
                        n_tickcnt = 0;
                        n_state   = DATA;
                    end else begin
                        n_tickcnt = c_tickcnt + 1;
                    end
                end
            end
            DATA: begin
                if (btick) begin
                    if (c_tickcnt == OSR - 1) begin
                        n_tickcnt = 0;
                        n_data = {rx, c_data[7:1]};
                        if (c_bitcnt == DATALEN - 1) begin
                            n_bitcnt = 0;
                            n_state  = STOP;
                        end else begin
                            n_bitcnt = c_bitcnt + 1;
                        end
                    end else begin
                        n_tickcnt = c_tickcnt + 1;
                    end
                end
            end
            STOP: begin
                if (btick) begin
                    if (c_tickcnt == OSR - 1) begin
                        n_tickcnt = 0;
                        n_state = IDLE;
                        n_done = 1;
                        n_busy = 0;
                    end else begin
                        n_tickcnt = c_tickcnt + 1;
                    end
                end
            end
        endcase

    end
endmodule
