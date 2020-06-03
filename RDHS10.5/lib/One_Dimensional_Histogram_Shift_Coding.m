function ODHS=One_Dimensional_Histogram_Shift_Coding
ODHS.getMaxGrayId256Cnts=@Get_Max_Gray_Id256_cnts;
ODHS.getMinGrayId256Cnts=@Get_Min_Gray_Id256_cnts;
ODHS.getMinMaxGrayId256Cnts=@Get_MinMax_Gray_Id256_cnts;
ODHS.getOverheadInfo=@Get_Overhead_Info;
ODHS.getMaxEmbeddedCapacity=@Get_Max_Embedded_Capacity;
ODHS.translateHistogram=@Translate_Histogram;
ODHS.translateHistogram=@Translate_Histogram;
ODHS.grayCntsXNORIm=@Gray_Cnts_XNOR_Img;
ODHS.isOverload=@IsOverload;
ODHS.overload=@Overload;
ODHS.overloadClip=@OverloadClip;
ODHS.overloadGroup=@OverloadGroup;
ODHS.getMaxEmbeddedCapacityPureload=@Get_Max_Embedded_Capacity_Pureload;
ODHS.zeroHistogramCoding=@Zero_Histogram_Coding;
ODHS.zeroHistogramDecoding=@Zero_Histogram_Decoding;
ODHS.codingMsgToImg=@Coding_Msg_To_Img;
ODHS.decodingImgToMsg=@Decoding_Img_To_Msg;
ODHS.translationHistogram=@Translation_Histogram;
ODHS.generateResultCoding=@Generate_Result_Coding;
ODHS.generateResultDecoding=@Generate_Result_Decoding;

ODHS.getParaByFile=@Get_Para_By_File;
ODHS.getLocatemap=@Get_Locatemap;

ODHS.preprocess=@Preprocess;



end
function [ gray_maxId256,gray_max_cnt ] = Get_Max_Gray_Id256_cnts( gray_cnts,varargin)
% 此处显示有关此函数的摘要
%   此处显示详细说明
%定位灰度最大值 256级别峰点：maxId256 峰值：maxCnt
gray_maxIds256 = find(gray_cnts==max(gray_cnts));%找到H中对应最大值的索引,索引值为1-256，对应实际像素值0-255
if(nargin==2)
    if(strcmp(varargin{1},'left'))
        gray_maxId256 = min(gray_maxIds256) ;%找到灰度最大值计数 从左找
    elseif(strcmp(varargin{1},'right'))
        gray_maxId256 = max(gray_maxIds256) ;%找到灰度最大值计数 从左找
    else
        error('illegal parameter')
    end
elseif(nargin==1)
    gray_maxId256 = max(gray_maxIds256) ;
    
end
gray_max_cnt=gray_cnts(gray_maxId256);
end
function [ gray_minId256,gray_min_cnt,overheadInfoFlag] = Get_Min_Gray_Id256_cnts( gray_cnts ,varargin)
% 此处显示有关此函数的摘要
%   此处显示详细说明
%%定位零值点
gray_minIds256 = find(gray_cnts==min(gray_cnts));%找到H中对应最小值的索引

%生成overhead标记最小值的额外开销 最小值为零 取零值点最大索引 处
%b为零值点灰度值 刻度0-255 从右找
if min(gray_cnts)==0 %找到H(x)=0的直方图，并将其最大化
    if(nargin==2)
        if(strcmp(varargin{1},'left'))
            gray_minId256 = min(gray_minIds256) ;%找到灰度最大值计数 从左找
        elseif(strcmp(varargin{1},'right'))
            gray_minId256 = max(gray_minIds256) ;%找到灰度最大值计数 从左找
        else
            error('illegal parameter');
        end
    elseif(nargin==1)
        gray_minId256 = min(gray_minIds256) ;
    end
    gray_min_cnt=gray_cnts(gray_minId256);
    overheadInfoFlag = 0;%标记零值类型flag
