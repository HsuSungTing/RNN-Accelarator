module ADD(FP_A,FP_B,FP_out);
    input  [31:0]FP_A,FP_B;
    output reg[31:0]FP_out;

    wire sign_A,sign_B;
    reg sign_out;
    wire [7:0]exp_A,exp_B;
    reg [7:0]exp_out;
    wire [24:0]frac_A,frac_B;
    reg [24:0]frac_out;//ex:1.01101，但多1 bit檢查是否有overflow

    assign exp_A=FP_A[30:23]; //要-127才是真的指數，11111110代表254，exp就是254-127
    assign exp_B=FP_B[30:23]; //要-127才是真的指數
    assign sign_A=FP_A[31];   assign sign_B=FP_B[31];
    assign frac_A={1'b0,1'b1,FP_A[22:0]};assign frac_B={1'b0,1'b1,FP_B[22:0]};

    reg[7:0] shift_bit;
    
    always @(*) begin
        if(exp_A>=exp_B) shift_bit=exp_A-exp_B;
        else shift_bit=exp_B-exp_A;
    end
    
    reg [24:0]frac_A_after_shifting,frac_B_after_shifting;
    always @(*) begin
        if(exp_A<exp_B) frac_A_after_shifting=frac_A>>shift_bit;//可以確保MSB=0。留一位以防進位或overflow
        else frac_A_after_shifting=frac_A>>0;
    end

    always @(*) begin
        if(exp_A>=exp_B) frac_B_after_shifting=frac_B>>shift_bit;
        else frac_B_after_shifting=frac_B>>0;
    end

    always@(*)begin
        //frac_A和frac_B+127後都是正數，所以直接加減就可以了
        if(sign_A==sign_B)frac_out=frac_A_after_shifting+frac_B_after_shifting;//如果MSB=1代表有進位,特別注意
        else if(sign_A==1'b0&&sign_B==1'b1)frac_out=frac_A_after_shifting-frac_B_after_shifting;//代表A正B負，如果MSB=1代表結果為負數
        else frac_out=frac_B_after_shifting-frac_A_after_shifting;//代表B正A負，如果MSB=1代表結果為負數，且frac_out需要被2's comp一次
    end

    always@(*)begin
        if(sign_A==sign_B) begin
            sign_out=sign_A;
        end
        else begin
            sign_out=frac_out[24];
        end
    end
    //正+正 or 負+負OK，但正+負會有問題
    always@(*)begin
        if(frac_out[24]==1'b1&&exp_A>=exp_B)exp_out=exp_A+1;    //normalize
        else if(frac_out[24]==1'b1&&exp_A<exp_B)exp_out=exp_B+1;//normalize
        else if(frac_out[24]==1'b0&&exp_A>=exp_B)exp_out=exp_A;    //不用normalize
        else if(frac_out[24]==1'b0&&exp_A<exp_B)exp_out=exp_B;     //不用normalize
        else exp_out=exp_A;
    end

    always@(*)begin
        if(frac_out[24]==1'b1)FP_out={sign_out,exp_out,frac_out[23:1]};    //需要normalize
        else FP_out={sign_out,exp_out,frac_out[22:0]};                 //不用normalize
    end

endmodule

module MUT(FP_A,FP_B,FP_out);
    input  [31:0]FP_A,FP_B;
    output [31:0]FP_out;

    wire sign_A,sign_B;
    reg sign_out;
    wire [7:0]exp_A,exp_B;
    reg [7:0]exp_out;
    wire [23:0]frac_A,frac_B;
    reg [22:0]frac_out;//ex:1.01101，但多1 bit檢查是否有overflow
    wire [47:0]frac_AXB;

    assign exp_A=FP_A[30:23]; //要-127才是真的指數，11111110代表254，exp就是254-127
    assign exp_B=FP_B[30:23]; //要-127才是真的指數

    assign sign_A=FP_A[31];   assign sign_B=FP_B[31];
    
    always@(*)begin
        if(sign_A==sign_B)sign_out=1'b0;
        else sign_out=1'b1;
    end

    assign frac_A={1'b1,FP_A[22:0]};assign frac_B={1'b1,FP_B[22:0]};
    assign frac_AXB=frac_A*frac_B;
    always@(*)begin
        if(frac_AXB[47]==1'b1)frac_out=frac_AXB[46:24];//要進位 by chatgpt
        else frac_out=frac_AXB[45:23];//應該這樣就乘完了
    end
    always@(*)begin
        if(frac_AXB[47]==1'b1)exp_out=exp_A+exp_B-8'd127+8'd1;//要進位 by chatgpt
        else exp_out=exp_A+exp_B-8'd127;//應該這樣就乘完了
    end
    assign FP_out={sign_out,exp_out,frac_out};

endmodule

module matrix_MUT(M_00,M_01,M_02,M_10,M_11,M_12,M_20,M_21,M_22,in_0,in_1,in_2,Sum_row0,Sum_row1,Sum_row2);
    input [31:0]M_00,M_01,M_02,M_10,M_11,M_12,M_20,M_21,M_22;
    input [31:0]in_0,in_1,in_2;
    wire [31:0]FP_out_00,FP_out_01,FP_out_02;
    wire [31:0]FP_out_10,FP_out_11,FP_out_12;
    wire [31:0]FP_out_20,FP_out_21,FP_out_22;

    wire [31:0]Psum_row0,Psum_row1,Psum_row2;

    output wire [31:0]Sum_row0,Sum_row1,Sum_row2;

    MUT U0(.FP_A(M_00),.FP_B(in_0),.FP_out(FP_out_00));
    MUT U1(.FP_A(M_01),.FP_B(in_1),.FP_out(FP_out_01));
    MUT U2(.FP_A(M_02),.FP_B(in_2),.FP_out(FP_out_02));
    ADD A0(.FP_A(FP_out_00),.FP_B(FP_out_01),.FP_out(Psum_row0));
    ADD A1(.FP_A(Psum_row0),.FP_B(FP_out_02),.FP_out(Sum_row0));

    MUT U3(.FP_A(M_10),.FP_B(in_0),.FP_out(FP_out_10));
    MUT U4(.FP_A(M_11),.FP_B(in_1),.FP_out(FP_out_11));
    MUT U5(.FP_A(M_12),.FP_B(in_2),.FP_out(FP_out_12));
    ADD A2(.FP_A(FP_out_10),.FP_B(FP_out_11),.FP_out(Psum_row1));
    ADD A3(.FP_A(Psum_row1),.FP_B(FP_out_12),.FP_out(Sum_row1));

    MUT U6(.FP_A(M_20),.FP_B(in_0),.FP_out(FP_out_20));
    MUT U7(.FP_A(M_21),.FP_B(in_1),.FP_out(FP_out_21));
    MUT U8(.FP_A(M_22),.FP_B(in_2),.FP_out(FP_out_22));
    ADD A4(.FP_A(FP_out_20),.FP_B(FP_out_21),.FP_out(Psum_row2));
    ADD A5(.FP_A(Psum_row2),.FP_B(FP_out_22),.FP_out(Sum_row2));

endmodule

module RNN(clk,rst_n,in_valid,weight_u,weight_w,weight_v,data_x,data_h,out_valid,out);
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter FLEN = inst_sig_width + inst_exp_width + 1;

    input  clk, rst_n, in_valid;
    input [FLEN-1 : 0] weight_u, weight_w, weight_v, data_x, data_h;
    output reg	out_valid;
    output reg [FLEN-1 : 0] out;//32 bit

    //FSM: 設定一個counter，從in_valid=1後開始數九個clk，數完後會進入計算的state
    parameter IDLE=2'b00;parameter Input_now=2'b01;parameter Input_done= 2'b10;parameter Onput_done= 2'b11;
    reg [1:0] cur_state,next_state;
    
    always@(posedge clk ,posedge rst_n)begin
        if (rst_n) cur_state <= IDLE;
        else        cur_state <= next_state;
    end

    reg [3:0]input_counter; reg [3:0]layer_counter;

    always@(*)begin
        case(cur_state)
            IDLE:
                if(in_valid==1'b1)next_state=Input_now;
                else next_state=IDLE;
            Input_now:
                if(input_counter>=4'd9)next_state=Input_done;
                else next_state=Input_now;
            Input_done:
                //先大概寫的
                if(layer_counter>4'd8)next_state=Onput_done;
                else next_state=Input_done;
            Onput_done:
                next_state=Onput_done;
        endcase
    end

    always@(posedge clk ,posedge rst_n)begin
        if (rst_n)input_counter<=4'd0;
        else if(in_valid==1'b0)input_counter<=4'd0;
        else if(in_valid==1'b1&&input_counter<4'd9) input_counter<=input_counter+1;
        else input_counter<=input_counter;
    end

    reg [31:0]W[0:8]; reg [31:0]U[0:8]; reg [31:0]V[0:8]; reg [31:0]X[0:8];
    reg [31:0]h_0[0:2];

    integer i;
    always@(posedge clk or negedge rst_n)begin
        if (rst_n)begin
            for(i=0;i<9;i=i+1)begin
                W[i]<=32'd0; U[i]<=32'd0;
                V[i]<=32'd0; X[i]<=32'd0;
            end
        end
        else if(in_valid==1'b1&&input_counter<4'd9)begin
            W[8]<=weight_w; U[8]<=weight_u; 
            V[8]<=weight_v; X[8]<=data_x;
            for (i=0;i<8;i=i+1) begin
                W[i]<=W[i+1]; U[i]<=U[i+1]; 
                V[i]<=V[i+1]; X[i]<=X[i+1];
            end
        end
        else begin
            for(i=0;i<9;i=i+1)begin
                W[i]<=W[i]; U[i]<=U[i]; 
                V[i]<=V[i]; X[i]<=X[i];
            end
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if (rst_n)begin
            for(i=0;i<3;i=i+1)begin
                h_0[i]<=32'd0;
            end
        end
        else if(in_valid==1'b1&&input_counter<4'd3)begin
            h_0[2]<=data_h;
            h_0[1]<=h_0[2];
            h_0[0]<=h_0[1];
        end
        else begin
            for(i=0;i<3;i=i+1)begin
                h_0[i]<=h_0[i];
            end
        end
    end

    reg [31:0]x_0[0:2]; reg [31:0]x_1[0:2]; reg [31:0]x_2[0:2];

    always@(*)begin
        x_0[0]=X[0];x_0[1]=X[1];x_0[2]=X[2];
        x_1[0]=X[3];x_1[1]=X[4];x_1[2]=X[5];
        x_2[0]=X[6];x_2[1]=X[7];x_2[2]=X[8];
    end
    
    //先h1=Relu(U*x1+W*h0) clk=1
    //先h2=Relu(U*x2+W*h1) clk=2
    //先h3=Relu(U*x3+W*h2) clk=3
    
    reg [31:0]h_in[0:2]; reg [31:0]x_in[0:2];
    wire [31:0]W_dot_h[0:2];
    wire [31:0]U_dot_x[0:2];
    wire [31:0]h_out[0:2];  wire [31:0]y_out[0:2];

    //計算後的輸出
    reg [31:0]h_1[0:2]; reg [31:0]h_2[0:2]; reg [31:0]h_3[0:2];
    reg [31:0]y_1[0:2]; reg [31:0]y_2[0:2]; reg [31:0]y_3[0:2];

    //layer_counter運作
    always@(posedge clk ,posedge rst_n)begin
        if (rst_n)layer_counter<=4'd0;
        else if(cur_state!=Input_done)layer_counter<=4'd0;
        else if(cur_state==Input_done&&layer_counter<=4'd8)layer_counter<=layer_counter+1;
        else layer_counter<=layer_counter;
    end

    //h_in母湯
    //每個cycle改變h_in和Xin，即可算出所需的h_out
    always@(posedge clk, posedge rst_n)begin
        if (rst_n)begin
            h_in[0]<=h_0[0]; h_in[1]<=h_0[1]; h_in[2]<=h_0[2];
            x_in[0]<=x_0[0]; x_in[1]<=x_0[1]; x_in[2]<=x_0[2];
        end
        else if(cur_state==Input_done&&layer_counter==4'd0)begin
            h_in[0]<=h_0[0]; h_in[1]<=h_0[1]; h_in[2]<=h_0[2];
            x_in[0]<=x_0[0]; x_in[1]<=x_0[1]; x_in[2]<=x_0[2];
        end
        else if(cur_state==Input_done&&layer_counter==4'd2)begin
            h_in[0]<=h_1[0]; h_in[1]<=h_1[1]; h_in[2]<=h_1[2];
            x_in[0]<=x_1[0]; x_in[1]<=x_1[1]; x_in[2]<=x_1[2];
        end
        else if(cur_state==Input_done&&layer_counter==4'd4)begin
            h_in[0]<=h_2[0]; h_in[1]<=h_2[1]; h_in[2]<=h_2[2];
            x_in[0]<=x_2[0]; x_in[1]<=x_2[1]; x_in[2]<=x_2[2];
        end
        else begin
            h_in[0]<=h_in[0]; h_in[1]<=h_in[1]; h_in[2]<=h_in[2];
            x_in[0]<=x_in[0]; x_in[1]<=x_in[1]; x_in[2]<=x_in[2];
        end
    end

    always@(posedge clk ,posedge rst_n)begin
        if (rst_n)begin
            for(i=0;i<3;i=i+1)h_1[i]<=32'd0;
            for(i=0;i<3;i=i+1)h_2[i]<=32'd0;
            for(i=0;i<3;i=i+1)h_3[i]<=32'd0;
        end
        else if(cur_state==Input_done&&layer_counter==4'd1)begin
            h_1[0]<=h_out[0]; h_1[1]<=h_out[1]; h_1[2]<=h_out[2];
            h_2[0]<=32'd0; h_2[1]<=32'd0; h_2[2]<=32'd0;
            h_3[0]<=32'd0; h_3[1]<=32'd0; h_3[2]<=32'd0;
        end
        else if(cur_state==Input_done&&layer_counter==4'd3)begin
            h_1[0]<=h_1[0]; h_1[1]<=h_1[1]; h_1[2]<=h_1[2];
            h_2[0]<=h_out[0]; h_2[1]<=h_out[1]; h_2[2]<=h_out[2];
            h_3[0]<=32'd0; h_3[1]<=32'd0; h_3[2]<=32'd0;
        end
        else if(cur_state==Input_done&&layer_counter==4'd5)begin
            h_1[0]<=h_1[0]; h_1[1]<=h_1[1]; h_1[2]<=h_1[2];
            h_2[0]<=h_2[0]; h_2[1]<=h_2[1]; h_2[2]<=h_2[2];
            h_3[0]<=h_out[0]; h_3[1]<=h_out[1]; h_3[2]<=h_out[2];
        end
        else begin
            for(i=0;i<3;i=i+1)h_1[i]<=h_1[i];
            for(i=0;i<3;i=i+1)h_2[i]<=h_2[i];
            for(i=0;i<3;i=i+1)h_3[i]<=h_3[i];
        end
    end

    always@(posedge clk ,posedge rst_n)begin
        if (rst_n)begin
            for(i=0;i<3;i=i+1)y_1[i]<=32'd0;
            for(i=0;i<3;i=i+1)y_2[i]<=32'd0;
            for(i=0;i<3;i=i+1)y_3[i]<=32'd0;
        end
        else if(cur_state==Input_done&&layer_counter==4'd2)begin
            y_1[0]<=y_out[0]; y_1[1]<=y_out[1]; y_1[2]<=y_out[2];
            y_2[0]<=32'd0; y_2[1]<=32'd0; y_2[2]<=32'd0;
            y_3[0]<=32'd0; y_3[1]<=32'd0; y_3[2]<=32'd0;
        end
        else if(cur_state==Input_done&&layer_counter==4'd3)begin
            y_1[0]<=y_1[0];  y_1[1]<=y_1[1];   y_1[2]<=y_1[2];
            y_2[0]<=y_out[0];y_2[1]<=y_out[1]; y_2[2]<=y_out[2];
            y_3[0]<=32'd0;   y_3[1]<=32'd0;    y_3[2]<=32'd0;
        end
        else if(cur_state==Input_done&&layer_counter==4'd4)begin
            y_1[0]<=y_1[0];   y_1[1]<=y_1[1];   y_1[2]<=y_1[2];
            y_2[0]<=y_2[0];   y_2[1]<=y_2[1];   y_2[2]<=y_2[2];
            y_3[0]<=y_out[0]; y_3[1]<=y_out[1]; y_3[2]<=y_out[2];
        end
        else begin
            for(i=0;i<3;i=i+1)y_1[i]<=y_1[i];
            for(i=0;i<3;i=i+1)y_2[i]<=y_2[i];
            for(i=0;i<3;i=i+1)y_3[i]<=y_3[i];
        end
    end

    matrix_MUT B0(.M_00(W[0]),.M_01(W[1]),.M_02(W[2]),.M_10(W[3]),.M_11(W[4]),.M_12(W[5]),.M_20(W[6]),.M_21(W[7]),.M_22(W[8]),
    .in_0(h_in[0]),.in_1(h_in[1]),.in_2(h_in[2]),.Sum_row0(W_dot_h[0]),.Sum_row1(W_dot_h[1]),.Sum_row2(W_dot_h[2]));

    matrix_MUT B1(.M_00(U[0]),.M_01(U[1]),.M_02(U[2]),.M_10(U[3]),.M_11(U[4]),.M_12(U[5]),.M_20(U[6]),.M_21(U[7]),.M_22(U[8]),
    .in_0(x_in[0]),.in_1(x_in[1]),.in_2(x_in[2]),.Sum_row0(U_dot_x[0]),.Sum_row1(U_dot_x[1]),.Sum_row2(U_dot_x[2]));

    ADD B2(.FP_A(W_dot_h[0]),.FP_B(U_dot_x[0]),.FP_out(h_out[0]));
    ADD B3(.FP_A(W_dot_h[1]),.FP_B(U_dot_x[1]),.FP_out(h_out[1]));
    ADD B4(.FP_A(W_dot_h[2]),.FP_B(U_dot_x[2]),.FP_out(h_out[2]));

    matrix_MUT B5(.M_00(V[0]),.M_01(V[1]),.M_02(V[2]),.M_10(V[3]),.M_11(V[4]),.M_12(V[5]),.M_20(V[6]),.M_21(V[7]),.M_22(V[8]),
    .in_0(h_out[0]),.in_1(h_out[1]),.in_2(h_out[2]),.Sum_row0(y_out[0]),.Sum_row1(y_out[1]),.Sum_row2(y_out[2]));

    reg [3:0]output_counter;

    always@(posedge clk ,posedge rst_n)begin
        if (rst_n)begin
            output_counter<=4'd0;
            out_valid<=1'b0;
        end
        else if(cur_state==Onput_done&&output_counter<=4'd9)begin
            output_counter<=output_counter+4'd1;
            out_valid<=1'b1;
        end
        else begin
            output_counter<=output_counter;
            out_valid<=out_valid;
        end
    end
    
    always@(posedge clk ,posedge rst_n)begin
        if (rst_n)begin
            out<=32'd0;
        end
        else if(cur_state==Onput_done&&output_counter<4'd3)begin
            out<=y_1[output_counter];
        end
        else if(cur_state==Onput_done&&output_counter>=4'd3&&output_counter<4'd6)begin
            out<=y_2[output_counter-3];
        end
        else if(cur_state==Onput_done&&output_counter>=4'd6&&output_counter<4'd9)begin
            out<=y_3[output_counter-6];
        end
        else begin
            out<=out;
        end
    end
endmodule