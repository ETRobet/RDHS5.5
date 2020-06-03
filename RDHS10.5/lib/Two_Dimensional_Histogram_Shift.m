function TDHS=Two_Dimensional_Histogram_Shift
%%输入
TDHS.getParaByFile=@Get_Parameter_By_File;%从文件获取参数
%%图像数据预处理与还原
TDHS.getOverheadInfo=@Get_overheadInfo;%获取预处理聚拢图像的坐标数据
TDHS.getEmbedInfo=@Get_EmbedInfo;%包装数据 总长度+标志位+坐标数据长度+坐标数据+数据
TDHS.extractPreprocessImg=@Extract_Preprocess_Img;%还原预处理图像和信息
%%图像分面
TDHS.getHalfPlane=@Get_Half_Plane;%划分棋盘格
%TDHS.getBlock=@Get_Block;%未实现占位
%%构建二维直方图
TDHS.getPD1=@Get_Prediction_Difference1;%获取dw1 4邻域预测差值
TDHS.getPD2=@Get_Prediction_Difference2;%获取dw2 2邻域预测差值
TDHS.getPDpair=@Get_Prediction_Difference_Pair;%获取预测差值对（即二维直方图坐标）
TDHS.getTDHS=@Get_TDHS;%二维直方图和数组从1开始的迁移量
%%嵌入参数收集
TDHS.getEODH=@Get_Embeddable_One_Dimensional_Histogram;%依据信道降维的一维直方图
TDHS.getPeakPixel=@Get_Peak_Pixel;%获取峰值点集合
%%嵌入信息  还原信息
TDHS.embedTranslationODHS=@Embed_Translation_ODHS;%平移一维直方图演示用
TDHS.embedTranslation=@Embed_Translation;%嵌入前平移留出嵌入空位
TDHS.extractTranslation=@Extract_Translation;%还原信息修复嵌入空位
TDHS.getPDPairToPixelMap=@Get_PDPair_To_Pixel_Map;%获取预测差值对到点坐标的映射
TDHS.embedInfo=@Embed_Information;%嵌入信息
TDHS.extractInfo=@Extract_Information;%还原信息
end
function [peakleft_pixels,peakright_pixels,ECs]=Get_Parameter_By_File(path)
%输出：左峰值点集合 右峰值点集合 嵌入信道集合
%输入：文件路径
data=dlmread(path);
data_len=length(data);
num=data_len/3;%每三个值划分一次
peakleft_pixels=cell(num,1);%集合结构：pixels→pixel→cnt;id;x;y
peakright_pixels=cell(num,1);
ECs=[];
data_cnt=1;
for i=1:num
    coord.x=data(data_cnt);
    coord.id=data(data_cnt);
    coord.y=data(data_cnt)-data(data_cnt+2);
    peakleft_pixels{i}=coord;
    data_cnt=data_cnt+1;
    coord.x=data(data_cnt);
    coord.id=data(data_cnt);
    coord.y=data(data_cnt)-data(data_cnt+1);
    peakright_pixels{i}=coord;
    data_cnt=data_cnt+1;
    ECs(i)=data(data_cnt);
    data_cnt=data_cnt+1;
end
end
function [ori_img2,ext_bin,ext_bin_len]=Get_overheadInfo(ori_img)
%输出：聚拢后的图像 附加信息 附加信息长度
%输入原始图像
%溢出标志位  （0不溢出 除了溢出位不再有额外信息；为1溢出根据预留的下溢坐标长度位和上溢坐标长度位判断）

[img_H,img_V]=size(ori_img);
ori_img_gray_cnts=Init_Gray_Cnts(ori_img);
underflow_bin_num=ori_img_gray_cnts(1);%统计灰度为0
overflow_bin_num=ori_img_gray_cnts(256);%统计灰度为255
%遍历下溢点 得坐标 预处理图像
switch underflow_bin_num
    case 0
        underflow_bin_flag=0;
    otherwise
        underflow_bin_flag=1;
        underflow_coords=cell(underflow_bin_num,1);
        coord.x=0;
        coord.y=0;
        cnt=1;
        for ii=1:img_H
            for jj=1:img_V
                if(ori_img(ii,jj)==0)
                    coord.x=ii;
                    coord.y=jj;
                    underflow_coords{cnt}=coord;
                    ori_img(ii,jj)=1;
                    cnt=cnt+1;
                end
            end
        end