else      %最小值非零 取零值点最大索引处
    if(nargin==2)
        if(strcmp(varargin{1},'left'))
            gray_minId256 = min(gray_minIds256) ;%找到灰度最大值计数 从左找
        elseif(strcmp(varargin{1},'right'))
            gray_minId256 = max(gray_minIds256) ;%找到灰度最大值计数 从左找
        else
            error('illegal parameter')
        end
    elseif(nargin==1)
        gray_minId256 = min(gray_minIds256) ;
    end
    gray_min_cnt=gray_cnts(gray_minId256);
    overheadInfoFlag = 1;%标记零值类型flag
    
end
end
function [ gray_minId256,gray_maxId256, overheadInfoFlag] = Get_MinMax_Gray_Id256_cnts( gray_cnts,varargin)
% 此处显示有关此函数的摘要
%   此处显示详细说明
%%定位零值点
if(nargin==2)
    
    if(strcmp(varargin{1},'short'))
        [gray_minId256,~,overheadInfoFlag]=Get_Min_Gray_Id256_cnts( gray_cnts,'right' );
        gray_maxId256=Get_Max_Gray_Id256_cnts( gray_cnts,'left' );
        
    elseif(strcmp(varargin{1},'long'))
        [gray_minId256,~,overheadInfoFlag]=Get_Min_Gray_Id256_cnts( gray_cnts,'left' );
        gray_maxId256=Get_Max_Gray_Id256_cnts( gray_cnts,'right');
        
    end
    
elseif(nargin>=3)
    error('too many parameter')
else
    [gray_minId256,~,overheadInfoFlag]=Get_Min_Gray_Id256_cnts( gray_cnts,'left' );
    gray_maxId256=Get_Max_Gray_Id256_cnts( gray_cnts,'right' );
    
end

end
function [ Locatemap,overhead_info_len,gray_minId256] = Get_Overhead_Info( img,leftId,rightId)
%UNTITLED10 此处显示有关此函数的摘要
%   此处显示详细说明

gray_cnts=Init_Gray_Cnts(img);
min1=min(gray_cnts);
gray_minIds256 = find(gray_cnts==min1);%找到H中对应最小值的索引

gray_minId256=[];
while(~length(gray_minId256))
    for i=1:length(gray_minIds256)
        if(gray_minIds256(i)>=leftId)
            gray_minId256=gray_minIds256(i);
            break;
        end
        
    end
    min1=min1+1;
    gray_minIds256 = find(gray_cnts==min1);
    
end
if(gray_cnts(gray_minId256)==0)
    overhead_info_flag=0;
else
    overhead_info_flag=1;
    
end

if(overhead_info_flag==1)
    
    
    j=1;
    gray_minId255=gray_minId256-1;
    [i1,i2]=find(img==gray_minId255); %i1,i2对应满足条件的图像横、纵坐标
    num=size(i1,1);%非零的零值点个数
    for idx=1:num
        %转存overhead信息 格式1~num 前元素横坐标后元素纵坐标
        Locatemap(j)=i1(idx);%转存’零值‘横坐标
        Locatemap(j+1)=i2(idx);%转存‘零值’纵坐标
        j=j+2;%转存表计数器进位
    end
else
    Locatemap=[];
end
overhead_info_len=length(Locatemap);
end
function [ max_capacity_bit,max_capacity_real_bit,max_capacity_str_num,coords ] = Get_Max_Embedded_Capacity( img,modStr )
%UNTITLED10 此处显示有关此函数的摘要
%   此处显示详细说明


gray_cnts=zeros(1,256);
[img_H,img_V]=size(img);%图像长宽
for ii=1:img_H
    for jj=1:img_V
        gray_cnts(img(ii,jj)+1)=gray_cnts(img(ii,jj)+1)+1;%[1~256]统计[0~255]需+1
    end
end
[gray_max_cnt,gray_maxId256]=max(gray_cnts);
%%统计可嵌入坐标

secret_coords=cell(gray_max_cnt,1);

coord.x=0;
coord.y=0;
cnt=1;
for i=1:img_H
    for j=1:img_V
        if(img(i,j)==(gray_maxId256-1))%1~256转0~255
            coord.x=i;
            coord.y=j;
            secret_coords{cnt}=coord;
            cnt=cnt+1;
        end
    end
    
end
max_capacity_bit=gray_max_cnt;
coords=secret_coords;

