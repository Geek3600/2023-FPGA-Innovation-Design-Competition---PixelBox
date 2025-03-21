`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 07/01/23 17:29:04
// Design Name: 
// Module Name: wr_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module wr_ctrl #(
    parameter          CTRL_ADDR_WIDTH      = 28,
    parameter          MEM_DQ_WIDTH         = 16
)(                        
    input                                clk              ,
    input                                rst_n            , 

    input                                wr_en            ,
    input [CTRL_ADDR_WIDTH-1:0]          wr_addr          ,     
    input [3:0]                          wr_id            ,
    input [3:0]                          wr_len           ,
    output                               wr_cmd_done      ,
    output                               wr_ready1         ,
    output                               wr_ready2         ,
    output                               wr_ready3         ,
    output                               wr_ready4         ,
    input                                wr_data_en       ,
    input      [MEM_DQ_WIDTH*8-1:0]      wr_data          ,
    output                               wr_bac           ,
    input                                wr_done          ,
    input                                wr_en1,
    input                                wr_en2,
    input                                wr_en3,
    input                                wr_en4,

    output reg [CTRL_ADDR_WIDTH-1:0]     axi_awaddr       =0,  
    output reg [3:0]                     axi_awid         =0,
    output reg [3:0]                     axi_awlen        =0,
    output     [2:0]                     axi_awsize       ,
    output     [1:0]                     axi_awburst      , //only support 2'b01: INCR
    input                                axi_awready      ,
    output reg                           axi_awvalid      =0,
          
    output     [MEM_DQ_WIDTH*8-1:0]      axi_wdata        ,
    output     [MEM_DQ_WIDTH -1 :0]      axi_wstrb        ,
    input                                axi_wlast        ,
    output                               axi_wvalid       ,
    input                                axi_wready       ,
    input      [3 : 0]                   axi_bid          , // Master Interface Write Response.
    input      [1 : 0]                   axi_bresp        , // Write response. This signal indicates the status of the write transaction.
    input                                axi_bvalid       , // Write response valid. This signal indicates that the channel is signaling a valid write response.
    output reg                           axi_bready       =1, // Response ready. This signal indicates that the master can accept a write response.
    output reg [4:0]                     test_wr_state    =0,
    output reg [1:0]                     wr_port,
    input                                wr_rst_1,
    input                                wr_rst_2,
    input                                wr_rst_3
);

    localparam DQ_NUM = MEM_DQ_WIDTH/8;
    
    localparam E_IDLE =  5'b00001;
    localparam E_WR1   = 5'b00010;
    localparam E_WR2   = 5'b00100;
    localparam E_WR3   = 5'b01000;
    localparam E_WR4   = 5'b10000;

    assign axi_awburst = 2'b01;
    assign axi_awsize  = 3'b110;

    assign axi_wstrb = {MEM_DQ_WIDTH{1'b1}};

    always @(posedge clk ) begin
        if (!rst_n) begin
            wr_port <= 2'd0;
        end
        // else if (wr_en && (test_wr_state == E_IDLE))
        else if (wr_done)
        begin
            if (wr_en4)
                wr_port <= 2'd3;
            else if (wr_en1)
                wr_port <= 2'd0;
            else if (wr_en2)
                wr_port <= 2'd1;
            else if (wr_en3)
                wr_port <= 2'd2;
            else if (wr_port == 2'd3)
                wr_port <= 2'd2;
            else
                wr_port <= wr_port;
        end
        else if ((test_wr_state == E_IDLE) && !wr_en) begin
            if (wr_en4)
                wr_port <= 2'd3;
            else if (wr_rst_1 && (wr_port == 2'd0))
                wr_port <= wr_en3 ? 2'd2 : 2'd1;
            else if (wr_rst_2 && (wr_port == 2'd1))
                wr_port <= wr_en1 ? 2'd0 : 2'd2;
            else if (wr_rst_3 && (wr_port == 2'd2))
                wr_port <= wr_en2 ? 2'd1 : 2'd0;
        end
        // else if (wr_port == 2'd3)
        //     wr_port <= 2'd0;
    end

    always @(posedge clk ) begin
        if (!rst_n) begin
            test_wr_state <= E_IDLE;
        end
        else begin
            case (test_wr_state)
                E_IDLE: begin
                    if (wr_en)
                    begin
                        if (wr_port == 2'd1) begin
                            test_wr_state <= E_WR2;
                        end
                        else if (wr_port == 2'd0) begin
                            test_wr_state <= E_WR1;
                        end
                        else if (wr_port == 2'd2) begin
                            test_wr_state <= E_WR3; 
                        end
                        else if (wr_port == 2'd3) begin
                            test_wr_state <= E_WR4; 
                        end
                    end
                end 
                E_WR1: begin
                    if (axi_wlast)
                        test_wr_state <= E_IDLE;
                end
                E_WR2: begin
                    if (axi_wlast)
                        test_wr_state <= E_IDLE;
                end
                E_WR3: begin
                    if (axi_wlast)
                        test_wr_state <= E_IDLE;
                end
                E_WR4: begin
                    if (axi_wlast)
                        test_wr_state <= E_IDLE;
                end
                default: test_wr_state <= E_IDLE;
            endcase
        end
    end

    wire        wr_opera_en_1,  wr_opera_en_2,  wr_opera_en_3, wr_opera_en_4 ;
    //写端口1操作使能
    assign wr_opera_en_1 = (test_wr_state == E_WR1);
    //写端口2操作使能 
    assign wr_opera_en_2 = (test_wr_state == E_WR2);
    //写端口3操作使能 
    assign wr_opera_en_3 = (test_wr_state == E_WR3);
    //写端口4操作使能 
    assign wr_opera_en_4 = (test_wr_state == E_WR4);
    //===========================================================================
    //   write ADDR channels
    //===========================================================================
    reg [3:0] cmd_cnt;
    always @(posedge clk)
    begin
        if (!rst_n) begin
            axi_awaddr  <= 'b0; 
            axi_awid    <= 4'b0; 
            axi_awlen   <= 4'b0; 
            axi_awvalid <= 1'b0; 
        end
        else if(wr_en)
        begin
            axi_awid    <= wr_id;     
            axi_awaddr  <= wr_addr;    
            axi_awlen   <= wr_len;  
            axi_awvalid <= 1'b1; 
        end
        else if(axi_awvalid & axi_awready)
        begin
            axi_awvalid <= 1'b0;
            axi_awid    <= axi_awid;     
            axi_awaddr  <= axi_awaddr;    
            axi_awlen   <= axi_awlen; 
        end
        else
        begin
            axi_awvalid <= axi_awvalid;
            axi_awid    <= axi_awid;     
            axi_awaddr  <= axi_awaddr;    
            axi_awlen   <= axi_awlen; 
        end
    end
    
    //----------------------------
    //Write Response (B) Channel
    //----------------------------
    always @(posedge clk)                                     
    begin                                                                 
        if (rst_n == 0)                                         
            axi_bready <= 1'b0;                                                                                  
        else                                                  
            axi_bready <= 1'b1;                                                                                   
    end 
    
    wire [3:0] trans_len/* synthesis PAP_MARK_DEBUG="true" */;
    wire       burst_finish;

    assign trans_len = wr_len;
 
    always @(posedge clk)
    begin
        if (!rst_n)
            cmd_cnt <= 4'd0;
        else
        begin
            if(axi_awvalid & axi_awready)
                cmd_cnt <= cmd_cnt + 4'd1;
            else if(axi_wlast && axi_wvalid && axi_wready)
                cmd_cnt <= cmd_cnt - 4'd1;
            else
                cmd_cnt <= cmd_cnt;
        end 
    end 
    
    reg  write_en;
    reg [3:0] axi_data_cnt; 
    always @(posedge clk)
    begin
        if (!rst_n)
            write_en <= 1'b0;
        else if(axi_awvalid & axi_awready & cmd_cnt == 4'd0)
            write_en <= 1'b1;

        else if(axi_wvalid && axi_data_cnt == trans_len && axi_wready)
            write_en <= 1'b0;
    end 
    
    assign wr_ready1 = axi_wready & wr_opera_en_1;
    assign wr_ready2 = axi_wready & wr_opera_en_2;
    assign wr_ready3 = axi_wready & wr_opera_en_3;
    assign wr_ready4 = axi_wready & wr_opera_en_4;
    
    always @(posedge clk)
    begin
        if (!rst_n)
            axi_data_cnt <= 4'd0;
        else if(cmd_cnt > 4'd1 && ~write_en)
            axi_data_cnt <= 4'd0;
        else
        begin
            if(axi_wready & axi_wvalid)
            begin
                if(axi_data_cnt == trans_len)
                    axi_data_cnt <= 4'd0;
                else
                    axi_data_cnt <= axi_data_cnt + 1'b1;
            end
            else
                axi_data_cnt <= axi_data_cnt;
        end 
    end 
    
    reg axi_wready_1d;
    assign burst_finish = ~axi_wready_1d && axi_wready;

    always @(posedge clk)
    begin
        axi_wready_1d <= axi_wready;
    end
     
    assign wr_cmd_done = axi_wlast;
    assign axi_wdata = wr_data ;
    assign axi_wvalid = axi_wready;
    assign wr_bac = axi_wvalid && (~axi_wready && axi_wready_1d);

endmodule