end
%遍历上溢点 得坐标 预处理图像
switch overflow_bin_num
    case 0
        overflow_bin_flag=0;
    otherwise
        overflow_bin_flag=1;
        overflow_coords=cell(overflow_bin_num,1);
        coord.x=0;
        coord.y=0;
        cnt=1;
        for ii=1:img_H
            for jj=1:img_V
                if(ori_img(ii,jj)==255)
                    coord.x=ii;
                    coord.y=jj;
                    overflow_coords{cnt}=coord;
                    ori_img(ii,jj)=254;
                    cnt=cnt+1;
                end
            end
        end
end
ori_img2=ori_img;%输出预处理后图像
%计算数据包各项长度 包装
%数据组成：全数据长度+溢出标志位+坐标数据长度+下溢坐标数据+上溢坐标数据+真实数据（其中全数据长度的封装在EmbedInfo函数中）
coord_bin_len=16;%预留溢出坐标长度位(默认16位)(由underflow_bin_len，overflow_bin_len共占用16*2) 
coord_bin_num=max(length(de2bi(img_H)),length(de2bi(img_V))); %每个x or y坐标使用的长度位
ext_coords_num=underflow_bin_num+overflow_bin_num;%下溢上溢点总数
ext_bin=zeros(1,2*ext_coords_num*coord_bin_num+1);%初始化总数据

switch ext_coords_num
    case 0
    %无溢出坐标
        ext_bin(1)=0;%溢出标志位置0
        ext_bin_len=1;
    otherwise
    %有溢出坐标
       %转换二进制；上下溢出存取顺序：先下溢 后上溢 坐标存取顺序：先x 后y
        ext_bin(1)=1;%溢出标志位置1
        ext_cnt=2;
        %遍历下溢
        for underflow_cnt=1:underflow_bin_num
            tempbinX=de2bi(underflow_coords{underflow_cnt}.x);
            tempbinY=de2bi(underflow_coords{underflow_cnt}.y);
            for ii=1:coord_bin_num
                ext_bin(ext_cnt)=tempbinX(ii);
                ext_cnt=ext_cnt+1;
            end
            for ii=1:coord_bin_num
                ext_bin(ext_cnt)=tempbinY(ii);
                ext_cnt=ext_cnt+1;
            end
        end
        %遍历上溢
        for overflow_cnt=1:overflow_bin_num
            tempbinX=de2bi(overflow_coords{overflow_cnt}.x);
            tempbinY=de2bi(overflow_coords{overflow_cnt}.y);
            for ii=1:coord_bin_num
                ext_bin(ext_cnt)=tempbinX(ii);
                ext_cnt=ext_cnt+1;
            end
            for ii=1:coord_bin_num
                ext_bin(ext_cnt)=tempbinY(ii);
                ext_cnt=ext_cnt+1;
            end
        end
        %
        ext_bin_len=2*ext_coords_num*coord_bin_num+1;%输出数据总长度
        
        ext_coord_bin_len=2*ext_coords_num*coord_bin_num;%纯坐标数据长度
        underflow_bin_len_bin=de2bi(underflow_bin_num*coord_bin_num*2);%计算下溢二进制数据长度
        overflow_bin_len_bin=de2bi(overflow_bin_num*coord_bin_num*2);%计算上溢二进制数据长度
        ext_coord_bin_len_bin=de2bi(ext_coord_bin_len);%计算溢出坐标二进制数据长度
        %包装额外信息
        if(ext_coord_bin_len_bin~=0)
            temp=ext_bin;
            ext_bin=[];
            ext_bin(1)=1;
            for i=1:length(underflow_bin_len_bin)
            ext_bin(end+1)=ext_coord_bin_len_bin(i);
            end
            while(length(ext_bin)~=coord_bin_len+1)
                ext_bin(end+1)=0;
            end
            for i=1:length(overflow_bin_len_bin)
                ext_bin(end+1)=ext_coord_bin_len_bin(i);
            end
            while(length(ext_bin)~=coord_bin_len+1)
                ext_bin(end+1)=0;
            end
            for ii=2:length(temp)
                ext_bin(end+1)=temp(ii);
            end
        end