switch modStr
    case 'A'
        capacity_loss_bit=mod(max_capacity_bit,8);
        max_capacity_str_num=(max_capacity_bit-capacity_loss_bit)/8;
        max_capacity_real_bit=max_capacity_str_num*8;
    case 'B'%后续支持
        capacity_loss_bit=mod(max_capacity_bit,8);
        max_capacity_str_num=(max_capacity_bit-capacity_loss_bit)/8;
        max_capacity_real_bit=max_capacity_str_num*8;
    case 'U'
        capacity_loss_bit=mod(max_capacity_bit,16);
        max_capacity_str_num=(max_capacity_bit-capacity_loss_bit)/16;
        max_capacity_real_bit=max_capacity_str_num*16;
    otherwise
        error('illegal parameter');
end

end
function [max_capacity_str_num] = Get_Max_Embedded_Capacity_Pureload( gray_cnts,modStr, img,leftId,rightId )
%UNTITLED10 此处显示有关此函数的摘要
%   此处显示详细说明


[gray_max_cnt,gray_maxId256]=max(gray_cnts);
max_capacity_bit=gray_max_cnt;
[ gray_minId256,gray_maxId256,overhead_info_flag] = Get_MinMax_Gray_Id256_cnts( gray_cnts);
[overhead_info,overhead_info_len]=Get_Overhead_Info( img,leftId,rightId);
switch modStr
    case 'A'
        
        max_capacity_bit=max_capacity_bit-(overhead_info_len*8);
        capacity_loss_bit=mod(max_capacity_bit,8);
        max_capacity_str_num=(max_capacity_bit-capacity_loss_bit)/8;
        max_capacity_real_bit=max_capacity_str_num*8;
    case 'B'
        max_capacity_bit=max_capacity_bit-(overhead_info_len*1);
        
        capacity_loss_bit=mod(max_capacity_bit,1);
        max_capacity_str_num=(max_capacity_bit-capacity_loss_bit)/1;
        max_capacity_real_bit=max_capacity_str_num*1;
    case 'U'
        max_capacity_bit=max_capacity_bit-(overhead_info_len*1);
        
        capacity_loss_bit=mod(max_capacity_bit,48);
        max_capacity_str_num=(max_capacity_bit-capacity_loss_bit)/48;
        max_capacity_real_bit=max_capacity_str_num*48;
    otherwise
        error('illegal parameter');
end

end
function [new_img ] = Gray_Cnts_XNOR_Img( leftId256,rightId256,img)

% 生成灰度信息统计
%   输出 灰度统计；输入图片信息
[img_H,img_V]=size(img);
new_img=zeros(img_H,img_V);
for ii=1:img_H
    for jj=1:img_V
        if(img(ii,jj)+1>=leftId256&&img(ii,jj)+1<=rightId256)
        new_img(ii,jj)=img(ii,jj);
        end
    end
end

end
function [overload_flag ] = IsOverload( msg_pak,ori_lena,modStr)


[ max_capacity_bit] = Get_Max_Embedded_Capacity( ori_lena,modStr );

switch modStr
    case 'A'
        msg_bit_len=length(msg_pak)*8;
    case 'B'
        msg_bit_len=length(msg_pak);
    case 'U'
        msg_bit_len=length(msg_pak)*48;
    otherwise
        error('illegal parameter');
end

if(msg_bit_len>max_capacity_bit)
    overload_flag=1;
else
    overload_flag=0;
end

end
function [msg_paks] = Overload(msg_pak,ori_lena,data_type,overload_solution)
switch overload_solution
    case 'clip'
        msg_paks=OverloadClip(msg_pak,ori_lena,data_type);
    case 'group';
        msg_paks=OverloadGroup(msg_pak,ori_lena,data_type);
    otherwise
        error('illegal parameter');
