Init_TDHSce;
%输入%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    embed_bin_len=0;
    capacity=intmax;%设置容量与长度最值 进入判断循环
    if(embed_bin_len>capacity)
        error_pause=errordlg('信息过长 请重新选择图像与信息！') ;
        uiwait(error_pause);
    end

end
    clear capacity embed_bin_len img_H img_V input_msg_mod input_msg_mod_flag list...
        ori_img_file ori_img_filename ori_img_filepath ori_msg_filename ori_msg_filepath;
ori_img=double(ori_img);
L_str = inputdlg('请输入分裂次L：','Input_msg',1);
L=str2double(L_str);
%主要%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
embed_L=0;%从0开始嵌入
input_img=ori_img;
input_bin=ori_bin;
while embed_L~=L
    [output_img]=TDHSce.mainCoding(input_img,input_bin,embed_L);
    input_img=output_img;
    input_bin=[];%暂未用信息分段所以下一次分段嵌入直接设空
    embed_L=embed_L+1;
end
marked_img=output_img; 

%输出%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,~,~,~,curOut_path,~] =FileIO.getCurPath();
output_dir_path=curOut_path;
FileIO.generateImgFile([output_dir_path,'\MarkedImg_TDHSce.bmp'],uint8(marked_img));