end
end
function [embed_bin,embed_bin_len]=Get_EmbedInfo(ori_bin,ext_bin,bit_len)
%输出：最终嵌入信息，嵌入信息长度
%输入：原始信息，附加信息，预留总数据长度位
ori_bin_len=length(ori_bin);
ext_bin_len=length(ext_bin);
embed_bin_len=ori_bin_len+ext_bin_len;
embed_bin=zeros(1,embed_bin_len);
embed_bin_cnt=1;
%包装额外信息与原始信息
for ii=1:ext_bin_len
    embed_bin(embed_bin_cnt)=ext_bin(ii);
    embed_bin_cnt=embed_bin_cnt+1;
end
for jj=1:ori_bin_len
    embed_bin(embed_bin_cnt)=ori_bin(jj);
    embed_bin_cnt=embed_bin_cnt+1;
end
embed_bin_len=length(embed_bin);
%创建数据长度头
overhead_embed_len=embed_bin_len+bit_len;
overhead=de2bi(overhead_embed_len);
overhead_len=length(overhead);
overhead_embed_bin=[];
for i=1:bit_len
    if(i<=overhead_len)
        overhead_embed_bin(i)=overhead(i);
    else
        overhead_embed_bin(i)=0;
    end
end
%包装数据
for i=1:embed_bin_len
    overhead_embed_bin(i+bit_len)=embed_bin(i);
end
%输出信息
embed_bin=overhead_embed_bin;
embed_bin_len=length(embed_bin);
end
function [ori_img,ori_msg]=Extract_Preprocess_Img(preprocess_img,recoverd_preprocess_msg,overheadflag)
%输出：提取还原图像 提取还原信息
%输入：被预处理过图像（被聚拢），被预处理的信息（无总数据长度） 溢出标志位
if(overheadflag==0)
    ori_img=preprocess_img;
    ori_msg=recoverd_preprocess_msg(2:end);
else
    %分离坐标与原信息
    [img_H,img_V]=size(preprocess_img);
    coord_bin_len=16;%坐标长度占用位数
    coord_bin_num=max(length(de2bi(img_H)),length(de2bi(img_V)));%单坐标占用位数
    underflow_bin_len=bi2de(recoverd_preprocess_msg(2:coord_bin_len+1));
    overflow_bin_len=bi2de(recoverd_preprocess_msg(coord_bin_len+2:coord_bin_len*2+1));
    underflow_bin=recoverd_preprocess_msg(coord_bin_len*2+1+1: coord_bin_len*2+1+ underflow_bin_len);
    overflow_bin=bi2de(recoverd_preprocess_msg(underflow_bin_len+coord_bin_len*2+1+1:coord_bin_len*2+1+overflow_bin_len+underflow_bin_len));
    %遍历下溢上溢提取坐标并还原
    for i=1:underflow_bin_len
        tempx=[];
        tempy=[];
        for j=1:coord_bin_num
            tempx(end+1)=underflow_bin(j+(i-1)*coord_bin_num*2);
        end
        for jj=1:coord_bin_num
            tempy(end+1)=underflow_bin(j+coord_bin_num+(i-1)*coord_bin_num*2);
        end
        preprocess_img(tempx,tempy)=0;
    end
    for ii=1:overflow_bin_len
        tempx=[];
        tempy=[];
        for j=1:coord_bin_num
            tempx(end+1)=overflow_bin(j+(i-1)*coord_bin_num*2);
        end
        for jj=1:coord_bin_num
            tempy(end+1)=overflow_bin(j+coord_bin_num+(i-1)*coord_bin_num*2);
        end
        preprocess_img(tempx,tempy)=255;
    end
    ori_msg=recoverd_preprocess_msg(1+coord_bin_len*2+underflow_bin_len+overflow_bin_len+1:end);
    ori_img=preprocess_img;
