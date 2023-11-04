`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 15/03/23 15:02:21
// Design Name: 
// Module Name: rd_buf
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
module rd_buf #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd24,
    parameter                     LINE_ADDR_WIDTH = 16'd19,
    parameter                     FRAME_CNT_WIDTH = 16'd8
)  (
    input                         ddr_clk,
    input                         ddr_rstn,
    
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en,
    output                        vout_de,
    output [PIX_WIDTH- 1'b1 : 0]  vout_data,
    
    input                         init_done,
    
    output                        ddr_rreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    input                         ddr_rrdy,
    input                         ddr_rdone,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en1, 
    input                         ddr_rdata_en2,
    input                         rd_opera_en_2 
);

    localparam RAM_WIDTH      = 16'd32;
    
    //===========================================================================
    reg [12:0]  rd_cnt;
    wire      rd_en_part1;
    wire      rd_en_part2;
    wire      ddr_rreq1;
    wire      ddr_rreq2;
    wire [RAM_WIDTH-1:0]        rd_data;
    wire [RAM_WIDTH-1:0]        rd_data_1d;
    wire [RAM_WIDTH-1:0]        rd_data1;
    wire [RAM_WIDTH-1:0]        rd_data2;
    wire [RAM_WIDTH-1:0]        rd_data1_1d;
    wire [RAM_WIDTH-1:0]        rd_data2_1d;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_raddr1;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_raddr2;
    wire [LEN_WIDTH- 1'b1 : 0] ddr_rd_len1;
    wire [LEN_WIDTH- 1'b1 : 0] ddr_rd_len2;
    wire [1:0] rd_cnt1;
    wire [1:0] rd_cnt2;
    wire [1:0] rd_cnt_part;
    reg rd_en_1d, rd_en_2d;
    reg [PIX_WIDTH- 1'b1 : 0]  read_data;

    //������ʾ�����ź��л�������ʾ���������buf0��ʾ���Ҳ�����buf1��ʾ
    assign rd_en_part1 = (rd_cnt <= H_NUM - 1) ? rd_en : 1'b0;
    assign rd_en_part2 = (rd_cnt <= H_NUM - 1) ? 1'b0 : rd_en;

    //��������ʾ����ʾλ�õ��л�
    assign rd_data = (rd_cnt <= H_NUM) ? rd_data1 : rd_data2; 
    assign rd_data_1d = (rd_cnt <= H_NUM) ? rd_data1_1d : rd_data2_1d;
    assign rd_cnt_part = (rd_cnt <= H_NUM) ? rd_cnt1 : rd_cnt2;

    always @(posedge vout_clk) begin
        rd_en_1d <= rd_en;
        rd_en_2d <= rd_en_1d;
    end

    generate
        if(PIX_WIDTH == 6'd24)
        begin
            always @(posedge vout_clk)
            begin
                if(rd_en_1d)
                begin
                    if(rd_cnt_part[1:0] == 2'd1)
                        read_data <= rd_data[PIX_WIDTH-1:0];
                    else if(rd_cnt_part[1:0] == 2'd2)
                        read_data <= {rd_data[15:0],rd_data_1d[31:PIX_WIDTH]};
                    else if(rd_cnt_part[1:0] == 2'd3)
                        read_data <= {rd_data[7:0],rd_data_1d[31:16]};
                    else
                        read_data <= rd_data_1d[31:8];
                end 
                else
                    read_data <= 'd0;
            end 
        end
        else if(PIX_WIDTH == 6'd16)
        begin
            always @(posedge vout_clk)
            begin
                if(rd_en_1d)
                begin
                    if(rd_cnt_part[0])
                        read_data <= rd_data[15:0];
                    else
                        read_data <= rd_data_1d[31:16];
                end 
                else
                    read_data <= 'd0;
            end 
        end
        else
        begin            
            always @(posedge vout_clk)
            begin
                read_data <= rd_data;
            end 
        end
    endgenerate

    //�Զ������źż���
    always @(posedge vout_clk) begin
        if(rd_en) rd_cnt <= rd_cnt + 1'b1;
        else rd_cnt <= 13'd0;
    end

    rd_cell #(  
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
        .RAM_WIDTH       (RAM_WIDTH)
    ) rd_cell1 (
        .ddr_clk(ddr_clk)          ,// input                         ddr_clk,
        .ddr_rstn(ddr_rstn)        , // input                         ddr_rstn,         
        .vout_clk(vout_clk)        , // input                         vout_clk,
        .rd_fsync(rd_fsync)        , // input                         rd_fsync,
        .rd_en(rd_en)              ,// input                         rd_en,
        .rd_en_part(rd_en_part1)    ,     // input                         rd_en_part,
        .rd_data(rd_data1)           , // output [RAM_WIDTH-1:0]        rd_data,
        .rd_data_1d(rd_data1_1d)     ,       // output [RAM_WIDTH-1:0]        rd_data_1d,
        // .vout_data(vout_data1)      ,   // output [PIX_WIDTH- 1'b1 : 0]  vout_data,       
        // input                         init_done,     
        .ddr_rreq(ddr_rreq1)        , // output                        ddr_rreq,
        .ddr_raddr(ddr_raddr1)      ,   // output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len(ddr_rd_len1)    ,     // output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        // .ddr_rrdy(ddr_rrdy)        , // input                         ddr_rrdy,
        .ddr_rdone(ddr_rdone)      ,   // input                         ddr_rdone,      
        .ddr_rdata(ddr_rdata)      ,   // input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en(ddr_rdata_en1),         // input                         ddr_rdata_en,
        .ddr_part(1'b0)        , // input                         ddr_part 
        .rd_cnt(rd_cnt1) // output [1:0] rd_cnt    
    );

    rd_cell #(  
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
        .RAM_WIDTH       (RAM_WIDTH)
    ) rd_cell2 (
        .ddr_clk(ddr_clk)          ,// input                         ddr_clk,
        .ddr_rstn(ddr_rstn)        , // input                         ddr_rstn,         
        .vout_clk(vout_clk)        , // input                         vout_clk,
        .rd_fsync(rd_fsync)        , // input                         rd_fsync,
        .rd_en(rd_en)              ,// input                         rd_en,
        .rd_en_part(rd_en_part2)    ,     // input                         rd_en_part,
        .rd_data(rd_data2)           , // output [RAM_WIDTH-1:0]        rd_data,
        .rd_data_1d(rd_data2_1d)     ,       // output [RAM_WIDTH-1:0]        rd_data_1d,
        // .vout_data(vout_data1)      ,   // output [PIX_WIDTH- 1'b1 : 0]  vout_data,       
        // input                         init_done,     
        .ddr_rreq(ddr_rreq2)        , // output                        ddr_rreq,
        .ddr_raddr(ddr_raddr2)      ,   // output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len(ddr_rd_len2)    ,     // output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        // .ddr_rrdy(ddr_rrdy)        , // input                         ddr_rrdy,
        .ddr_rdone(ddr_rdone)      ,   // input                         ddr_rdone,      
        .ddr_rdata(ddr_rdata)      ,   // input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en(ddr_rdata_en2),         // input                         ddr_rdata_en,
        .ddr_part(1'b1)        , // input                         ddr_part 
        .rd_cnt(rd_cnt2) // output [1:0] rd_cnt    
    );

    assign vout_de = rd_en_2d;
    assign vout_data = read_data;
    assign ddr_rreq = ddr_rreq1;
    assign ddr_raddr = ~rd_opera_en_2 ? ddr_raddr1 : ddr_raddr2;
    assign ddr_rd_len = ~rd_opera_en_2 ? ddr_rd_len1 : ddr_rd_len2;

endmodule
