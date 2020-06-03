function DP=Data_Process
DP.clip8bit=@Clip_8bit;
DP.group8bit=@Group_8bit;
DP.divide8bit=@Divide_8bit;
DP.overflow8bit=@Overflow_8bit;
DP.randBin=@Rand_Bin;
DP.psnr=@PSNR;
DP.mse=@MSE;
end

function [ overload_flag,clip_msg] = Clip_8bit(clip_flag,msg_bits,ori_img,modStr)
%UNTITLED10 此处显示有关此函数的摘要
%   此处显示详细说明
max_embedded_capacity=Get_Max_Embedded_Capacity(ori_img);
msg_len=length(msg_bits);
if(strcmp(modStr,'A'))
    
elseif(strcmp(modStr,'U'))
    max_embedded_capacity=Get_Odhs_Max_Embedded_Capacity(odhs_lena)+1;
    max_embedded_capacity_Uni_num=floor(max_embedded_capacity/48);
    max_embedded_capacity_Uni=max_embedded_capacity_Uni_num*48;
else
    error('non parameter');
end
if(msg_len>max_embedded_capacity)
  overload_flag=1;
    if(clip_flag)
temp_msg=msg_bits(1:max_embedded_capacity);    
else
temp_msg=msg_bits;
end


else
   overload_flag=0;
   temp_msg=msg_bits;
    
end

clip_msg=temp_msg;
end

function [ databin,datastr] = Rand_Bin(seed,num)

        rng(seed);
        data=rand(1,num);
        databin=zeros(1,num);
        databinInd=find(data>0.5);
        databin(databinInd)=1;
        datastr=num2str(databin);      
 
end




function [ PSNR] = PSNR(reference_img,trans_img,bit_num)
%UNTITLED10 此处显示有关此函数的摘要
%   此处显示详细说明
%编码一个像素用多少二进制位
reference_img=double(reference_img);
trans_img=double(trans_img);
[H,V]=size(reference_img);
MAX=2^bit_num-1;          %图像有多少灰度级
MES=sum(sum((reference_img-trans_img).^2))/(H*V);     %均方差
PSNR=20*log10(MAX/sqrt(MES));               
 
end
function [MSE]=MSE(reference_img,trans_img)
reference_img=double(reference_img);  
trans_img=double(trans_img);  
[H,V]=size(reference_img);  
MSE=sum(sum((reference_img-trans_img).^2))/(H*V);     %均方差
end