end
end
function [plane1,plane2,plane1_len,plane2_len]=Get_Half_Plane(img)
%输出：半平面1，半平面2，半平面1长度，半平面2长度   （半平面结构：plane→pixel→x,y） 
%输入：待划分图像
%顺序从左到右 从上到下 plane1首元素为1，1
[img_H,img_V]=size(img);
plane1_len=0;
plane2_len=0;
%计算半平面点个数
for i=1:img_H
    odd_flag=mod(i,2);%判定奇偶性
    switch odd_flag
        case 1
            plane1_len=plane1_len+ceil(img_V/2);
            plane2_len=plane2_len+floor(img_V/2);
        case 0
            plane1_len=plane1_len+floor(img_V/2);
            plane2_len=plane2_len+ceil(img_V/2);
    end
end
%初始化半平面结构体
plane1=cell(plane1_len,1);
plane2=cell(plane2_len,1);
coord.x=0;
coord.y=0;
plane1_cnt=1;
plane2_cnt=1;
pixel_cnt=1;
even_flag=mod(img_V,2);
even_switch=1;
%判断奇偶划分
switch even_flag
    case 1%为奇数列
        for ii=1:img_H
            for jj=1:img_V
                coord.x=ii;
                coord.y=jj;
                odd_flag=mod(pixel_cnt,2);
                switch odd_flag
                    case 1
                        plane1{plane1_cnt}=coord;
                        plane1_cnt=plane1_cnt+1;
                    case 0
                        plane2{plane2_cnt}=coord;
                        plane2_cnt=plane2_cnt+1;
                end
                pixel_cnt=pixel_cnt+1;
            end
        end
    case 0%为偶数列
        for ii=1:img_H
            switch even_switch%每循环一次开关正负闭合 实现交叉
                case 1
                    for jj=1:img_V
                        coord.x=ii;
                        coord.y=jj;
                        odd_flag=mod(pixel_cnt,2);
                        switch odd_flag
                            case 1
                                plane1{plane1_cnt}=coord;
                                plane1_cnt=plane1_cnt+1;
                            case 0
                                plane2{plane2_cnt}=coord;
                                plane2_cnt=plane2_cnt+1;
                        end
                        
                        pixel_cnt=pixel_cnt+1;
                        
                    end
                case -1
                    for jj=1:img_V
                        coord.x=ii;
                        coord.y=jj;
                        odd_flag=mod(pixel_cnt,2);
                        switch odd_flag
                            case 1
                                plane2{plane2_cnt}=coord;
                                plane2_cnt=plane2_cnt+1;
                                
                            case 0
                                plane1{plane1_cnt}=coord;
                                plane1_cnt=plane1_cnt+1;
                                
                        end
                        pixel_cnt=pixel_cnt+1;
                        
                    end
            end
            even_switch=-even_switch;
        end
end
end
function [dw1]=Get_Prediction_Difference1(img,coord)
%输出：四邻域预测差值
%输入：图像，预测坐标
%四邻域预测
[img_H,img_V]=size(img);
valid_cnt=4;
%既四个邻域皆无不可能情况  故不用考虑 考虑除数为0
if(coord.x==1)%无up
    up=0;
    valid_cnt=valid_cnt-1;
else
    up=img(coord.x-1,coord.y);
end
if(coord.x==img_H)%无down
    down=0;
    valid_cnt=valid_cnt-1;
else
    down=img(coord.x+1,coord.y);
end
if(coord.y==1)%无left
    left=0;
    valid_cnt=valid_cnt-1;
else
    left=img(coord.x,coord.y-1);
end
if(coord.y==img_V)%无right
    right=0;
    valid_cnt=valid_cnt-1;
else
    right=img(coord.x,coord.y+1);
end
dw1=img(coord.x,coord.y)-...
    floor((up+down+left+right)/valid_cnt);
%disp(sprintf('%d-(%d+%d+%d+%d)/%d=%d',img(coord.x,coord.y),up,down,left,right,valid_cnt,dw1));
end
function [dw2]=Get_Prediction_Difference2(img,coord)
%输出：二邻域预测差值
%输入：图像，预测坐标
%二邻域预测
[img_H,~]=size(img);
valid_cnt=2;
%既无down也无left 要考虑除数为0（valid_cnt）
if(coord.x==img_H&&coord.y==1)
    dw2=img(coord.x,coord.y);
