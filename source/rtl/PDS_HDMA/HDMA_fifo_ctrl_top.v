
module HDMA_fifo_ctrl_top #(
	parameter VIDEO_DATA_BIT   = 32		// 输入视频数据位宽,这里选择32,也可以选择16
)(
    input                       rst_n              ,  //复位信号    
    input                       rd_clk             ,  //rfifo时钟
    input                       clk_100            ,  //用户时钟
    //fifo1接口信号
    input                       wr_clk_1           ,  //wfifo时钟    
    input                       datain_valid_1     ,  //数据有效使能信号
    input  [VIDEO_DATA_BIT-1:0] datain_1           ,  //有效数据
    input                       wr_load_1          ,  //输入源场信号    
    input  [127:0]              rfifo_din_1        ,  //用户读数据
    input                       rfifo_wren_1       ,  //从ddr3读出数据的有效使能
    input                       wfifo_rden_1       ,  //wfifo读使能
    output [10:0]               wfifo_rcount_1     ,  //wfifo剩余数据计数
    output [10:0]               rfifo_wcount_1     ,  //rfifo写进数据计数
    input                       wr_opera_en_2,    
    //fifo2接口信号  
    input                       wr_clk_2           ,  //wfifo时钟    
    input                       datain_valid_2     ,  //数据有效使能信号
    input  [VIDEO_DATA_BIT-1:0] datain_2           ,  //有效数据    
    input                       wr_load_2          ,  //输入源场信号
    input  [127:0]              rfifo_din_2        ,  //用户读数据
    input                       rfifo_wren_2       ,  //从ddr3读出数据的有效使能
    input                       wfifo_rden_2       ,  //wfifo读使能    
    output [10:0]               wfifo_rcount_2     ,  //wfifo剩余数据计数
    output [10:0]               rfifo_wcount_2     ,  //rfifo写进数据计数

    input  [12:0]               h_disp             ,
    input                       rd_load            ,  //输出源场信号
    input                       rdata_req          ,  //请求像素点颜色数据输入     
    output [VIDEO_DATA_BIT-1:0] pic_data           ,  //有效数据  
    output [127:0]              wfifo_dout            //用户写数据  
       
    );

//reg define
reg  [12:0]  rd_cnt;
reg          wfifo_rden_1_d0;  

//wire define
wire                      rdata_req_1;
wire                      rdata_req_2;
wire [VIDEO_DATA_BIT-1:0] pic_data_1;
wire [VIDEO_DATA_BIT-1:0] pic_data_2;
wire [VIDEO_DATA_BIT-1:0] pic_data;
wire [127:0]              wfifo_dout;
wire [127:0]              wfifo_dout_1;
wire [127:0]              wfifo_dout_2;
//wire [10:0]               wfifo_rcount_1;
//wire [10:0]               wfifo_rcount_2;
//wire [10:0]               rfifo_wcount_1;
//wire [10:0]               rfifo_wcount_2;

 //*****************************************************
//**                    main code
//***************************************************** 

//像素显示请求信号切换，即显示器左侧请求FIFO0显示，右侧请求FIFO1显示
assign rdata_req_1  = (rd_cnt <= h_disp[12:1]-1) ? rdata_req :1'b0;	//h_disp[12:1]=h_disp/2
assign rdata_req_2  = (rd_cnt <= h_disp[12:1]-1) ? 1'b0 :rdata_req;

//像素在显示器显示位置的切换，即显示器左侧显示FIFO0,右侧显示FIFO1
assign pic_data =     (rd_cnt <= h_disp[12:1]) ? pic_data_1 : pic_data_2;

//写入DDR3的像素数据切换
assign wfifo_dout = ~wr_opera_en_2 ? wfifo_dout_1 : wfifo_dout_2; 

//对读请求信号计数
always @(posedge rd_clk) begin
    if(!rst_n) rd_cnt <= 13'd0;
    else if(rdata_req) rd_cnt <= rd_cnt + 1'b1;
    else rd_cnt <= 13'd0;
end

always @(posedge clk_100) begin
    if(!rst_n) wfifo_rden_1_d0 <= 1'd0;
    else wfifo_rden_1_d0 <= wfifo_rden_1;
end

HDMA_fifo_ctrl #(
	.VIDEO_DATA_BIT(VIDEO_DATA_BIT)		// 输入视频数据位宽,这里选择32,也可以选择16
)u_HDMA_fifo_ctrl_1(
    .rst_n               (rst_n )           ,  
    //摄像头接口
    .wr_clk              (wr_clk_1)         ,
    .rd_clk              (rd_clk)           ,
    .clk_100             (clk_100)          ,    //用户时钟 
    .datain_valid        (datain_valid_1)   ,    //数据有效使能信号
    .datain              (datain_1)         ,    //有效数据 
    .rfifo_din           (rfifo_din_1)      ,    //用户读数据 
    .rdata_req           (rdata_req_1)      ,    //请求像素点颜色数据输入 
    .rfifo_wren          (rfifo_wren_1)     ,    //ddr3读出数据的有效使能 
    .wfifo_rden          (wfifo_rden_1)     ,    //ddr3 写使能         
    //用户接口
    .wfifo_rcount        (wfifo_rcount_1)   ,    //wfifo剩余数据计数                 
    .rfifo_wcount        (rfifo_wcount_1)   ,    //rfifo写进数据计数                
    .wfifo_dout          (wfifo_dout_1)     ,    //用户写数据 
    .rd_load             (rd_load)          ,    //lcd场信号
    .wr_load             (wr_load_1)        ,    //摄像头场信号
    .pic_data            (pic_data_1)            //rfifo输出数据        
    );
    
HDMA_fifo_ctrl #(
	.VIDEO_DATA_BIT(VIDEO_DATA_BIT)		// 输入视频数据位宽,这里选择32,也可以选择16
)u_HDMA_fifo_ctrl_2(
    .rst_n               (rst_n )           ,  
    //摄像头接口                            
    .wr_clk              (wr_clk_2)         ,
    .rd_clk              (rd_clk)           ,
    .clk_100             (clk_100)          ,    //用户时钟 
    .datain_valid        (datain_valid_2)   ,    //数据有效使能信号
    .datain              (datain_2)         ,    //有效数据 
    .rfifo_din           (rfifo_din_2)      ,    //用户读数据 
    .rdata_req           (rdata_req_2)      ,    //请求像素点颜色数据输入 
    .rfifo_wren          (rfifo_wren_2)     ,    //ddr3读出数据的有效使能 
    .wfifo_rden          (wfifo_rden_2)     ,    //ddr3 写使能         
    //用户接口                              
    .wfifo_rcount        (wfifo_rcount_2)   ,    //wfifo剩余数据计数                   
    .rfifo_wcount        (rfifo_wcount_2)   ,    //rfifo写进数据计数                  
    .wfifo_dout          (wfifo_dout_2)     ,    //用户写数据 
    .rd_load             (rd_load)          ,    //lcd场信号
    .wr_load             (wr_load_2)        ,    //摄像头场信号
    .pic_data            (pic_data_2)            //rfifo输出数据        
    );   

endmodule
