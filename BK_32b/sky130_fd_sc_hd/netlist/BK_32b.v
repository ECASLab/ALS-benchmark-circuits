/* Generated by Yosys 0.19+18 (git sha1 08c319fc3, gcc 11.2.0-19ubuntu1 -fPIC -Os) */

module BK_32b(X, Y, S);
  wire _000_;
  wire _001_;
  wire _002_;
  wire _003_;
  wire _004_;
  wire _005_;
  wire _006_;
  wire _007_;
  wire _008_;
  wire _009_;
  wire _010_;
  wire _011_;
  wire _012_;
  wire _013_;
  wire _014_;
  wire _015_;
  wire _016_;
  wire _017_;
  wire _018_;
  wire _019_;
  wire _020_;
  wire _021_;
  wire _022_;
  wire _023_;
  wire _024_;
  wire _025_;
  wire _026_;
  wire _027_;
  wire _028_;
  wire _029_;
  wire _030_;
  wire _031_;
  wire _032_;
  wire _033_;
  wire _034_;
  wire _035_;
  wire _036_;
  wire _037_;
  wire _038_;
  wire _039_;
  wire _040_;
  wire _041_;
  wire _042_;
  wire _043_;
  wire _044_;
  wire _045_;
  wire _046_;
  wire _047_;
  wire _048_;
  wire _049_;
  wire _050_;
  wire _051_;
  wire _052_;
  wire _053_;
  wire _054_;
  wire _055_;
  wire _056_;
  wire _057_;
  wire _058_;
  wire _059_;
  wire _060_;
  wire _061_;
  wire _062_;
  wire _063_;
  wire _064_;
  wire _065_;
  wire _066_;
  wire _067_;
  wire _068_;
  wire _069_;
  wire _070_;
  wire _071_;
  wire _072_;
  wire _073_;
  output [32:0] S;
  wire [32:0] S;
  input [31:0] X;
  wire [31:0] X;
  input [31:0] Y;
  wire [31:0] Y;
  sky130_fd_sc_hd__nor2_1 _074_ (
    .A(Y[31]),
    .B(X[31]),
    .Y(_072_)
  );
  sky130_fd_sc_hd__nand2_1 _075_ (
    .A(Y[31]),
    .B(X[31]),
    .Y(_073_)
  );
  sky130_fd_sc_hd__nand2_1 _076_ (
    .A(Y[30]),
    .B(X[30]),
    .Y(_000_)
  );
  sky130_fd_sc_hd__nand2b_1 _077_ (
    .A_N(_072_),
    .B(_073_),
    .Y(_001_)
  );
  sky130_fd_sc_hd__xor2_1 _078_ (
    .A(Y[30]),
    .B(X[30]),
    .X(_002_)
  );
  sky130_fd_sc_hd__nand2_1 _079_ (
    .A(Y[28]),
    .B(X[28]),
    .Y(_003_)
  );
  sky130_fd_sc_hd__xnor2_1 _080_ (
    .A(Y[28]),
    .B(X[28]),
    .Y(_004_)
  );
  sky130_fd_sc_hd__nor2_1 _081_ (
    .A(Y[27]),
    .B(X[27]),
    .Y(_005_)
  );
  sky130_fd_sc_hd__and2_0 _082_ (
    .A(Y[27]),
    .B(X[27]),
    .X(_006_)
  );
  sky130_fd_sc_hd__and2_0 _083_ (
    .A(Y[26]),
    .B(X[26]),
    .X(_007_)
  );
  sky130_fd_sc_hd__nor2_1 _084_ (
    .A(Y[26]),
    .B(X[26]),
    .Y(_008_)
  );
  sky130_fd_sc_hd__nor2_1 _085_ (
    .A(_007_),
    .B(_008_),
    .Y(_009_)
  );
  sky130_fd_sc_hd__xnor2_1 _086_ (
    .A(Y[25]),
    .B(X[25]),
    .Y(_010_)
  );
  sky130_fd_sc_hd__xnor2_1 _087_ (
    .A(Y[24]),
    .B(X[24]),
    .Y(_011_)
  );
  sky130_fd_sc_hd__xnor2_1 _088_ (
    .A(Y[22]),
    .B(X[22]),
    .Y(_012_)
  );
  sky130_fd_sc_hd__xnor2_1 _089_ (
    .A(Y[20]),
    .B(X[20]),
    .Y(_013_)
  );
  sky130_fd_sc_hd__xnor2_1 _090_ (
    .A(Y[18]),
    .B(X[18]),
    .Y(_014_)
  );
  sky130_fd_sc_hd__xnor2_1 _091_ (
    .A(Y[16]),
    .B(X[16]),
    .Y(_015_)
  );
  sky130_fd_sc_hd__xnor2_1 _092_ (
    .A(Y[14]),
    .B(X[14]),
    .Y(_016_)
  );
  sky130_fd_sc_hd__xnor2_1 _093_ (
    .A(Y[12]),
    .B(X[12]),
    .Y(_017_)
  );
  sky130_fd_sc_hd__xnor2_1 _094_ (
    .A(Y[10]),
    .B(X[10]),
    .Y(_018_)
  );
  sky130_fd_sc_hd__xnor2_1 _095_ (
    .A(Y[8]),
    .B(X[8]),
    .Y(_019_)
  );
  sky130_fd_sc_hd__xnor2_1 _096_ (
    .A(Y[6]),
    .B(X[6]),
    .Y(_020_)
  );
  sky130_fd_sc_hd__xnor2_1 _097_ (
    .A(Y[4]),
    .B(X[4]),
    .Y(_021_)
  );
  sky130_fd_sc_hd__nand2_1 _098_ (
    .A(Y[1]),
    .B(X[1]),
    .Y(_022_)
  );
  sky130_fd_sc_hd__nand2_1 _099_ (
    .A(Y[0]),
    .B(X[0]),
    .Y(_023_)
  );
  sky130_fd_sc_hd__nor2_1 _100_ (
    .A(Y[1]),
    .B(X[1]),
    .Y(_024_)
  );
  sky130_fd_sc_hd__lpflow_isobufsrc_1 _101_ (
    .A(_022_),
    .SLEEP(_024_),
    .X(_025_)
  );
  sky130_fd_sc_hd__o21ai_0 _102_ (
    .A1(_023_),
    .A2(_024_),
    .B1(_022_),
    .Y(_026_)
  );
  sky130_fd_sc_hd__xnor2_1 _103_ (
    .A(Y[2]),
    .B(X[2]),
    .Y(_027_)
  );
  sky130_fd_sc_hd__maj3_1 _104_ (
    .A(Y[2]),
    .B(X[2]),
    .C(_026_),
    .X(_028_)
  );
  sky130_fd_sc_hd__maj3_1 _105_ (
    .A(Y[3]),
    .B(X[3]),
    .C(_028_),
    .X(_029_)
  );
  sky130_fd_sc_hd__maj3_1 _106_ (
    .A(Y[4]),
    .B(X[4]),
    .C(_029_),
    .X(_030_)
  );
  sky130_fd_sc_hd__maj3_1 _107_ (
    .A(Y[5]),
    .B(X[5]),
    .C(_030_),
    .X(_031_)
  );
  sky130_fd_sc_hd__maj3_1 _108_ (
    .A(Y[6]),
    .B(X[6]),
    .C(_031_),
    .X(_032_)
  );
  sky130_fd_sc_hd__maj3_1 _109_ (
    .A(Y[7]),
    .B(X[7]),
    .C(_032_),
    .X(_033_)
  );
  sky130_fd_sc_hd__maj3_1 _110_ (
    .A(Y[8]),
    .B(X[8]),
    .C(_033_),
    .X(_034_)
  );
  sky130_fd_sc_hd__maj3_1 _111_ (
    .A(Y[9]),
    .B(X[9]),
    .C(_034_),
    .X(_035_)
  );
  sky130_fd_sc_hd__maj3_1 _112_ (
    .A(Y[10]),
    .B(X[10]),
    .C(_035_),
    .X(_036_)
  );
  sky130_fd_sc_hd__maj3_1 _113_ (
    .A(Y[11]),
    .B(X[11]),
    .C(_036_),
    .X(_037_)
  );
  sky130_fd_sc_hd__maj3_1 _114_ (
    .A(Y[12]),
    .B(X[12]),
    .C(_037_),
    .X(_038_)
  );
  sky130_fd_sc_hd__maj3_1 _115_ (
    .A(Y[13]),
    .B(X[13]),
    .C(_038_),
    .X(_039_)
  );
  sky130_fd_sc_hd__maj3_1 _116_ (
    .A(Y[14]),
    .B(X[14]),
    .C(_039_),
    .X(_040_)
  );
  sky130_fd_sc_hd__maj3_1 _117_ (
    .A(Y[15]),
    .B(X[15]),
    .C(_040_),
    .X(_041_)
  );
  sky130_fd_sc_hd__maj3_1 _118_ (
    .A(Y[16]),
    .B(X[16]),
    .C(_041_),
    .X(_042_)
  );
  sky130_fd_sc_hd__maj3_1 _119_ (
    .A(Y[17]),
    .B(X[17]),
    .C(_042_),
    .X(_043_)
  );
  sky130_fd_sc_hd__maj3_1 _120_ (
    .A(Y[18]),
    .B(X[18]),
    .C(_043_),
    .X(_044_)
  );
  sky130_fd_sc_hd__maj3_1 _121_ (
    .A(Y[19]),
    .B(X[19]),
    .C(_044_),
    .X(_045_)
  );
  sky130_fd_sc_hd__maj3_1 _122_ (
    .A(Y[20]),
    .B(X[20]),
    .C(_045_),
    .X(_046_)
  );
  sky130_fd_sc_hd__maj3_1 _123_ (
    .A(Y[21]),
    .B(X[21]),
    .C(_046_),
    .X(_047_)
  );
  sky130_fd_sc_hd__maj3_1 _124_ (
    .A(Y[22]),
    .B(X[22]),
    .C(_047_),
    .X(_048_)
  );
  sky130_fd_sc_hd__maj3_1 _125_ (
    .A(Y[23]),
    .B(X[23]),
    .C(_048_),
    .X(_049_)
  );
  sky130_fd_sc_hd__maj3_1 _126_ (
    .A(Y[24]),
    .B(X[24]),
    .C(_049_),
    .X(_050_)
  );
  sky130_fd_sc_hd__maj3_1 _127_ (
    .A(Y[25]),
    .B(X[25]),
    .C(_050_),
    .X(_051_)
  );
  sky130_fd_sc_hd__a21oi_1 _128_ (
    .A1(_009_),
    .A2(_051_),
    .B1(_007_),
    .Y(_052_)
  );
  sky130_fd_sc_hd__a211oi_1 _129_ (
    .A1(_009_),
    .A2(_051_),
    .B1(_006_),
    .C1(_007_),
    .Y(_053_)
  );
  sky130_fd_sc_hd__nor2_1 _130_ (
    .A(_005_),
    .B(_053_),
    .Y(_054_)
  );
  sky130_fd_sc_hd__o31ai_1 _131_ (
    .A1(_004_),
    .A2(_005_),
    .A3(_053_),
    .B1(_003_),
    .Y(_055_)
  );
  sky130_fd_sc_hd__maj3_1 _132_ (
    .A(Y[29]),
    .B(X[29]),
    .C(_055_),
    .X(_056_)
  );
  sky130_fd_sc_hd__nand2_1 _133_ (
    .A(_002_),
    .B(_056_),
    .Y(_057_)
  );
  sky130_fd_sc_hd__a31oi_1 _134_ (
    .A1(_073_),
    .A2(_000_),
    .A3(_057_),
    .B1(_072_),
    .Y(S[32])
  );
  sky130_fd_sc_hd__xor2_1 _135_ (
    .A(Y[0]),
    .B(X[0]),
    .X(S[0])
  );
  sky130_fd_sc_hd__maj3_1 _136_ (
    .A(Y[30]),
    .B(X[30]),
    .C(_056_),
    .X(_058_)
  );
  sky130_fd_sc_hd__xnor2_1 _137_ (
    .A(_001_),
    .B(_058_),
    .Y(S[31])
  );
  sky130_fd_sc_hd__xor2_1 _138_ (
    .A(_002_),
    .B(_056_),
    .X(S[30])
  );
  sky130_fd_sc_hd__xnor2_1 _139_ (
    .A(Y[29]),
    .B(X[29]),
    .Y(_059_)
  );
  sky130_fd_sc_hd__xnor2_1 _140_ (
    .A(_055_),
    .B(_059_),
    .Y(S[29])
  );
  sky130_fd_sc_hd__xnor2_1 _141_ (
    .A(_004_),
    .B(_054_),
    .Y(S[28])
  );
  sky130_fd_sc_hd__lpflow_inputiso1p_1 _142_ (
    .A(_005_),
    .SLEEP(_006_),
    .X(_060_)
  );
  sky130_fd_sc_hd__xor2_1 _143_ (
    .A(_052_),
    .B(_060_),
    .X(S[27])
  );
  sky130_fd_sc_hd__xor2_1 _144_ (
    .A(_009_),
    .B(_051_),
    .X(S[26])
  );
  sky130_fd_sc_hd__xnor2_1 _145_ (
    .A(_010_),
    .B(_050_),
    .Y(S[25])
  );
  sky130_fd_sc_hd__xnor2_1 _146_ (
    .A(_011_),
    .B(_049_),
    .Y(S[24])
  );
  sky130_fd_sc_hd__xnor2_1 _147_ (
    .A(Y[23]),
    .B(X[23]),
    .Y(_061_)
  );
  sky130_fd_sc_hd__xnor2_1 _148_ (
    .A(_048_),
    .B(_061_),
    .Y(S[23])
  );
  sky130_fd_sc_hd__xnor2_1 _149_ (
    .A(_012_),
    .B(_047_),
    .Y(S[22])
  );
  sky130_fd_sc_hd__xnor2_1 _150_ (
    .A(Y[21]),
    .B(X[21]),
    .Y(_062_)
  );
  sky130_fd_sc_hd__xnor2_1 _151_ (
    .A(_046_),
    .B(_062_),
    .Y(S[21])
  );
  sky130_fd_sc_hd__xnor2_1 _152_ (
    .A(_013_),
    .B(_045_),
    .Y(S[20])
  );
  sky130_fd_sc_hd__xnor2_1 _153_ (
    .A(Y[19]),
    .B(X[19]),
    .Y(_063_)
  );
  sky130_fd_sc_hd__xnor2_1 _154_ (
    .A(_044_),
    .B(_063_),
    .Y(S[19])
  );
  sky130_fd_sc_hd__xnor2_1 _155_ (
    .A(_014_),
    .B(_043_),
    .Y(S[18])
  );
  sky130_fd_sc_hd__xnor2_1 _156_ (
    .A(Y[17]),
    .B(X[17]),
    .Y(_064_)
  );
  sky130_fd_sc_hd__xnor2_1 _157_ (
    .A(_042_),
    .B(_064_),
    .Y(S[17])
  );
  sky130_fd_sc_hd__xnor2_1 _158_ (
    .A(_015_),
    .B(_041_),
    .Y(S[16])
  );
  sky130_fd_sc_hd__xnor2_1 _159_ (
    .A(Y[15]),
    .B(X[15]),
    .Y(_065_)
  );
  sky130_fd_sc_hd__xnor2_1 _160_ (
    .A(_040_),
    .B(_065_),
    .Y(S[15])
  );
  sky130_fd_sc_hd__xnor2_1 _161_ (
    .A(_016_),
    .B(_039_),
    .Y(S[14])
  );
  sky130_fd_sc_hd__xnor2_1 _162_ (
    .A(Y[13]),
    .B(X[13]),
    .Y(_066_)
  );
  sky130_fd_sc_hd__xnor2_1 _163_ (
    .A(_038_),
    .B(_066_),
    .Y(S[13])
  );
  sky130_fd_sc_hd__xnor2_1 _164_ (
    .A(_017_),
    .B(_037_),
    .Y(S[12])
  );
  sky130_fd_sc_hd__xnor2_1 _165_ (
    .A(Y[11]),
    .B(X[11]),
    .Y(_067_)
  );
  sky130_fd_sc_hd__xnor2_1 _166_ (
    .A(_036_),
    .B(_067_),
    .Y(S[11])
  );
  sky130_fd_sc_hd__xnor2_1 _167_ (
    .A(_018_),
    .B(_035_),
    .Y(S[10])
  );
  sky130_fd_sc_hd__xnor2_1 _168_ (
    .A(Y[9]),
    .B(X[9]),
    .Y(_068_)
  );
  sky130_fd_sc_hd__xnor2_1 _169_ (
    .A(_034_),
    .B(_068_),
    .Y(S[9])
  );
  sky130_fd_sc_hd__xnor2_1 _170_ (
    .A(_019_),
    .B(_033_),
    .Y(S[8])
  );
  sky130_fd_sc_hd__xnor2_1 _171_ (
    .A(Y[7]),
    .B(X[7]),
    .Y(_069_)
  );
  sky130_fd_sc_hd__xnor2_1 _172_ (
    .A(_032_),
    .B(_069_),
    .Y(S[7])
  );
  sky130_fd_sc_hd__xnor2_1 _173_ (
    .A(_020_),
    .B(_031_),
    .Y(S[6])
  );
  sky130_fd_sc_hd__xnor2_1 _174_ (
    .A(Y[5]),
    .B(X[5]),
    .Y(_070_)
  );
  sky130_fd_sc_hd__xnor2_1 _175_ (
    .A(_030_),
    .B(_070_),
    .Y(S[5])
  );
  sky130_fd_sc_hd__xnor2_1 _176_ (
    .A(_021_),
    .B(_029_),
    .Y(S[4])
  );
  sky130_fd_sc_hd__xnor2_1 _177_ (
    .A(Y[3]),
    .B(X[3]),
    .Y(_071_)
  );
  sky130_fd_sc_hd__xnor2_1 _178_ (
    .A(_028_),
    .B(_071_),
    .Y(S[3])
  );
  sky130_fd_sc_hd__xnor2_1 _179_ (
    .A(_026_),
    .B(_027_),
    .Y(S[2])
  );
  sky130_fd_sc_hd__xnor2_1 _180_ (
    .A(_023_),
    .B(_025_),
    .Y(S[1])
  );
endmodule