else
    if(coord.x==img_H)%无down
        down=0;
        valid_cnt=valid_cnt-1;
    else
        down=img(coord.x+1,coord.y);
        
    end
    if(coord.y==1)%无left
        left=0;
        valid_cnt=valid_cnt-1;
    else
        left=img(coord.x,coord.y-1);
    end
    dw2=img(coord.x,coord.y)-...
    floor((down+left)/valid_cnt);
end
end
function [PDpairs]=Get_Prediction_Difference_Pair(img,plane)
%输出：预测差值对  （结构：PDpairs→pd1，pd2）
%输入：图像，坐标集
plane_len=length(plane);
PDpairs=cell(plane_len,1);
tempdw.dw1=0;
tempdw.dw2=0;

for i=1:plane_len
    tempdw.dw1=Get_Prediction_Difference1(img,plane{i});
    tempdw.dw2=Get_Prediction_Difference2(img,plane{i});
    PDpairs{i}=tempdw;
end

end
function [H,axisincr,minaxis2,maxaxis2]=Get_TDHS(dws)
%计算最小坐标最大坐标平移坐标轴
minaxis=min(dws{1}.dw1,dws{1}.dw2);
maxaxis=max(dws{1}.dw1,dws{1}.dw2);
for i=1:length(dws)
    minaxis=min(minaxis,min(dws{i}.dw1,dws{i}.dw2));
    
    maxaxis=max(maxaxis,max(dws{i}.dw1,dws{i}.dw2));
    
end

axisincr=1-minaxis;%平移像素原始零点（0，0）变为（axisincr，axisincr）
for i=1:length(dws)
    dws{i}.dw1=dws{i}.dw1+axisincr;
    dws{i}.dw2=dws{i}.dw2+axisincr;
end
minaxis2=minaxis+axisincr;
maxaxis2=maxaxis+axisincr;

H=zeros(maxaxis2,maxaxis2);

for i=1:length(dws)
    H(dws{i}.dw1,dws{i}.dw2)= H(dws{i}.dw1,dws{i}.dw2)+1;
end

end
function [ODHs]=Get_Embeddable_One_Dimensional_Histogram(H,ECs)
%构造H时为最大正方形 故遍历使用length（H）
len=length(H);
ODHs=cell(length(ECs),1);
ODHs_cnt=1;
for ec_cnt=1:length(ECs)
    ec=ECs(ec_cnt);
    ODH=zeros(1,len);
    for ii=1:len
        for jj=1:len
            if((ii-jj)==ec)
                ODH(1,ii)=H(ii,jj);
            end
        end
    end
    ODHs{ODHs_cnt}=ODH;
    ODHs_cnt=ODHs_cnt+1;
end
end
function [peakleft_pixels,peakright_pixels,capacity]=Get_Peak_Pixel(ODHs,ECs)
%输出：左峰值点集，右峰值点集，最大容量 （结构：pixels→pixel→cnt，id，x，y）
%输入：一维直方图集合，嵌入信道集合
ODHs_len=length(ODHs);
peakleft_pixels=cell(ODHs_len,1);
peakright_pixels=cell(ODHs_len,1);
capacity=0;%总容量
%遍历一维直方图
for i=1:ODHs_len
    temp_ODH=ODHs{i};
    min_cnt=min(temp_ODH);
    %第一峰值点
    [temp1.cnt,temp1.id]=max(temp_ODH);
    temp1.x=temp1.id;
    temp1.y=temp1.id-ECs(i);
    temp_ODH(temp1.id)=min_cnt;%把已经找过的峰值设为最小值
    %第二峰值点
    [temp2.cnt,temp2.id]=max(temp_ODH);
    temp2.x=temp2.id;
    temp2.y=temp2.id-ECs(i);
    capacity=temp1.cnt+temp2.cnt+capacity;%总容量
    
    %按对应横坐标左大右小放置
    if(temp1.id<temp2.id)
        peakleft_pixels{i}=temp1;
        peakright_pixels{i}=temp2;
    else
        peakleft_pixels{i}=temp2;
        peakright_pixels{i}=temp1;
    end
end


