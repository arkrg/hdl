module updn_counter_top #(
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter WIDTH_COUNTER = $clog2(MAX_COUNT),
    parameter DIV_1KHz = 100_000  // for fnd scanning
) (
    input        clk,
    input        rst,
    input        ud_btn,
    input        clr_btn,
    input        rnstp_btn,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);

    wire updn_debounce;
    //assign updn_debounce = ud_btn;
    wire rnstp_debounce;
    // assign rnstp_debounce = rnstp_btn;
    wire clr_debounce;
    // assign clr_debounce = clr_btn;

    wire [WIDTH_COUNTER-1:0] count;
    btn_debouncer u_btn_debouncer[2:0] (
        .clk(clk),
        .rst(rst),
        .d({ud_btn, clr_btn, rnstp_btn}),
        .edge_d({updn_debounce, clr_debounce, rnstp_debounce})
    );
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

module updn_counter_datapath #(
    parameter DIV = 10_000_000,
    parameter MAX_COUNT = 10_000,
    parameter WIDTH_COUNTER = $clog2(MAX_COUNT)
) (
    input                      clk,
    input                      rst,
    input                      ud,
    input                      clr,
    input                      en,
    output [WIDTH_COUNTER-1:0] count
);
    reg [3:0] _fnd_com;
    wire tick;

    tick_generator_wctrl #(
        .DIV(DIV)
    ) u_tick_generator (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .clr (clr),
        .tick(tick)
    );

    updn_counter #(
        .MAX_COUNT(MAX_COUNT)
    ) u_counter (
        .rst(rst),
        .clk(clk),
        .tick(tick),
        .ud(ud),
        .clr(clr),
        .count(count)
    );

endmodule

module updn_counter #(
    parameter MAX_COUNT = 10_000,
    parameter WIDTH = $clog2(MAX_COUNT)
) (
    input              rst,
    input              clk,
    input              tick,
    input              ud,
    input              clr,
    output [WIDTH-1:0] count
);
    reg [WIDTH-1:0] r_count;

    always @(posedge clk or posedge rst or posedge clr) begin
        if (rst | clr) begin
            r_count <= 0;
        end else begin
            if (tick) begin
                if (ud == 1) begin  // up
                    if (r_count < MAX_COUNT - 1) begin
                        r_count <= r_count + 1;
                    end else r_count <= 0;
                end else begin  // dn 
                    if (r_count > 0) begin
                        r_count <= r_count - 1;
                    end else r_count <= MAX_COUNT - 1;

                end
            end
        end
    end
    assign count = r_count;
endmodule

module tick_generator_wctrl #(
    parameter DIV = 10_000_000,
    parameter WIDTH_COUNTER = $clog2(DIV)
) (
    input  rst,
    input  clk,
    input  clr,
    input  en,
    output tick
);
    reg [WIDTH_COUNTER-1:0] r_count;

    always @(posedge clk or posedge rst or posedge clr) begin
        if (rst | clr) begin
            r_count <= 0;
        end else begin
            if (en) begin
                if (r_count > DIV - 1) r_count <= 0;
                else r_count <= r_count + 1;
            end
        end
    end

    assign tick = (r_count == DIV - 1);
endmodule

module updn_counter_controller (
    input clk,
    input rst,
    input rnstp,
    input clr,
    input ud,

    output ctrl_en,
    output ctrl_ud,
    output ctrl_clr
);
    parameter [1:0] RUN = 0, STOP = 1, CLEAR = 2;
    parameter UP = 0, DN = 1;

    reg [1:0] c_rs_state, n_rs_state;
    reg c_ud_state, n_ud_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_rs_state <= RUN;
            c_ud_state <= UP;
        end else begin
            c_rs_state <= n_rs_state;
            c_ud_state <= n_ud_state;

        end
    end
    always @(*) begin
        case (c_ud_state)
            UP: n_ud_state = (ud) ? DN : UP;
            DN: n_ud_state = (ud) ? UP : DN;
            default: n_ud_state = UP;
        endcase
    end
    always @(*) begin
        case (c_rs_state)
            RUN: n_rs_state = (rnstp) ? STOP : RUN;
            STOP: n_rs_state = (rnstp) ? RUN : (clr) ? CLEAR : STOP;
            CLEAR: n_rs_state = STOP;
            default: n_rs_state = STOP;
        endcase
    end

    assign ctrl_en  = (c_rs_state == RUN);
    assign ctrl_clr = (c_rs_state == CLEAR);
    assign ctrl_ud  = (c_ud_state == UP);

endmodule

module btn_debouncer (
    input  clk,
    input  rst,
    input  d,
    output edge_d
);

    reg [3:0] q;
    reg d_q;
    wire and_q;
    always @(posedge clk or posedge rst) begin
        if (rst) q <= 0;
        else q <= {q[2:0], d};
    end

    assign and_q = &q;

    always @(posedge clk or posedge rst) begin
        if (rst) d_q <= 0;
        else d_q <= and_q;
    end
    assign edge_d = d_q & and_q;


endmodule