end
end
function [msg_paks] = OverloadClip(msg_pak,ori_lena,data_type)
[ max_capacity_bit,max_capacity_real_bit,max_capacity_str_num] = Get_Max_Embedded_Capacity( ori_lena,data_type);
msg_num=length(msg_pak);
msg_paks=msg_pak(1:max_capacity_str_num);
end
function [msg_paks] = OverloadGroup(msg_pak,ori_lena,data_type)
[ max_capacity_bit,max_capacity_real_bit,max_capacity_str_num] = Get_Max_Embedded_Capacity( ori_lena,data_type);
msg_num=length(msg_pak);
group_num=1;overload_flag=1;
while(overload_flag)
    group_num=group_num+1;
    temp_msg_pak=[];
    temp_msg_paks=[];
    overhead_info_lens=[];
    ori_gray_cnts_groups=[];
    group_index=floor(256/group_num);
    ori_gray_cnts=Init_Gray_Cnts(ori_lena);
    msg_paks_group_index=1;
    new_msg_pak=[];
    leftId256=[];
    rightId256=[];
    img_groups=[];
    for i=1:group_num
        ori_gray_cnts_groups{end+1}=ori_gray_cnts(((i-1)*group_index+1):group_index*i);
        leftId256{end+1}=((i-1)*group_index+1);
        rightId256{end+1}=group_index*i;
        img_groups{end+1}=Gray_Cnts_XNOR_Img(((i-1)*group_index+1),group_index*i,ori_lena);
    end
    for ii=1:group_num
        [ ~,gray_maxId256,overhead_info_flag] = Get_MinMax_Gray_Id256_cnts( ori_gray_cnts_groups{ii});
        [overhead_info,overhead_info_len,gray_minId256]=Get_Overhead_Info(img_groups{ii},leftId256{ii},rightId256{ii});
        overhead_info_lens{end+1}=overhead_info_len;
        [ max_capacity_str_num] = Get_Max_Embedded_Capacity_Pureload( ori_gray_cnts_groups{ii},data_type,img_groups{ii},leftId256{ii},rightId256{ii});
        msg_num=length(msg_pak);
        if((msg_paks_group_index+max_capacity_str_num-1)==length(msg_pak))
            temp_msg_pak=msg_pak(msg_paks_group_index: msg_paks_group_index+max_capacity_str_num-1);
            new_msg_pak=[];
        elseif((msg_paks_group_index+max_capacity_str_num-1)>length(msg_pak))
            temp_msg_pak=msg_pak(msg_paks_group_index:end);
            new_msg_pak=[];
        else
            temp_msg_pak=msg_pak(msg_paks_group_index: msg_paks_group_index+max_capacity_str_num-1);
            new_msg_pak=msg_pak(msg_paks_group_index+max_capacity_str_num:end);
            msg_paks_group_index=length(temp_msg_pak)+1;
        end
        temp_msg_paks{end+1}=[overhead_info,temp_msg_pak];
    end
    if(length(new_msg_pak)==0)
        overload_flag=0
    end
end
msg_paks=temp_msg_paks;
end
function [trans_img] = Translation_Histogram( gray_minId256,gray_maxId256,ori_img,trans_img,modStr )
% 平移直方图
%   输出 平移后直方图；输入 最小灰度256刻度，最大灰度256刻度，原始图像，平移图像，平移模式（Coding/Decoding）


%预处理
[img_H,img_V]=size(ori_img);%图像长宽
switch modStr
    case 'Coding'
        if(gray_minId256<gray_maxId256)
            for i=1:img_H
                for j=1:img_V
                    if((ori_img(i,j)<(gray_maxId256-1))&&(ori_img(i,j)>(gray_minId256-1)));
                        trans_img(i,j)=trans_img(i,j)-uint8(1);
                    end
                end
                
            end
        else
            for ii=1:img_H
                for jj=1:img_V
                    if((ori_img(ii,jj)>(gray_maxId256-1))&&(ori_img(ii,jj)<(gray_minId256-1)));
                        trans_img(ii,jj)=trans_img(ii,jj)+uint8(1);
                        
                    end
                end
            end
        end
    case 'Decoding'
        if(gray_minId256<gray_maxId256)
            for i=1:img_H
                for j=1:img_V
                    if((ori_img(i,j)<(gray_maxId256-1))&&(ori_img(i,j)>(gray_minId256-1)));
                        trans_img(i,j)=trans_img(i,j)+uint8(1);
                    end
                end
                
            end
        else
            for ii=1:img_H
                for jj=1:img_V
                    if((ori_img(ii,jj)>(gray_maxId256-1))&&(ori_img(ii,jj)<(gray_minId256-1)));
                        trans_img(ii,jj)=trans_img(ii,jj)-uint8(1);
                    end
                end
            end
        end
    otherwise
        error('illegal parameter');
