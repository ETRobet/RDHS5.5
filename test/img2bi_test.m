%{
addpath('lib')
FileIO=File_IO;
[ori_img_filename,ori_img_filepath]=FileIO.openResFileDialog('bmp','lena32.bmp');
lena32=FileIO.readImgFile(ori_img_filepath);
ori_img=double(lena32);
[img_H,img_V]=size(ori_img);
ori_bin=[];
temp_bin=[];
temp_bin_cnt=1;
msg_cnt=1;

%嵌入图像长宽
tempH_bin=de2bi(img_H);
while length(tempH_bin)~=14
tempH_bin(end+1)=0;
end
tempV_bin=de2bi(img_V);
while length(tempH_bin)~=14
tempV_bin(end+1)=0;
end

for i=1:img_H
    for ii=1:img_V
    temp=ori_img(i,ii);
    temp_bin=de2bi(temp);
    while length(temp_bin)~=8
        temp_bin(end+1)=0;
    end
    for j=1:8
    ori_bin(end+1)=temp_bin(j);
    end
    end
end
%%encodimg
%}
length(de2bi(4096))