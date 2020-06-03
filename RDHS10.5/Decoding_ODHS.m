Init_ODHS;
%%信息装入
[final_img_filename,final_img_filepath]=FileIO.openOutFileDialog('bmp','MarkedImg.bmp');
final_img=FileIO.readImgFile(final_img_filepath);

[img_H,img_V]=size(final_img);%图像长宽
clear final_img_filename final_img_filepath;

[para_msg_filename,para_msg_filepath]=FileIO.openOutFileDialog('txt','para_coding.txt');
[gray_minId256,gray_maxId256,overhead_info_len]=ODHS.getParaByFile(para_msg_filepath);
clear ori_msg_filename ori_msg_filepath;


%提取信息
final_gray_cnts=Init_Gray_Cnts(final_img);%记录灰度
msg_bits_flag=1;
odhs_img=final_img;
[~,msg_bits_max_len] = ODHS.getMaxEmbeddedCapacity( odhs_img,data_type );
[msg_bits,odhs_img] = ODHS.decodingImgToMsg( gray_minId256,gray_maxId256,msg_bits_max_len,odhs_img);
secret_msg=DC.bi2StrUni(msg_bits);%转码
odhs_gray_cnts=Init_Gray_Cnts(odhs_img);%记录灰度


%RC4解密
msg_pak=secret_msg;
 output_RC4dir_path=FileIO.openDirDialog('out\Extract_ODHS','输出解密文件路径');
 FileIO.generateStrFile([output_RC4dir_path,'\RecoveredMsg.txt'],msg_pak);


%%图像处理
%平移直方图
ori_img=odhs_img;
ori_img=ODHS.translationHistogram( gray_minId256,gray_maxId256,ori_img,odhs_img,'Decoding' );
[ori_msg,Locatemap]=ODHS.getLocatemap(msg_pak,overhead_info_len);
 %非零零值点还原
odhs_img=ODHS.zeroHistogramDecoding(gray_minId256,ori_img,Locatemap);
ori_gray_cnts=Init_Gray_Cnts(odhs_img);%记录灰度



figure;
subplot(2,3,1);imshow(final_img);title('秘密lena');
subplot(2,3,2);imshow(odhs_img);title('平移lena');
subplot(2,3,3);imshow(ori_img);title('原始lena');
subplot(2,3,4);bar(0:255,final_gray_cnts,'grouped');title('秘密直方图');
subplot(2,3,5);bar(0:255,odhs_gray_cnts,'grouped');title('平移直方图');
subplot(2,3,6);bar(0:255,ori_gray_cnts,'grouped');title('原始直方图');


output_dir_path2=FileIO.openDirDialog('out\Extract_ODHS','输出图像文件路径');
FileIO.generateImgFile([output_dir_path2,'\RecoveredImg.bmp'],ori_img);
psnr=DP.psnr(final_img,ori_img,8);
disp(['PSNR:',num2str(psnr)]);