end
end
function [odhs_img] = Zero_Histogram_Coding( gray_minId256,ori_img)
% 平移直方图
%   输出 平移后直方图；输入 最小灰度256刻度，最大灰度256刻度，原始图像，平移图像，平移模式（Coding/Decoding）
%预处理
odhs_img=ori_img;
[img_H,img_V]=size(ori_img);%图像长宽
for i=1:img_H
    for ii=1:img_V
        if(ori_img(i,ii)==(gray_minId256-1))
            odhs_img(i,ii)=0;
        end
    end
end
end
function [odhs_img] = Zero_Histogram_Decoding( gray_minId256,ori_img,Locatemap)
%预处理
if(isempty(Locatemap))
    odhs_img=ori_img;
else
odhs_img=ori_img;
for i=1:2:length(Locatemap)
    odhs_img(Locatemap(i),Locatemap(i+1))=gray_minId256-1;
end
end

end
function [img,msg_img] = Coding_Msg_To_Img( gray_minId256,gray_maxId256,msg_bits_len,msg_bits,img)
% Odhs方式编码嵌入信息到图片
%   输出 嵌入信息后图片 ；输入 最小灰度级256刻度，最大灰度级256刻度，二进制码流长度，二进制码流，待嵌入图片

msg_bits_flag=1;
[img_H,img_V]=size(img);%图像长宽
msg_bits_len=length(msg_bits);
msg_img=zeros(size(img));
if(gray_minId256<gray_maxId256)
    for ii=1:img_H
        for jj=1:img_V   %遍历像素
            if(msg_bits_flag>msg_bits_len) %判断嵌入是否完成
                break;
            end
            if(img(ii,jj)==(gray_maxId256-1)) %判断是否为峰值像素
                if(msg_bits(msg_bits_flag)==1) %判断嵌入信息
                    img(ii,jj)=img(ii,jj)-uint8(1);
                    msg_img(ii,jj)=img(ii,jj)-uint8(1);
                end
                msg_bits_flag=msg_bits_flag+1;
            end
        end
    end
end
clear ii jj;
if(gray_minId256>gray_maxId256)
    for ii=1:img_H
        for jj=1:img_V   %遍历像素
            if(msg_bits_flag>msg_bits_len) %判断嵌入是否完成
                break;
            end
            if(img(ii,jj)==(gray_maxId256-1)) %判断是否为峰值像素
                if(msg_bits(msg_bits_flag)==1) %判断嵌入信息
                    img(ii,jj)=img(ii,jj)+uint8(1);
                    msg_img(ii,jj)=img(ii,jj)+uint8(1);
                    
                end
                msg_bits_flag=msg_bits_flag+1;
            end
        end
    end
end
clear ii jj;

end
function [msg_bits,img] = Decoding_Img_To_Msg( gray_minId256,gray_maxId256,msg_bits_len,img)
% Odhe方式解码嵌入信息图片与信息分离
%   输出 信息二进制码流，分离信息后图片；输入 最小灰度级256刻度，最大灰度级256刻度，二进制码流长度，嵌入信息图片

msg_bits_flag=1;
[img_H,img_V]=size(img);%图像长宽

msg_bits=zeros(1,msg_bits_len);
if(gray_minId256<gray_maxId256)
    for ii=1:img_H
        for jj=1:img_V   %遍历像素
            if(msg_bits_flag>msg_bits_len)
                break;
            end
            if(img(ii,jj)==(gray_maxId256-1)) %判断是否为0
                msg_bits(msg_bits_flag)=0;
                msg_bits_flag=msg_bits_flag+1;
            end
            if(img(ii,jj)==(gray_maxId256-1-1)) %判断是否为1
                msg_bits(msg_bits_flag)=1;
                img(ii,jj)=img(ii,jj)+uint8(1);
                msg_bits_flag=msg_bits_flag+1;
            end
        end
    end