end
function [trans_ODHs]=Embed_Translation_ODHS(ODHs,peakleft_pixels,peakright_pixels)
%输出：平移后的一维直方图集合
%输入：一维直方图集合，左峰值点集，右峰值点集
%位于信道且小于左峰值点的ODH左移
%位于信道且大于右峰值点的ODH右移
%初始化trans_ODHs
trans_ODHs=cell(length(ODHs),1);
for i=1:length(ODHs)
    trans_ODH=zeros(length(ODHs{i})+2);
    for ii=1:length(ODHs{i})
        trans_ODH(ii+1)=ODHs{i}(ii);
    end
    trans_ODHs{i}=trans_ODH;
end
%遍历ODH内点 平移ODHs
for k=1:length(trans_ODHs)
    for i=1:peakleft_pixels{k}.id-1
        %修改ODH
        trans_ODHs{k}(i)=trans_ODHs{k}(i+1);
    end
    for ii=length(trans_ODH):-1:peakright_pixels{k}.id+1
        trans_ODHs{k}(ii)=trans_ODHs{k}(ii-1);
    end
end
end
function [trans_img]=Embed_Translation(img,H,peakleft_pixels,peakright_pixels,ECs,PDP2PixelMap)
%输出：图像平移准备嵌入
%输入：图像，预测差值对分布图，左峰值点集合，右峰值点集合，可嵌入信道集合，预测差值对到点坐标的映射集合
%位于信道且小于左峰值点的 TDH不变 图像像素减1
%位于信道且大于右峰值点的 TDH不变 图像像素加1

%遍历原始H 平移trans_H和trans_img
%初始化 trans_H trans_img
trans_img=img;
H_len=length(H);
for k=1:length(ECs)
    for i=1:H_len
        for ii=1:H_len
            if ((i-ii)==ECs(k)&&i<peakleft_pixels{k}.id)
                %修改像素
                pixels=PDP2PixelMap{i,ii};
                pixels_len=length(pixels);
                if(i==51&&ii==51)
                disp('wait');
                end
                for j=1:pixels_len
                    if(pixels{j}.x==1&&pixels{j}.y==15)
                   fprintf('[%d,%d] %d→%d\n',pixels{j}.x,pixels{j}.y,rans_img(pixels{j}.x,pixels{j}.y),rans_img(pixels{j}.x,pixels{j}.y)-1);
                    end
                    trans_img(pixels{j}.x,pixels{j}.y)= ...
                        trans_img(pixels{j}.x,pixels{j}.y)-1;
                      %fprintf('C%d %d 减一\n',pixels{j}.x,pixels{j}.y);
                end
            elseif ((i-ii)==ECs(k)&&i>peakright_pixels{k}.id)
                %修改像素
                pixels=PDP2PixelMap{i,ii};
                pixels_len=length(pixels);
                for j=1:pixels_len
                    if(pixels{j}.x==1&&pixels{j}.y==15)
               fprintf('[%d,%d] %d→%d\n',pixels{j}.x,pixels{j}.y,rans_img(pixels{j}.x,pixels{j}.y),rans_img(pixels{j}.x,pixels{j}.y)+1);
                    end
                    trans_img(pixels{j}.x,pixels{j}.y)=...
                        trans_img(pixels{j}.x,pixels{j}.y)+1;
                     %fprintf('C%d %d 加一\n',pixels{j}.x,pixels{j}.y);
                end
            end
        end
    end
end

end
function [trans_img]=Extract_Translation(img,H,peakleft_pixels,peakright_pixels,ECs,PDP2PixelMap)

%输出：平移图像还原
%输入：图像，预测差值对分布图，左峰值点集合，右峰值点集合，可嵌入信道集合，预测差值对到点坐标的映射集合

%位于信道且小于左峰值点的 TDH不变 图像像素加1
%位于信道且大于右峰值点的 TDH不变 图像像素减1

