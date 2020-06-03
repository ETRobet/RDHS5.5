function DC=Data_Convert
DC.bi2StrUni=@Bits_To_Str_Unicode;
DC.str2BiUni=@Str_To_Bits_Unicode;
DC.bi2StrAsc=@Bits_To_Str_Ascii;
DC.str2BiAsc=@Str_To_Bits_Ascii;
DC.str2Bi=@Str_To_Bits;
DC.bi2Str=@Bits_To_Str;
DC.img2bi=@Img_To_Bits;
DC.bi2img=@Bits_To_Img;
end


function [msgStr]=Bits_To_Str(msg_bits,modStr)
if(strcmp(modStr,'A'))   
msgStr=Bits_To_Str_Ascii(msg_bits);
elseif(strcmp(modStr,'U'))
    msgStr=Bits_To_Str_Unicode(msg_bits);
else
    error('non parameter');
end
end
function msg_bits = Str_To_Bits(msgStr,modStr)
if(strcmp(modStr,'A'))   
msg_bits=Str_To_Bits_Ascii(msgStr);
elseif(strcmp(modStr,'U'))
    msg_bits=Str_To_Bits_Unicode(msgStr);
else
    error('non parameter');
end
end

function msg_bits = Str_To_Bits_Ascii(msgStr)
   msg_bits=dec2bin(msgStr,6);
   [M,N]=size(msg_bits);
   msg_bits=reshape(msg_bits,[1,M*N]);
   msg_bits=double(msg_bits-'0');
end
function msgStr = Bits_To_Str_Ascii(msg_bits)
msgStr=reshape(char(bin2dec(msg_bits)),[1,length(char(bin2dec(msg_bits)))]);

end
function msg_bits = Str_To_Bits_Unicode(msgStr)
% 字符串转二进制码流 Unicode兼容
%   输出 信息二进制码流 ；输入 信息字符串
try
    native=unicode2native(msgStr);%转成本地编码
    msgBin=de2bi(native,8,'left-msb');%转成8bit
    len = size(msgBin,1).*size(msgBin,2);
    msg_bits = reshape(double(msgBin).',len,1).';
        catch
        error_pause=errordlg('转码类型错误！') ;
        uiwait(error_pause);
        return;
    end

end
function msgStr = Bits_To_Str_Unicode(msg_bits)
%二进制码流转字符串 Unicode兼容的
%   输出 信息字符串 ；输入 信息二进制码流
    try
    bit1=reshape(msg_bits,8,numel(msg_bits)/8).';%整形成8bit表示的字节
    native1=bi2de(bit1,'left-msb').';%转成编码
    b=native2unicode(native1);
    msgStr=char(b);
    catch
        error_pause=errordlg('转码类型错误！') ;
        uiwait(error_pause);
        return;
    end

end
function [bin,img_bin,HV_bin]=Img_To_Bits(img,varargin)

switch nargin
    case 2
        img_bit_size=varargin{1};
    case 1
        img_bit_size=14;
    otherwise
        error('too many parameters');
end

ori_img=double(img);
[img_H,img_V]=size(ori_img);
img_bin=[];
temp_bin=[];
temp_bin_cnt=1;
msg_cnt=1;

%嵌入图像长宽
HV_bin=[];
tempH_bin=de2bi(img_H);
while length(tempH_bin)~=img_bit_size
tempH_bin(end+1)=0;
end
tempV_bin=de2bi(img_V);
while length(tempV_bin)~=img_bit_size
tempV_bin(end+1)=0;
end
HV_bin=tempH_bin;
for i=1:img_bit_size
HV_bin(end+1)=tempV_bin(i);
end

for i=1:img_H
    for ii=1:img_V
    temp=ori_img(i,ii);
    temp_bin=de2bi(temp);
    while length(temp_bin)~=8
        temp_bin(end+1)=0;
    end
    for j=1:8
    img_bin(end+1)=temp_bin(j);
    end
    end
end
bin=HV_bin;
for jj=1:length(img_bin)
bin(end+1)=img_bin(jj);
end




end
function [img]=Bits_To_Img(bin,varargin)

switch nargin
    case 2
        img_bit_size=varargin{1};
    case 1
        img_bit_size=14;
    otherwise
        error('too many parameters');
end




H_bin=[];
V_bin=[];
img_bin=[];
for i=1:img_bit_size
    H_bin(end+1)=bin(i);
end
for i=1:img_bit_size
    V_bin(end+1)=bin(i+img_bit_size);
end
img_H=bi2de(H_bin);
img_V=bi2de(V_bin);
for i=1:length(bin)-img_bit_size*2
img_bin(end+1)=bin(i+img_bit_size*2);
end
img=zeros(img_H,img_V);
bin_cnt=0;
for i=1:img_H
    for ii=1:img_V
        temp_bin=[];
        for j=1:8
        temp_bin(end+1)=bin(j+bin_cnt+img_bit_size*2);
        end
        temp=bi2de(temp_bin);
        bin_cnt=bin_cnt+8;
        img(i,ii)=temp;
    end
end

img=uint8(img);


end