 Init_TDHS_Pro;
%载入默认图像对比（coding时不手动改输入）
%load TDHS_Coding128_analyse;%提供原始图像对比
load TDHS_Coding_analyse;
bit_len=16;%预设数据长度位
%获取图像
[~,marked_img_filepath]=FileIO.openOutFileDialog('bmp','MarkedImg_TDHSpro.bmp');
ori_marked_img=FileIO.readImgFile(marked_img_filepath);
marked_img=double(ori_marked_img);%归一化
clear final_img_filename final_img_filepath;
%获取参数文件，分配到各个对应集合
%[~,para_msg_filepath]=FileIO.openOutFileDialog('txt','para_coding_TDHSpro.txt');
%[peakleft_pixels,peakright_pixels,EC_para]=TDHS.getParaByFile(para_msg_filepath);
clear para_msg_filename para_msg_filepath;
bit_len=16;
ECs_max=16;




  %还原秘密信息
  [recoverd_img,recoverd_msg]=TDHS.mainMyDecoding(marked_img,ECs_max,bit_len,1);



save TDHS_Decoding_analyse.mat recoverd_img recoverd_msg;




%{

      [ori_LSB_marked_img,peak_bin2]=TDHS.mainDecoding(ori_marked_img,peakleft_pixels,peakright_pixels,EC_para,ECs_max,bit_len,0);

LSB_marked_img=ori_LSB_marked_img;

      %还原参数信道信息
        [Recoverd_LSB_embed_bits,LSB_full_bits]=TDHS.LSBRecoverd(LSB_marked_img,ECs_max);
      
      [Recoverd_peakleft_pixels,Recoverd_peakright_pixels,Recoverd_ECs]=TDHS.recoverdLSBEmbedBits(Recoverd_LSB_embed_bits);
      [Recoverd_ori_marked_img]=TDHS.LSBExtract(peak_bin2,LSB_marked_img,Recoverd_ECs,ECs_max);
      peakleft_pixels=Recoverd_peakleft_pixels;
      peakright_pixels=Recoverd_peakright_pixels;
      ECs=Recoverd_ECs;

      


[recoverd_img,recoverd_msg]=TDHS.mainDecoding(Recoverd_ori_marked_img,peakleft_pixels,peakright_pixels,Recoverd_ECs,ECs_max,bit_len,1);

%}


%输出
 [~,~,~,~,curOut_path,~] =FileIO.getCurPath();
output_path=FileIO.openDirDialog('out\Extract_TDHSpro','输出解密文件路径');
FileIO.generateImgFile([output_path,'\RecoverdImg_TDHSpro.bmp'],uint8(recoverd_img));
list = {'file_str','file_dec','file_img','msgbox'};
[output_msg_mod,output_msg_mod_flag] = listdlg('ListString',list, 'SelectionMode','single');
if(output_msg_mod_flag==0) error('nonselseted mod'); end
switch output_msg_mod
    case 1
        [ori_msg]=DC.bi2StrUni(recoverd_msg);
        FileIO.generateStrFile([output_path,'\RecoverdMsg_str_TDHSpro.txt'],ori_msg);
    case 2
        [ori_msg]=recoverd_msg;
        FileIO.generateDecFile( [output_path,'\RecoverdMsg_TDHSpro.txt'],ori_msg)
    case 3
        if(mod(length(recoverd_msg)-28,16)==0)
            [ori_msg]=DC.bi2img(recoverd_msg);
            FileIO.generateImgFile([output_path,'\RecoverdMsgImg_TDHSpro.bmp'],ori_msg);
        else
            [ori_msg]=recoverd_msg;
            FileIO.generateDecFile( [output_path,'\RecoverdMsg_TDHSpro.txt'],ori_msg)
            error('illegal img ;forced ouput file');
        end
    case 4
        [ori_msg]=num2str(recoverd_msg);
        msgbox(ori_msg);
    otherwise
        error('illegal parameter');
end



psnr=DP.psnr(marked_img,recoverd_img,8);
mse=DP.mse(marked_img,recoverd_img);
fprintf('PSNR: %s\nMSE: %s\n',num2str(psnr),num2str(mse));
