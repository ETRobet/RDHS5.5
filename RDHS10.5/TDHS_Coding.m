%待改进 
%1.棋盘格划分只用了一个半平面
%2.未分块嵌入实现篡改定位       
Init_TDHS;%设置路径 头文件
embed_bin_len=intmax;
capacity=0;%设置容量与长度最值 进入判断循环
while embed_bin_len>capacity
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
    bit_len=16;%记录嵌入长度 预留的二进制位
    ECs=[-10,0,10];%可嵌入信道数组
    preprocess_img=double(ori_img);%归一化
    %预处理图像(两边向中间聚拢，灰度0→1 255→254，坐标标进预处理信息头) 
    [preprocess_img,ext_bin,~]=TDHS.getOverheadInfo(preprocess_img);% 传出ext_bin额外信息 设标志位0or1 判定是否溢出
    %预处理信息（被嵌入信息格式：全数据长度+溢出标志位+坐标数据长度+下溢坐标数据+上溢坐标数据+真实数据）
    [embed_bin,embed_bin_len]=TDHS.getEmbedInfo(ori_bin,ext_bin,bit_len);%包装进data 信息格式 长度位溢出标志位数据位
    %划分棋盘格
    [plane1,plane2,plane1_len,plane2_len]=TDHS.getHalfPlane(preprocess_img);
    %获取预测差值对
    [PDpairs]=TDHS.getPDpair(preprocess_img,plane1);
    %获取预测差值对出现次数分布图H，以预测差值对的最小值为迁移量axisincr，使数组从0开始
    [H,axisincr]=TDHS.getTDHS(PDpairs);
    %二维直方图依据信道降维成一维直方图集合
    [ODHs]=TDHS.getEODH(H,ECs);
    %求左右峰值点集合和容量  
    [peakleft_pixels,peakright_pixels,capacity]=TDHS.getPeakPixel(ODHs,ECs);%输出属性cnt id x y 此处xy指H
    %判定是否超出容量，否则重设
    if(embed_bin_len>capacity)
        error_pause=errordlg('信息过长 请重新选择图像与信息！') ;
        uiwait(error_pause);
    end
end
%获取 预测差值对到所有点坐标的映射集
[PDP2PixelMap]=TDHS.getPDPairToPixelMap(preprocess_img,plane1,H,axisincr);
%平移一维直方图（演示用可省略）
[trans_ODHs]=TDHS.embedTranslationODHS(ODHs,peakleft_pixels,peakright_pixels);
%平移二维直方图
[trans_img]=TDHS.embedTranslation(preprocess_img,H,peakleft_pixels,peakright_pixels,ECs,PDP2PixelMap);
%嵌入信息
[marked_img]=TDHS.embedInfo(trans_img,embed_bin,peakleft_pixels,peakright_pixels,ECs,plane1,axisincr);
%输出
[~,~,~,~,curOut_path,~] =FileIO.getCurPath();
output_dir_path=curOut_path;
FileIO.generateDecFileTDHS([output_dir_path,'\para_coding_TDHS.txt'],peakleft_pixels,peakright_pixels,ECs);
FileIO.generateImgFile([output_dir_path,'\\MarkedImg_TDHS.bmp'],uint8(marked_img));
psnr=DP.psnr(ori_img,marked_img,8);
mse=DP.mse(ori_img,marked_img);
fprintf('PSNR: %s\nMSE: %s\n',num2str(psnr),num2str(mse));
%直方图图形输出
%{
ODH_len=length(ODHs{1});
for i=1:length(ODHs)
    figure;
    bar(1:ODH_len,ODHs{i},'grouped');
end

figure;
mesh(double(H));
title('半平面1');
%}