end
clear ii jj;
if(gray_minId256>gray_maxId256)
    for ii=1:img_H
        for jj=1:img_V   %遍历像素
            if(msg_bits_flag>msg_bits_len)
                break;
            end
            if(img(ii,jj)==(gray_maxId256-1)) %判断是否为0
                msg_bits(msg_bits_flag)=0;
                msg_bits_flag=msg_bits_flag+1;
            end
            if(img(ii,jj)==(gray_maxId256-1+1)) %判断是否为1
                msg_bits(msg_bits_flag)=1;
                img(ii,jj)=img(ii,jj)-uint8(1);
                msg_bits_flag=msg_bits_flag+1;
            end
        end
    end
end
clear ii jj;

end
function [] = Generate_Result_Coding( gray_minId256,gray_maxId256,msg_bits_len,odhs_lena )
% 输出Odhs编码结果文件
%   输出 ；输入 最小灰度级256刻度，最大灰度级256刻度，二进制码流长度，待嵌入信息文件
[curProg_path,~]=Get_curPath();
dec_para=[gray_minId256,gray_maxId256,msg_bits_len];
fp=fopen([curProg_path,'\','ODHS','\','Result','\','para_coding.txt'],'w+','n','UTF-8');
fprintf(fp,'%d ',dec_para);
fclose(fp);
imwrite(odhs_lena,[curProg_path,'\','ODHS','\','Result','\','secret_lena_coding.bmp'],'bmp');
end
function [] = Generate_Result_Decoding( msgStr,img) 
    % 输出Odhs解码结果文件
    %   输出 ；输入 信息字符串，待解码文件
    
    %生成秘密信息
    [curProg_path,~]=Get_curPath();
    fp=fopen([curProg_path,'\','ODHS','\','\','Result','\','msg_decoding.txt'],'w+','n','UTF-8');
    fprintf(fp,'%s',msgStr);
    fclose(fp);
    
    %生成还原图片
    imwrite(img,[curProg_path,'\','ODHS','\','\','Result','\','ori_lena_decoding.bmp'],'bmp');
end
function [gray_minId256,gray_maxId256,msg_bits_len ] =Get_Para_By_File( path)
% 获取Odhs的文件的参数
%   输出 最小灰度级256刻度，最大灰度级256刻度，二进制码流长度；输入 文件路径 
para_file=fopen(path,'r');
read_data=textscan(para_file,'%d,%d,%d');
gray_minId256=read_data{1};
gray_maxId256=read_data{2};
msg_bits_len=read_data{3};
fclose(para_file);

end
function [ori_gray_cnts,gray_minId256,gray_maxId256,overhead_info_len,msg] =Preprocess(ori_img,msg,data_type,overload_solution)
% 获取Odhs的文件的参数
%   输出 最小灰度级256刻度，最大灰度级256刻度，二进制码流长度；输入 文件路径 

%%收集信息
ori_gray_cnts=Init_Gray_Cnts(ori_img);%取灰度
[ gray_minId256,gray_maxId256,overhead_info_flag] = Get_MinMax_Gray_Id256_cnts( ori_gray_cnts);%取峰值点零值点
[overhead_info,overhead_info_len,gray_minId256]=Get_Overhead_Info(ori_img,1,256);%取开销
msg_pak=[overhead_info,msg];
if(IsOverload(msg_pak,ori_img,data_type))%超容判断
    msg_paks=Overload(msg_pak,ori_img,data_type,overload_solution);
else
    msg_paks=msg_pak;
end%选取字符存储方式默认ASCII8bit
msg=msg_paks;

end
function [ori_msg,Locatemap] =Get_Locatemap(msg_pak,overhead_info_len)
% 获取Odhs的文件的参数
%   输出 最小灰度级256刻度，最大灰度级256刻度，二进制码流长度；输入 文件路径 
if(overhead_info_len==0)
Locatemap=[];
ori_msg=msg_pak;
else
Locatemap=msg_pak(1:overhead_info_len);
ori_msg=msg_pak(overhead_info_len+1:end);
end
end



