module MUT(FP_A,FP_B,FP_out);
    input  [31:0]FP_A,FP_B;
    output [31:0]FP_out;

    wire sign_A,sign_B;
    reg sign_out;
    wire [7:0]exp_A,exp_B,exp_out;
    wire [23:0]frac_A,frac_B;
    wire [22:0]frac_out;//ex:1.01101，但多1 bit檢查是否有overflow
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