
clear;
%待改进 
%1.棋盘格划分只用了一个半平面
%2.未分块嵌入实现篡改定位       
Init_TDHS_Pro;%设置路径 头文件
embed_bin_len=intmax;
capacity=0;%设置容量与长度最值 进入判断循环

    %获取图像
    [ori_img_filename,ori_img_filepath]=FileIO.openResFileDialog('bmp','lena512.bmp');
    ori_img=FileIO.readImgFile(ori_img_filepath);
   
    
    [img_H,img_V]=size(ori_img);
    %设置嵌入信息输入方式
    list = {'file_str','file_img','input','randkey'};
    [input_msg_mod,input_msg_mod_flag] = listdlg('ListString',list, 'SelectionMode','single');
    if(input_msg_mod_flag==0) error('nonselseted mod'); end
    switch input_msg_mod
        case 1
            %从文件读取字符串
            [ori_msg_filename,ori_msg_filepath]=FileIO.openResFileDialog('txt','msg.txt');
            [ori_msg_str]=FileIO.readStrFile(ori_msg_filepath);
            [ori_bin]=DC.str2BiUni(ori_msg_str);%Unicode编码字符串转二进制码流
        case 2
            %从图像读取
            [ori_msg_filename,ori_msg_filepath]=FileIO.openResFileDialog('bmp','lena16.bmp');
            ori_img_file=FileIO.readImgFile(ori_msg_filepath);
            [ori_bin]=DC.img2bi(ori_img_file);%图像转码流
        case 3
            %从输入框读取
            inputInfo_str = inputdlg('请输入信息','Input_msg',1);
            [ori_bin]=DC.str2BiUni(inputInfo_str{1});
        case 4
            %随机数生成
            randkey_len_str = inputdlg('请输入随机数长度','Input_msg_rand_len',1);
            randkey_len=str2double(randkey_len_str{1});
            randkey_seed_str = inputdlg('请输入随机种子','Input_msg_randkey',1);
            randkey_seed=str2double(randkey_seed_str{1});
            [ori_bin]=DP.randBin(randkey_seed,randkey_len);
        otherwise
            error('illegal parameter');
    end
    save TDHS_Coding_analyse.mat ori_img ori_bin;
    bit_len=16;%记录嵌入长度 预留的二进制位
    ECs_max=16;
    
    
    ECs=[1,2,3];%可嵌入信道数组(正整数,数量小于16个)
    EC_para=[0];
    
    [marked_img,capacity]=TDHS.mainMyCoding(ori_img,ori_bin,ECs,ECs_max,bit_len,1,EC_para);
    

%输出
[~,~,~,~,curOut_path,~] =FileIO.getCurPath();
output_dir_path=curOut_path;
%FileIO.generateDecFileTDHS([output_dir_path,'\para_coding_TDHSpro.txt'],peakleft_pixels,peakright_pixels,EC_para);
FileIO.generateImgFile([output_dir_path,'\\MarkedImg_TDHSpro.bmp'],uint8(marked_img));
psnr=DP.psnr(ori_img,marked_img,8);
mse=DP.mse(ori_img,marked_img);
fprintf('PSNR: %s\nMSE: %s\n',num2str(psnr),num2str(mse));
