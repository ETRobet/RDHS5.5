Init_TDHSce;
%输入%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,marked_img_filepath]=FileIO.openOutFileDialog('bmp','MarkedImg_TDHSce.bmp');
ori_marked_img=FileIO.readImgFile(marked_img_filepath);
marked_img=double(ori_marked_img);%归一化
%主要%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
input_img=marked_img;
L=intmax;%确保可进入循环
while L~=0
    [output_img,output_bin,L]=TDHSce.mainDecoding(input_img);
    input_img=output_img;
end
recoverd_img=output_img;
recoverd_bin=output_bin;
%输出%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,~,~,~,curOut_path,~] =FileIO.getCurPath();
output_path=FileIO.openDirDialog('out\Extract_TDHSce','输出解密文件路径');
FileIO.generateImgFile([output_path,'\RecoverdImg_TDHSce.bmp'],uint8(recoverd_img));
list = {'file_str','file_dec','file_img','msgbox'};
[output_msg_mod,output_msg_mod_flag] = listdlg('ListString',list, 'SelectionMode','single');
if(output_msg_mod_flag==0) error('nonselseted mod'); end
switch output_msg_mod
    case 1
        [ori_msg]=DC.bi2StrUni(recoverd_bin);
        FileIO.generateStrFile([output_path,'\RecoverdMsg_str_TDHSce.txt'],ori_msg);
    case 2
        [ori_msg]=recoverd_bin;
        FileIO.generateDecFile( [output_path,'\RecoverdMsg_TDHSce.txt'],ori_msg)
    case 3
        if(mod(length(recoverd_bin)-28,16)==0)
            [ori_msg]=DC.bi2img(recoverd_bin);
            FileIO.generateImgFile([output_path,'\RecoverdMsgImg_TDHSce.bmp'],ori_msg);
        else
            [ori_msg]=recoverd_bin;
            FileIO.generateDecFile( [output_path,'\RecoverdMsg_TDHSce.txt'],ori_msg)
            error('illegal img ;forced ouput file');
        end
    case 4
        [ori_msg]=num2str(recoverd_bin);
        msgbox(ori_msg);
    otherwise
        error('illegal parameter');
end

