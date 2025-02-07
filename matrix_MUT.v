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