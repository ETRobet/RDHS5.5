addpath('lib')
FileIO=File_IO;
DC=Data_Convert;
[ori_img_filename,ori_img_filepath]=FileIO.openResFileDialog('bmp','lena32.bmp');
lena32=FileIO.readImgFile(ori_img_filepath);

bin=DC.img2bi(lena32);
img=DC.bi2img(bin);
if(img==lena32)
disp('yes');
end
%%encoding
