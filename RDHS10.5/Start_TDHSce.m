TDHSce_Coding;
save TDHSceCodingAnalyseData.mat ori_bin ori_img;
TDHSce_Decoding;
load TDHSceCodingAnalyseData.mat;
%分析一致性
if (recoverd_bin==ori_bin)  disp('Extract_Preprocess_Data Sucess');  elseif(length(recoverd_bin)==0&&length(ori_bin)==0) disp('Extract_Preprocess_0Data Sucess'); else disp('Extract_Preprocess_Data Failed'); end
if (recoverd_img==ori_img) disp('Extract_Preprocess_Img Sucess'); else disp('Extract_Preprocess_Img Failed'); end
psnr=DP.psnr(ori_img,marked_img,8);
mse=DP.mse(ori_img,marked_img);
fprintf('PSNR: %s\nMSE: %s\n',num2str(psnr),num2str(mse));