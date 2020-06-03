%{
addpath('lib');
FileIO=File_IO;
[~,ori_img1_filepath]=FileIO.openResFileDialog('bmp');
img1=FileIO.readImgFile(ori_img1_filepath);
[~,ori_img2_filepath]=FileIO.openOutFileDialog('bmp');
img2=FileIO.readImgFile(ori_img2_filepath);
%}
if(ori_img==recoverd_img)
msgbox('Extract Img Sucess');
else
msgbox('Extract Img Failed');
end
if(ori_bin==recoverd_msg)
msgbox('Extract Msg Sucess');
else
msgbox('Extract Msg Failed');
end