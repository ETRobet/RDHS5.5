function [gray_cnts ] = Init_Gray_Cnts( img )
% 生成灰度信息统计
%   输出 灰度统计；输入图片信息
gray_cnts=zeros(1,256);
[img_H,img_V]=size(img);%图像长宽
for ii=1:img_H
    for jj=1:img_V
       gray_cnts(img(ii,jj)+1)=gray_cnts(img(ii,jj)+1)+1;%[1~256]统计[0~255]需+1
    end
end
end

