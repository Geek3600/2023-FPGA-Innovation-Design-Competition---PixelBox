`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 15/03/23 14:17:29
// Design Name: 
// Module Name: fram_buf
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
module fram_buf #(
    parameter                     MEM_ROW_WIDTH        = 15    ,
    parameter                     MEM_COLUMN_WIDTH     = 10    ,
    parameter                     MEM_BANK_WIDTH       = 3     ,
    parameter                     CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH,
    parameter                     MEM_DQ_WIDTH         = 32    ,
    parameter                     H_NUM                = 12'd640,//12'd1920,
    parameter                     V_NUM                = 12'd720,//12'd1080,//12'd106,//
    parameter                     PIX_WIDTH            = 16
)(
    input                         vin_clk1,
    input                         wr_fsync1,
    input                         wr_en1,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data1,
    input                         vin_clk2,
    input                         wr_fsync2,
    input                         wr_en2,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data2,
    input                         vin_clk3,
    input                         wr_fsync3,
    input                         wr_en3,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data3,
    output reg                    init_done=0,
    
    input                         ddr_clk,
    input                         ddr_rstn,
    
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en,
    output                        vout_de,
    output [PIX_WIDTH- 1'b1 : 0]  vout_data,
    
    output [CTRL_ADDR_WIDTH-1:0]  axi_awaddr     ,
    output [3:0]                  axi_awid       ,
    output [3:0]                  axi_awlen      ,
    output [2:0]                  axi_awsize     ,
    output [1:0]                  axi_awburst    ,
    input                         axi_awready    ,
    output                        axi_awvalid    ,
                                                  
    output [MEM_DQ_WIDTH*8-1:0]   axi_wdata      ,
    output [MEM_DQ_WIDTH -1 :0]   axi_wstrb      ,
    input                         axi_wlast      ,
    output                        axi_wvalid     ,
    input                         axi_wready     ,
    input  [3 : 0]                axi_bid        ,                                      
                                                  
    output [CTRL_ADDR_WIDTH-1:0]  axi_araddr     ,
    output [3:0]                  axi_arid       ,
    output [3:0]                  axi_arlen      ,
    output [2:0]                  axi_arsize     ,
    output [1:0]                  axi_arburst    ,
    output                        axi_arvalid    ,
    input                         axi_arready    ,
                                                  
    output                        axi_rready     ,
    input  [MEM_DQ_WIDTH*8-1:0]   axi_rdata      ,
    input                         axi_rvalid     ,
    input                         axi_rlast      ,
    input  [3:0]                  axi_rid        ,
    input  [3:0]                  num            ,
    input                         num_vld        ,
    input  [1:0]                  rotate_ctrl
);
    parameter LEN_WIDTH       = 32;
    parameter LINE_ADDR_WIDTH = 22;//19;//1440 * 1080 = 1 555 200 = 21'h17BB00
    parameter FRAME_CNT_WIDTH = CTRL_ADDR_WIDTH - LINE_ADDR_WIDTH;
      
    wire [CTRL_ADDR_WIDTH- 1'b1 : 0] ddr_waddr;    
    wire [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len;   
    wire                        ddr_wrdy;     
    wire                        ddr_wdone;    
    wire [8*MEM_DQ_WIDTH-1 : 0] ddr_wdata;    
    wire                        ddr_wdata_req1;
    wire                        ddr_wdata_req2;
    wire                        ddr_wdata_req3;
    wire                        ddr_wdata_req4;
    
    wire                        rd_cmd_en   ;
    wire [CTRL_ADDR_WIDTH-1:0]  rd_cmd_addr ;
    wire [LEN_WIDTH- 1'b1: 0]   rd_cmd_len  ;
    wire                        rd_cmd_ready;
    wire                        rd_cmd_done;
                                
    wire                        read_ready  = 1'b1;
    wire [MEM_DQ_WIDTH*8-1:0]   read_rdata  ;
    wire                        read_en1     ;
    wire                        read_en2     ;
    wire                        read_en3     ;
    wire                        read_en4     ;
    wire                        ddr_wr_bac;
    wire                        wr_opera_en_1;
    wire                        wr_opera_en_2;
    wire                        wr_opera_en_3;
    wire                        rd_opera_en_1;
    wire                        rd_opera_en_2;
    wire                        rd_opera_en_3;
    wire                        ddr_wreq_en_1;
    wire                        ddr_wreq_en_2;
    wire                        ddr_wreq_en_3;
    wire                        ddr_wreq_en_4;
    wire                        ddr_wreq_rst1;
    wire                        ddr_wreq_rst2;
    wire                        ddr_wreq_rst3;
    wire                        ddr_wreq4;
    wire [CTRL_ADDR_WIDTH- 1'b1 : 0] ddr_waddr4;    
    wire [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len4;   
    // wire                        read_rdata_ban4;
    wire [CTRL_ADDR_WIDTH-1'b1:0] ddr_raddr4;
    wire [LEN_WIDTH-1'b1:0]     ddr_rd_len4;
    wire [8*MEM_DQ_WIDTH-1 : 0] ddr_wdata4; 
    wire                        read_rdata_ban2;  
    wire                        frame_wcnt1; 
    wire                        frame_wcnt2; 
    wire                        frame_wcnt3; 
    wire                        frame_wcnt4; 

    wr_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd28,
        .ADDR_OFFSET      (  32'd0            ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd22,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) wr_buf (                                       
        .ddr_clk          (  ddr_clk          ),//input                         ddr_clk,
        .ddr_rstn         (  ddr_rstn         ),//input                         ddr_rstn,
                                              
        .wr_clk1           (  vin_clk1          ),//input                         wr_clk,
        .wr_fsync1         (  wr_fsync1         ),//input                         wr_fsync,
        .wr_en1            (  wr_en1            ),//input                         wr_en,
        .wr_data1          (  wr_data1          ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
        .wr_clk2           (  vin_clk2          ),//input                         wr_clk,
        .wr_fsync2         (  wr_fsync2         ),//input                         wr_fsync,
        .wr_en2            (  wr_en2            ),//input                         wr_en,
        .wr_data2          (  wr_data2          ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
        .wr_clk3           (  vin_clk3          ),//input                         wr_clk,
        .wr_fsync3         (  wr_fsync3         ),//input                         wr_fsync,
        .wr_en3            (  wr_en3            ),//input                         wr_en,
        .wr_data3          (  wr_data3          ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
            
        .rd_bac           (  ddr_wr_bac       ),//input                         rd_bac,                                      
        .ddr_wreq         (  ddr_wreq         ),//output                        ddr_wreq,
        .ddr_waddr        (  ddr_waddr        ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
        .ddr_wr_len       (  ddr_wr_len       ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
        .ddr_wrdy         (  ddr_wrdy         ),//input                         ddr_wrdy,
        .ddr_wdone        (  ddr_wdone        ),//input                         ddr_wdone,
        .ddr_wdata        (  ddr_wdata        ),//output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
        .ddr_wdata_req1    (  ddr_wdata_req1    ),//input                         ddr_wdata_req,
        .ddr_wdata_req2    (  ddr_wdata_req2    ),//input                         ddr_wdata_req,
        .ddr_wdata_req3    (  ddr_wdata_req3    ),//input                         ddr_wdata_req,
        .ddr_wreq_rst1     (ddr_wreq_rst1),
        .ddr_wreq_rst2     (ddr_wreq_rst2),
        .ddr_wreq_rst3     (ddr_wreq_rst3),

        // .frame_wcnt       (                   ),//output [FRAME_CNT_WIDTH-1 :0] frame_wcnt,
        .frame_wirq       (  frame_wirq       ), //output                        frame_wirq
        .frame_wcnt1      (  frame_wcnt1       ), //output
        .frame_wcnt2      (  frame_wcnt2       ), //output
        .frame_wcnt3      (  frame_wcnt3       ), //output
        .wr_opera_en_1    (wr_opera_en_1      ),      //input                         wr_opera_en_2
        .wr_opera_en_2    (wr_opera_en_2      ),      //input                         wr_opera_en_2
        .wr_opera_en_3    (wr_opera_en_3      ),      //input                         wr_opera_en_2
        .ddr_wreq_en_1    (ddr_wreq_en_1      ),    //output
        .ddr_wreq_en_2    (ddr_wreq_en_2      ),     //output
        .ddr_wreq_en_3    (ddr_wreq_en_3      ),     //output
        .ddr_wreq_en_4    (ddr_wreq_en_4      ),     //output
        .ddr_wreq4        (ddr_wreq4          ),     //input
        .ddr_waddr4       (ddr_waddr4         ),     //input
        .ddr_wr_len4      (ddr_wr_len4        ),     //input 
        .ddr_wdata4       (ddr_wdata4         )      //input      
    );
    
    always @(posedge ddr_clk)
    begin
        if(frame_wirq)
            init_done <= 1'b1;
        else
            init_done <= init_done;
    end 
    
    rd_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd28,
        .ADDR_OFFSET      (  32'h0000_0000    ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd22,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) rd_buf (
        .ddr_clk         (  ddr_clk           ),//input                         ddr_clk,
        .ddr_rstn        (  ddr_rstn          ),//input                         ddr_rstn,

        .vout_clk        (  vout_clk          ),//input                         vout_clk,
        .rd_fsync        (  rd_fsync          ),//input                         rd_fsync,
        .rd_en           (  rd_en             ),//input                         rd_en,
        .vout_de         (  vout_de           ),//output                        vout_de,
        .vout_data       (  vout_data         ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,
        
        .init_done       (  init_done         ),//input                         init_done,
      
        .ddr_rreq        (  rd_cmd_en         ),//output                        ddr_rreq,
        .ddr_raddr       (  rd_cmd_addr       ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len      (  rd_cmd_len        ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        .ddr_rrdy        (  rd_cmd_ready      ),//input                         ddr_rrdy,
        .ddr_rdone       (  rd_cmd_done       ),//input                         ddr_rdone,
                                              
        .ddr_rdata       (  read_rdata        ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en1   (  read_en1           ), //input                         ddr_rdata_en,
        .ddr_rdata_en2   (  read_en2           ), //input                         ddr_rdata_en,
        .ddr_rdata_en3   (  read_en3           ), //input                         ddr_rdata_en,
        .rd_opera_en_1   (rd_opera_en_1),//input                         rd_opera_en_2,
        .rd_opera_en_2   (rd_opera_en_2),//input                         rd_opera_en_2,
        .rd_opera_en_3   (rd_opera_en_3),//input                         rd_opera_en_2,
        .num             (num          ),//input [3 : 0]                 num 
        .num_vld         (num_vld          ),//input 
        .rotate_90       (rotate_ctrl == 2'd1),
        .rotate_180      (rotate_ctrl == 2'd2),
        .ddr_raddr4      (ddr_raddr4 ), 
        .ddr_rd_len4     (ddr_rd_len4),
        .ddr_rdata_ban   (read_rdata_ban2),
        .frame_wcnt1     (frame_wcnt1 ),
        .frame_wcnt2     (frame_wcnt2 ),
        .frame_wcnt3     (frame_wcnt3 ),
        .frame_wcnt4     (frame_wcnt4 )
    );
    
    wr_rd_ctrl_top#(
        .CTRL_ADDR_WIDTH  (  CTRL_ADDR_WIDTH  ),//parameter                    CTRL_ADDR_WIDTH      = 28,
        .MEM_DQ_WIDTH     (  MEM_DQ_WIDTH     ) //parameter                    MEM_DQ_WIDTH         = 16
    )wr_rd_ctrl_top (                         
        .clk              (  ddr_clk          ),//input                        clk            ,            
        .rstn             (  ddr_rstn         ),//input                        rstn           ,            
                                              
        .wr_cmd_en        (  ddr_wreq         ),//input                        wr_cmd_en   ,
        .wr_cmd_addr      (  ddr_waddr        ),//input  [CTRL_ADDR_WIDTH-1:0] wr_cmd_addr ,
        .wr_cmd_len       (  ddr_wr_len       ),//input  [31��0]               wr_cmd_len  ,
        .wr_cmd_ready     (  ddr_wrdy         ),//output                       wr_cmd_ready,
        .wr_cmd_done      (  ddr_wdone        ),//output                       wr_cmd_done,
        .wr_bac           (  ddr_wr_bac       ),//output                       wr_bac,                                     
        .wr_ctrl_data     (  ddr_wdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  wr_ctrl_data,
        .wr_data_re1       (  ddr_wdata_req1    ),//output                       wr_data_re  ,
        .wr_data_re2       (  ddr_wdata_req2    ),//output                       wr_data_re  ,
        .wr_data_re3       (  ddr_wdata_req3    ),//output                       wr_data_re  ,
        .wr_data_re4       (  ddr_wdata_req4    ),//output                       wr_data_re  ,
                                              
        .rd_cmd_en        (  rd_cmd_en        ),//input                        rd_cmd_en   ,
        .rd_cmd_addr      (  rd_cmd_addr      ),//input  [CTRL_ADDR_WIDTH-1:0] rd_cmd_addr ,
        .rd_cmd_len       (  rd_cmd_len       ),//input  [31��0]               rd_cmd_len  ,
        .rd_cmd_ready     (  rd_cmd_ready     ),//output                       rd_cmd_ready, 
        .rd_cmd_done      (  rd_cmd_done      ),//output                       rd_cmd_done,
                                              
        .read_ready       (  read_ready       ),//input                        read_ready  ,    
        .read_rdata       (  read_rdata       ),//output [MEM_DQ_WIDTH*8-1:0]  read_rdata  ,    
        .read_en1          (  read_en1          ),//output                       read_en     ,                                          
        .read_en2          (  read_en2          ),//output                       read_en     ,                                          
        .read_en3          (  read_en3          ),//output                       read_en     ,                                          
        .read_en4          (  read_en4          ),//output                       read_en     ,                                          
        .read_line         (  ddr_line          ),//input                                read_line   ,
        .read_rdata_ban2    (  read_rdata_ban2     ),//input
        // .read_rdata_ban4    (  read_rdata_ban4    ),//input
        // write channel                        
        .axi_awaddr       (  axi_awaddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_awaddr     ,  
        .axi_awid         (  axi_awid         ),//output [3:0]                 axi_awid       ,
        .axi_awlen        (  axi_awlen        ),//output [3:0]                 axi_awlen      ,
        .axi_awsize       (  axi_awsize       ),//output [2:0]                 axi_awsize     ,
        .axi_awburst      (  axi_awburst      ),//output [1:0]                 axi_awburst    , //only support 2'b01: INCR
        .axi_awready      (  axi_awready      ),//input                        axi_awready    ,
        .axi_awvalid      (  axi_awvalid      ),//output                       axi_awvalid    ,
                                              
        .axi_wdata        (  axi_wdata        ),//output [MEM_DQ_WIDTH*8-1:0]  axi_wdata      ,
        .axi_wstrb        (  axi_wstrb        ),//output [MEM_DQ_WIDTH -1 :0]  axi_wstrb      ,
        .axi_wlast        (  axi_wlast        ),//output                       axi_wlast      ,
        .axi_wvalid       (  axi_wvalid       ),//output                       axi_wvalid     ,
        .axi_wready       (  axi_wready       ),//input                        axi_wready     ,
        .axi_bid          (  4'd0             ),//input  [3 : 0]               axi_bid        , // Master Interface Write Response.
        .axi_bresp        (  2'd0             ),//input  [1 : 0]               axi_bresp      , // Write response. This signal indicates the status of the write transaction.
        .axi_bvalid       (  1'b0             ),//input                        axi_bvalid     , // Write response valid. This signal indicates that the channel is signaling a valid write response.
        .axi_bready       (                   ),//output                       axi_bready     ,
                                              
        // read channel                          
        .axi_araddr       (  axi_araddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_araddr     ,    
        .axi_arid         (  axi_arid         ),//output [3:0]                 axi_arid       ,
        .axi_arlen        (  axi_arlen        ),//output [3:0]                 axi_arlen      ,
        .axi_arsize       (  axi_arsize       ),//output [2:0]                 axi_arsize     ,
        .axi_arburst      (  axi_arburst      ),//output [1:0]                 axi_arburst    ,
        .axi_arvalid      (  axi_arvalid      ),//output                       axi_arvalid    , 
        .axi_arready      (  axi_arready      ),//input                        axi_arready    , //only support 2'b01: INCR
                                              
        .axi_rready       (  axi_rready       ),//output                       axi_rready     ,
        .axi_rdata        (  axi_rdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  axi_rdata      ,
        .axi_rvalid       (  axi_rvalid       ),//input                        axi_rvalid     ,
        .axi_rlast        (  axi_rlast        ),//input                        axi_rlast      ,
        .axi_rid          (  axi_rid          ),//input  [3:0]                 axi_rid        ,
        .axi_rresp        (  2'd0             ), //input  [1:0]                 axi_rresp  
        .wr_opera_en_1    (wr_opera_en_1)      ,
        .wr_opera_en_2    (wr_opera_en_2)      ,
        .wr_opera_en_3    (wr_opera_en_3)      ,
        .rd_opera_en_1    (rd_opera_en_1)      ,
        .rd_opera_en_2    (rd_opera_en_2)      ,
        .rd_opera_en_3    (rd_opera_en_3)      ,
        .wr_cmd_en_1       (ddr_wreq_en_1),
        .wr_cmd_en_2       (ddr_wreq_en_2),
        .wr_cmd_en_3       (ddr_wreq_en_3),
        .wr_cmd_en_4       (ddr_wreq_en_4),
        .wr_rst_1 (ddr_wreq_rst1),
        .wr_rst_2 (ddr_wreq_rst2),
        .wr_rst_3 (ddr_wreq_rst3),
        .rotate_90 (rotate_ctrl == 2'd1)
    );

    rotate_buf#(
        .ADDR_WIDTH      (CTRL_ADDR_WIDTH),            
        .ADDR_OFFSET     (32'h0000_0000  ),
        .H_NUM           (H_NUM          ),
        .V_NUM           (V_NUM          ),
        .DQ_WIDTH        (MEM_DQ_WIDTH   ),
        .LEN_WIDTH       (LEN_WIDTH      ),
        .PIX_WIDTH       (PIX_WIDTH      ),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH)
    ) rotate_buf (
        .ddr_clk(ddr_clk),
        .ddr_rstn(ddr_rstn),
        .ddr_raddr(ddr_raddr4), 
        .ddr_rd_len(ddr_rd_len4),
        .ddr_rdone(rd_cmd_done),
        .ddr_rdata(read_rdata),
        .ddr_rdata_en(read_en4),
        .ddr_part_wr(2'd1),
        .ddr_wreq(ddr_wreq4),
        .ddr_waddr(ddr_waddr4),
        .ddr_wr_len(ddr_wr_len4),
        .ddr_wdone(ddr_wdone),
        .ddr_wdata(ddr_wdata4),
        .ddr_wdata_req(ddr_wdata_req4),
        .ddr_part_rd(2'd3),
        .frame_wcnt(frame_wcnt2),
        .frame_wcnt_out(frame_wcnt4)
        // .ddr_rdata_ban(read_rdata_ban4)   
    );
endmodule
