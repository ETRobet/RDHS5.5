Init_ODHS;
%UI控件
input_msg_mod=1;


%%信息装入
[ori_img_filename,ori_img_filepath]=FileIO.openResFileDialog('bmp','lena512.bmp');
ori_img=FileIO.readImgFile(ori_img_filepath);
[img_H,img_V]=size(ori_img);%图像长宽
clear ori_img_filename ori_img_filepath;

switch input_msg_mod
    case 1
        %取信息
        [ori_msg_filename,ori_msg_filepath]=FileIO.openResFileDialog('txt','msg.txt');
        ori_msg=FileIO.readStrFile(ori_msg_filepath);
        clear ori_msg_filename ori_msg_filepath;
    case 2
        randkey = 0.35;%生成随机种子参数
        %maxH原为最大可嵌入的比特payload
        %生成水印序列
        maxH=100;
        
        rand('seed',randkey);%产生随机种子
        wmSeq = rand(1,maxH);%固定随机数产生
        wmSeqBin = zeros(1,maxH);%初始化随机矩阵置零
        wmSeqInd = find(wmSeq>0.5);%随机数大于0.5的
        wmSeqBin(wmSeqInd) = 1; %将随机矩阵随机置1
        ori_msg_bits=wmSeqBin;
        %msg_bits=DC.str2BiAsc(msg_paks);
        %msg_bits=Str_To_Bits_Unicode(char(msg_bits));
        ori_msg=char(ori_msg_bits);
    otherwise
        error('占位');
end


%收集信息
[ori_gray_cnts,gray_minId256,gray_maxId256,overhead_info_len,msg]...
    =ODHS.preprocess(ori_img,ori_msg,data_type,overload_solution);

%转码
msg_bits=DC.str2BiUni( ori_msg);
msg_bits_len=length(msg_bits);


%%预处理图像
odhs_img=ori_img;
odhs_img=ODHS.zeroHistogramCoding(gray_minId256,ori_img);%非零零值点置零
odhs_img=ODHS.translationHistogram( gray_minId256,gray_maxId256,ori_img,odhs_img,'Coding' );%平移直方图
odhs_gray_cnts=Init_Gray_Cnts(odhs_img);%记录灰度信息
%嵌入信息
final_img=odhs_img;
[final_img,msg_img]=ODHS.codingMsgToImg(  gray_minId256,gray_maxId256,length(msg_bits),msg_bits,final_img);
final_gray_cnts=Init_Gray_Cnts(final_img);%记录灰度信息




%分析
figure;
subplot(2,3,1);imshow(ori_img);title('原始lena');
subplot(2,3,2);imshow(odhs_img);title('平移lena');
subplot(2,3,3);imshow(final_img);title('秘密lena');
subplot(2,3,4);bar(0:255,ori_gray_cnts,'grouped');title('原始直方图');
subplot(2,3,5);bar(0:255,odhs_gray_cnts,'grouped');title('平移直方图');
subplot(2,3,6);bar(0:255,final_gray_cnts,'grouped');title('秘密直方图');

[~,~,~,~,output_dir_path] =FileIO.getCurPath();
            
%output_dir_path=FileIO.openDirDialog('out','输出文件路径');
FileIO.generateDecFile([output_dir_path,'\para_coding.txt'],[gray_minId256,gray_maxId256,overhead_info_len]);
FileIO.generateImgFile([output_dir_path,'\MarkedImg.bmp'],final_img);
FileIO.generateImgFile([output_dir_path,'\secret_msg_coding.bmp'],msg_img);
psnr=DP.psnr(ori_img,final_img,8);
disp(['PSNR:',num2str(psnr)]);