%遍历原始H 平移trans_H和trans_img
%初始化 trans_H trans_img
trans_img=img;
H_len=length(H);
for k=1:length(ECs)
    for i=1:H_len
        for ii=1:H_len
            if ((i-ii)==ECs(k)&&i<peakleft_pixels{k}.id)
                %修改像素
                pixels=PDP2PixelMap{i,ii};
                pixels_len=length(pixels);
                for j=1:pixels_len
                    trans_img(pixels{j}.x,pixels{j}.y)= ...
                        trans_img(pixels{j}.x,pixels{j}.y)+1;
                    %fprintf('E%d %d 加一\n',pixels{j}.x,pixels{j}.y);
                end
            elseif ((i-ii)==ECs(k)&&i>peakright_pixels{k}.id)
                %修改像素
                pixels=PDP2PixelMap{i,ii};
                pixels_len=length(pixels);
                for j=1:pixels_len
                    trans_img(pixels{j}.x,pixels{j}.y)=...
                        trans_img(pixels{j}.x,pixels{j}.y)-1;
                    %fprintf('E%d %d 减一\n',pixels{j}.x,pixels{j}.y);
                end
            end
        end
    end
end

end
function [PDP2PixelMap]=Get_PDPair_To_Pixel_Map(ori_img2,plane1,H,axisincr)
%输出：预测差值对到点坐标的映射集合  （结构：PDP2PixelMap{?,?}→pixels{?}→pixel→x,y）
%输入：图像，坐标集合，预测差值对分布图，迁移量
H_len=length(H);
PDP2PixelMap=cell(H_len,H_len);
plane1_len=length(plane1);
for i=1:plane1_len
    tempdw.dw1=Get_Prediction_Difference1(ori_img2,plane1{i})+axisincr;
    tempdw.dw2=Get_Prediction_Difference2(ori_img2,plane1{i})+axisincr;
   %{
    if(plane1{i}.x==1&&plane1{i}.y==15)
    fprintf('[%d,%d] e1:%d e2:%d',plane1{i}.x,plane1{i}.y,tempdw.dw1,tempdw.dw2);
    end
    %}
    if(isempty(PDP2PixelMap{tempdw.dw1,tempdw.dw2}))%如果当前映射无值则新建一个cell结构体准备存放点集合
        pixels=cell(1,1);
        pixels{1}=plane1{i};
        PDP2PixelMap{tempdw.dw1,tempdw.dw2}=pixels;
    else
        PDP2PixelMap{tempdw.dw1,tempdw.dw2}{end+1}=plane1{i};
    end
end
end
function [marked_img]=Embed_Information(img,msg,peakleft_pixels,peakright_pixels,ECs,plane,axisincr)
%输出：嵌入后的图像
%输入：图像,信息，左峰值点集合，右峰值点集合，可嵌入信道结合，坐标集合，迁移量
%从小到大遍历可嵌入 直到嵌入位置满或信息结束
%可嵌入空间对应着预测值差对应的像素多少
marked_img=img;
msg_cnt=1;
msg_len=length(msg);
for k=1:length(ECs)
    EC=ECs(k);
    for i=1:length(plane)
        %像素转差值对
        e1=Get_Prediction_Difference1(img,plane{i})+axisincr;
        e2=Get_Prediction_Difference2(img,plane{i})+axisincr;
        %差值对比较信息
        p1=peakleft_pixels{k}.x;
        p2=peakright_pixels{k}.x;
        imgx=plane{i}.x;
        imgy=plane{i}.y;
        if(imgx==1&&imgy==15)
            flag=1;
        end
        if(e2==e1-EC)
            %disp('e2=e1-EC');
                if(e1==p1)
                    if(msg_cnt>msg_len)
                        break;
                    else
                        incr=msg(msg_cnt);
                    end                    
                    fprintf('%d嵌入%d:[%d,%d]\t  %d→%d\t  信道%d\t e1:%d p1:%d p2:%d\t\n',msg_cnt,incr,imgx,imgy,marked_img(imgx,imgy),marked_img(imgx,imgy)-incr,EC,e1,p1,p2);
                    marked_img(imgx,imgy)=marked_img(imgx,imgy)-incr;
                    msg_cnt=msg_cnt+1;
                end
                if(e1==p2)
                    if(msg_cnt>msg_len)
                        break;
                    else
                        incr=msg(msg_cnt);
                    end
                    fprintf('%d嵌入%d:[%d,%d]\t  %d→%d\t  信道%d\t e1:%d p1:%d p2:%d\t\n',msg_cnt,incr,imgx,imgy,marked_img(imgx,imgy),marked_img(imgx,imgy)+incr,EC,e1,p1,p2);
                    marked_img(imgx,imgy)=marked_img(imgx,imgy)+incr;
                    msg_cnt=msg_cnt+1;
                end
        end
    end
