
TDHS_Pro_Coding;

TDHS_Pro_Decoding;
clear;
load TDHS_Coding_analyse.mat;

load TDHS_Decoding_analyse.mat;

ori_img=double(ori_img);
if(recoverd_img==ori_img)
    disp('Img_sucess');
else
    disp('Img_failed');
end

if(recoverd_msg==ori_bin)
    disp('msg_sucess');
else
    disp('msg_failed');
end

