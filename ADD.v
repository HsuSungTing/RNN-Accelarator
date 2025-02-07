module ADD(FP_A,FP_B,FP_out);
    input  [31:0]FP_A,FP_B;
    output [31:0]FP_out;

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
        if(frac_out[24]==1'b1)FP_out={sign_out,exp_out,frac_out[23:1]};    //有進位，需要normalize
        else FP_out={sign_out,exp_out,frac_out[22:0]}                      //不用normalize
    end

endmodule