end
end
function [recoverd_msg,recoverd_img,overflow_flag]=Extract_Information(img,peakleft_pixels,peakright_pixels,ECs,plane,axisincr,bit_len)
%输出：还原信息，还原图像
%输入：图像，左峰值点集合，右峰值点集合，可嵌入信道集合，坐标集合，迁移量，预留数据长度位
%从小到大遍历可嵌入 依据新生成的预测值+-1与左右峰值点进行提取
%可嵌入空间对应着预测值差对应的像素多少
recoverd_img=img;
clip_flag=0;%%对数据裁剪标志位 静态变量
msg=[];
msg_cnt=1;
max_cnt=bit_len+2;
msg_max=3;
for k=1:length(ECs)
    EC=ECs(k);
    for i=1:length(plane)
        %像素转差值对
        e1=Get_Prediction_Difference1(img,plane{i})+axisincr;
        e2=Get_Prediction_Difference2(img,plane{i})+axisincr;
        %差值对比较信息
        p1=peakleft_pixels{k}.x;
        p2=peakright_pixels{k}.x;
        imgx=plane{i}.x;
        imgy=plane{i}.y;
        if(msg_cnt>max_cnt)
            break;
        end
        if(e2==e1-EC)
            if(e1==p1)
                fprintf('%d提取0:[%d,%d]\t  %d→%d\t  信道%d\t e1:%d p1:%d p2:%d\t\n',...
                    msg_cnt,imgx,imgy,recoverd_img(imgx,imgy),recoverd_img(imgx,imgy),EC,e1,p1,p2);
                recoverd_img(imgx,imgy)=recoverd_img(imgx,imgy);
                msg(msg_cnt)=0;
                msg_cnt=msg_cnt+1;
            end
            if(e1==p2)
                fprintf('%d提取0:[%d,%d]\t  %d→%d\t  信道%d\t e1:%d p1:%d p2:%d\t\n',...
                    msg_cnt,imgx,imgy,recoverd_img(imgx,imgy),recoverd_img(imgx,imgy),EC,e1,p1,p2);
                recoverd_img(imgx,imgy)=recoverd_img(imgx,imgy);
                msg(msg_cnt)=0;
                msg_cnt=msg_cnt+1;
            end
            if(e1==p1-1)
                fprintf('%d提取1:[%d,%d]\t  %d→%d\t  信道%d\t e1:%d p1:%d p2:%d\t\n',...
                    msg_cnt,imgx,imgy,recoverd_img(imgx,imgy),recoverd_img(imgx,imgy)+1,EC,e1,p1,p2);
                recoverd_img(imgx,imgy)=recoverd_img(imgx,imgy)+1;
                msg(msg_cnt)=1;
                msg_cnt=msg_cnt+1;
                %fprintf('left%d %d 提取1\n',imgx,imgy);
            end
            if(e1==p2+1)
                fprintf('%d提取1:[%d,%d]\t  %d→%d\t  信道%d\t e1:%d p1:%d p2:%d\t\n',...
                    msg_cnt,imgx,imgy,recoverd_img(imgx,imgy),recoverd_img(imgx,imgy)-1,EC,e1,p1,p2);
                recoverd_img(imgx,imgy)=recoverd_img(imgx,imgy)-1;
                msg(msg_cnt)=1;
                msg_cnt=msg_cnt+1;
                %fprintf('right%d %d 提取1\n',imgx,imgy);
            end
        end
        if(msg_cnt==17)
        end
                %导出数据头
        if(msg_cnt==bit_len+2&&clip_flag==0)
            clip_flag=1;
            overhead_len=bi2de(msg(1:bit_len));
            overflow_flag=msg(bit_len+1);
            max_cnt=overhead_len;
        end
    end
end
    %裁剪数据
    overhead=msg(1:bit_len);
    recoverd_msg=msg(bit_len+1:end);%此处recoverd_msg为预处理后的信息
end

