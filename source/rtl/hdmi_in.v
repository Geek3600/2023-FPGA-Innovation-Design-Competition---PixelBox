module hdmi_in # (
    parameter H_ACT = 12'd640,
    parameter V_ACT = 12'd720
)
(
    input pixclk_in,
    input init_over_tx, // д��ʼ������
    input vs_in,
    input hs_in,
    input de_in /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    input [7:0] r_in,
    input [7:0] g_in,
    input [7:0] b_in,
    input scaler_ctrl, 

    output reg vs_out/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    output reg hs_out/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    output reg de_out /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    // output reg de_out,
    output reg [23:0] data_out /*synthesis PAP_MARK_DEBUG="1"*/
    // output reg [23:0] data_out
);

    reg [23:0] i_data_scaler;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [23:0] o_data_scaler; /*synthesis PAP_MARK_DEBUG="1"*/ // �ݴ�����
    reg [11:0] h_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [11:0] v_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [8:0] scaler_v_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [8:0] scaler_h_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    reg vs_in_1d;/*synthesis PAP_MARK_DEBUG="1"*/
    reg de_in_1d;/*synthesis PAP_MARK_DEBUG="1"*/
    reg o_vs_scaler_1d;/*synthesis PAP_MARK_DEBUG="1"*/
    reg o_de_scaler_1d; /*synthesis PAP_MARK_DEBUG="1"*/
    reg  i_de_scaler; /*synthesis PAP_MARK_DEBUG="1"*/ // ��������ģ���de
    wire o_de_scaler; /*synthesis PAP_MARK_DEBUG="1"*/ // ����ģ�������de
    wire o_hs_scaler; /*synthesis PAP_MARK_DEBUG="1"*/ // ����ģ�������de
    wire o_vs_scaler; /*synthesis PAP_MARK_DEBUG="1"*/ // ����ģ�������de
    wire rst_scaler; /*synthesis PAP_MARK_DEBUG="1"*/ //
    reg scaler_ctrl_1d, scaler_ctrl_2d;

    always @(posedge pixclk_in) begin
        scaler_ctrl_1d <= scaler_ctrl;
        scaler_ctrl_2d <= scaler_ctrl_1d;
    end

    always  @(posedge pixclk_in) begin
        if(!init_over_tx)begin
            vs_out  <=  1'b0        ;
            de_out <=  1'b0        ;

            hs_out  <=  1'b0        ;

            i_de_scaler   <=  1'b0        ;
            i_data_scaler <=  24'b0        ;
            // data_out      <=  24'b0        ;
        end
    	else begin
            vs_out        <=  vs_in || (~scaler_ctrl_2d ? (v_cnt > V_ACT) : 1'b0);
            de_out <=  scaler_ctrl_2d ? (o_de_scaler || ((h_cnt < H_ACT) && (v_cnt > V_ACT-1'b1) && de_in)) : (de_in && (h_cnt < H_ACT) && (v_cnt < V_ACT));
            // vs_out        <=  vs_in || (v_cnt > V_ACT);
            hs_out        <=  hs_in;

            i_de_scaler <=  de_in && (h_cnt < H_ACT + 2) && (v_cnt < V_ACT) ;
            i_data_scaler          <=  {r_in, g_in, b_in}; 
            // data_out          <=  {r_in, g_in, b_in}         ; 
        end
    end

    always @(posedge pixclk_in) begin
        if (!init_over_tx) begin
            data_out <= 0;
        end
        else begin
            // data_out <= o_data_scaler;
            if (~scaler_ctrl_2d)
                data_out <= {r_in, g_in, b_in};
            else if (o_de_scaler)
                // data_out <= 24'b111111111111111111111111;
                data_out <= o_data_scaler;
            else 
                data_out <= 0;
        end
    end
    
    //������м���h
    always @(posedge pixclk_in) begin
        if (!de_in)
            h_cnt <= 12'd0;
        else
            h_cnt <= h_cnt + 1'b1;
    end

    // �����м���
    always @(posedge pixclk_in) begin
        if(!init_over_tx)begin
            v_cnt <= 12'd0;
        end
        else begin
            if (~vs_in_1d & vs_in) // ���vs�������أ�˵����һ֡���ˣ�vs_cnt�м�������
                v_cnt <= 12'd0;
            else if (de_in_1d & ~de_in) // ���de�����أ�˵����һ�����ˣ�vs_cnt�м���+1
                v_cnt <= v_cnt + 1'b1;
        end
    end

    always @(posedge pixclk_in) begin
        vs_in_1d <= vs_in;
        de_in_1d <= de_in;
    end
    
    //��������ģ���de�ź�
    // always @(posedge pixclk_in) begin
    //     if (!init_over_tx) begin
    //         de_out <= 1'b0;
    //     end
    //     else begin   
    //         de_out <=  o_de_scaler;
    //     end
    // end

    always @(posedge pixclk_in) begin
        o_vs_scaler_1d <= o_vs_scaler;
        o_de_scaler_1d <= o_de_scaler;
    end

    assign rst_scaler = vs_in & ~vs_in_1d;

    //������ģ�������ͼ������м���
    always @(posedge pixclk_in) begin
        if (!init_over_tx) begin
            scaler_v_cnt <= 0;
        end
        else begin
          
            if ((o_de_scaler_1d & ~o_de_scaler)) begin // �������ģ�������de�źŵ��½��أ�˵��һ�н���
                scaler_v_cnt <= scaler_v_cnt + 1;
            end
            else if (~o_vs_scaler_1d & o_vs_scaler) begin// ���vs�������أ�˵����һ֡���ˣ�vs_cnt�м�������
                scaler_v_cnt <= 12'd0;
            end
        end
    end

    // always @(posedge pixclk_in) begin
    //     if (!init_over_tx) begin
    //         vs_out  <=  1'b0 ;
    //     end
    //     else begin
    //         vs_out <= o_vs_scaler ;
    //     end
    // end

    // always @(posedge pixclk_in) begin
    //     if(!init_over_tx) begin
    //         vs_out  <=  1'b0;
    //     end
    //     else begin
    //         // vs_out  <=  o_vs_scaler || (scaler_v_cnt == V_ACT);
    //         vs_out  <=  o_vs_scaler || (scaler_v_cnt == 361);
    //     end
    // end

    image_scaler #(
        .PIXEL_DATA_WIDTH(24),      //RGB 888
        .SRC_IMAGE_RES_WIDTH(640),  // ԭͼ��
        .SRC_IMAGE_RES_HEIGHT(720), // ԭͼ��

        .DST_IMAGE_RES_WIDTH(320),  // Ŀ��ͼ��
        .DST_IMAGE_RES_HEIGHT(360)  // Ŀ��ͼ��

    ) u_image_scaler(
        .pixclk_in(pixclk_in),
        .rst_n(~rst_scaler), 

        .de_in(i_de_scaler),  //i_de_scaler �ź���Ч���µ�һ�п�ʼ��de��Ч��һ�д������
        .de_out(o_de_scaler), // ����ģ�������de�ź�
        .i_pixel(i_data_scaler),
        .o_pixel(o_data_scaler),
        .vs_out(o_vs_scaler)
    );

endmodule