function TDHSce=Two_Dimensional_Histogram_Shift_Contrast_Enhancement
%主函数
TDHSce.mainCoding=@Main_Coding;%主要嵌入函数
TDHSce.mainDecoding=@Main_Decoding;%主要提取函数
%%图像数据预处理与还原
TDHSce.getMergeLocation=@Get_Merge_Location;%获取预处理合并位置：零值列行
TDHSce.getEmbedLocation=@Get_Embed_Location;%获取嵌入位置：峰值列行
TDHSce.extractEmbedLocation=@Extract_Embed_Location;%LSB提取：峰值列行
TDHSce.preprocessImg=@Preprocess_Img;%聚拢图像
TDHSce.preprocessData=@Preprocess_Data;%预处理数据 排除位置嵌入峰值行列 数据格式：总数据长度16bit+零值行列（包括零标志位4bit为1时再加坐标长度，坐标数据）+峰值还原信息+下次L+嵌入信息数据
TDHSce.extractPreprocessImg=@Extract_Preprocess_Img;%逆聚拢图像
TDHSce.extractPreprocessData=@Extract_Preprocess_Data;%逆预处理数据 还原排除位置
%%图像分面
TDHSce.getHalfPlane=@Get_Half_Plane;%划分面（左右一对）
TDHSce.getVaildHalfPlane=@Get_Vaild_Half_Plane;%获取有效面 ，排除一定面来LSB嵌入信息
%%构建二维直方图
TDHSce.getPD1=@Get_Prediction_Difference1;%获取dw1 当前像素值                  二维横轴 （函数名字不达意是为了兼容旧版）
TDHSce.getPD2=@Get_Prediction_Difference2;%获取dw2 当前像素的右边像素值  二维竖轴
TDHSce.getPDpair=@Get_Prediction_Difference_Pair;%组合坐标对（即二维直方图坐标）
TDHSce.getTDHS=@Get_TDHS;%二维直方图和数组  若矩阵过远与平移至【1，1】原点的总迁移量暂时不考虑二维图中心偏移统一为1
%%嵌入信息  还原信息
TDHSce.embedTranslation=@Embed_Translation;%嵌入前平移留出嵌入空位
TDHSce.extractTranslation=@Extract_Translation;%还原信息修复嵌入空位
TDHSce.getPDPairToPixelMap=@Get_PDPair_To_Pixel_Map;%获取直方图坐标到像素坐标的映射（用来按序访问用）
TDHSce.embedData=@Embed_Data;%嵌入信息
TDHSce.extractData=@Extract_Data;%还原信息

end
function [marked_img]=Main_Coding(img,bin,L)

%初始化参数
ori_img=img;
ori_bin=bin;
excluding_num=16;%排除位置数 

%划分处理面
[plane1]=Get_Half_Plane(ori_img);
[vaild_plane,excluding_plane]=Get_Vaild_Half_Plane(plane1,excluding_num);
%构建二维直方图
[PDpairs]=Get_Prediction_Difference_Pair(ori_img,vaild_plane);%plane1保存从1，1开始隔一个的像素坐标 奇数列则抛弃最后一列  通过对plane像素列加1获得右像素
[H,axisincr]=Get_TDHS(PDpairs);
%获取零值行列
[trans_zero_pixels]=Get_Merge_Location(H);
%用零值行列 聚拢图像
[preprocess_img,LocateMap]=Preprocess_Img(ori_img,trans_zero_pixels,vaild_plane,H,axisincr);
%更新二维直方图
[trans_PDpairs]=Get_Prediction_Difference_Pair(preprocess_img,vaild_plane);
[trans_H,trans_axisincr]=Get_TDHS(trans_PDpairs);%更新H
%获取峰值行列
[trans_peak_pixels]=Get_Embed_Location(trans_H);
%用峰值行列嵌入排除位置LSB 并生成还原信息  封装装数据，内容格式见函数
[embed_bin,preprocess_2rd_img]=Preprocess_Data(preprocess_img,ori_bin,LocateMap,excluding_plane,trans_zero_pixels,trans_peak_pixels,axisincr,L);%生成还原信息但不嵌入峰值信息
%生成二维直方图坐标与像素位置映射（函数名字不达意为了兼容旧版本）
[PDP2PixelMap]=Get_PDPair_To_Pixel_Map(preprocess_2rd_img,vaild_plane,H,axisincr);
%平移以空位 平移位置：左右上下共4块4线 左上左下右上右下共4角块8线 
[trans_preprocess_img]=Embed_Translation(preprocess_2rd_img,vaild_plane,trans_peak_pixels,axisincr,PDP2PixelMap);
%嵌入信息
[marked_img]=Embed_Data(trans_preprocess_img,embed_bin,vaild_plane,trans_peak_pixels,axisincr);

%输出二维直方图用
%{
figure;
mesh(double(H));
title('半平面1');
%}
end
function [ori_img,ori_bin,L]=Main_Decoding(marked_img)
%初始化参数
marked_img2=marked_img;
axisincr2=1;
excluding_num=16;

%划分嵌入面与排除面
[plane12]=Get_Half_Plane(marked_img2);
[vaild_plane2,excluding_plane2]=Get_Vaild_Half_Plane(plane12,excluding_num);
%排除位置LSB提取峰值行列
[trans_peak_pixels2]=Extract_Embed_Location(marked_img2,excluding_plane2);
%提取信息
[trans_preprocess_img2,embed_bin2]=Extract_Data(marked_img2,vaild_plane2,trans_peak_pixels2,axisincr2);
%获取二维直方图
[trans_PDpairs]=Get_Prediction_Difference_Pair(trans_preprocess_img2,vaild_plane2);
[H2,axisincr2]=Get_TDHS(trans_PDpairs);%更新H
%获取直方图坐标与像素位置映射
[PDP2PixelMap2]=Get_PDPair_To_Pixel_Map(trans_preprocess_img2,vaild_plane2,H2,axisincr2);
%平移还原
[preprocess_2rd_img2]=Extract_Translation(trans_preprocess_img2,vaild_plane2,trans_peak_pixels2,axisincr2,PDP2PixelMap2);
%解包预处理数据 还原排除位置信息
[ori_bin2,preprocess_img2,LocateMap2,trans_zero_pixels2,L]=Extract_Preprocess_Data(preprocess_2rd_img2,embed_bin2,excluding_plane2,axisincr2);
%逆聚拢图像
[ori_img2]=Extract_Preprocess_Img(preprocess_img2,LocateMap2,trans_zero_pixels2,vaild_plane2,axisincr2);
%输出
ori_img=ori_img2;
ori_bin=ori_bin2;

end
function [plane1,plane2,plane1_len,plane2_len]=Get_Half_Plane(img)
%输出：半平面1，半平面2，半平面1长度，半平面2长度   （半平面结构：plane→pixel→x,y）
%输入：待划分图像
%顺序从左到右 从上到下 plane1首元素为1，1
%奇偶行划分 plane1第一个   若偶数全排 若奇数 舍去最后一行
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
            for jj=1:img_V-1
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
                if(jj==img_V-1)
                    pixel_cnt=1;
                else
                    pixel_cnt=pixel_cnt+1;
                end
            end
        end
    case 0%为偶数列
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
end
end
function [vaild_plane,excluding_plane]=Get_Vaild_Half_Plane(plane,excluding_num)
ori_plane_len=length(plane);
vaild_plane_len=ori_plane_len-excluding_num;
if(vaild_plane_len<=0)
    vaild_plane=[];
    excluding_plane=plane;
else
    if(ori_plane_len==1)
        switch vaild_plane_len
            case 0
                vaild_plane=[];
                excluding_plane=plane;
            case 1
                vaild_plane=plane;
                excluding_plane=[];
            otherwise
                vaild_plane=[];
                excluding_plane=plane;
        end
    else
        vaild_plane=plane(1:vaild_plane_len);
        excluding_plane=plane(vaild_plane_len+1:ori_plane_len);
    end
end
end
function [dw1]=Get_Prediction_Difference1(img,coord)
%输出：coord的当前像素值
%输入：图像，坐标
dw1=img(coord.x,coord.y);
end
function [dw2]=Get_Prediction_Difference2(img,coord)
%输出：coord的当前右边像素值
%输入：图像，预测坐标
%二邻域预测
dw2=img(coord.x,coord.y+1);
end
function [PDpairs]=Get_Prediction_Difference_Pair(img,plane)

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
%暂不考虑矩阵中心偏移中心过远
%trans_pixels存储结果，上下左右像素
minaxis=min(dws{1}.dw1,dws{1}.dw2);
maxaxis=max(dws{1}.dw1,dws{1}.dw2);
for i=1:length(dws)
    minaxis=min(minaxis,min(dws{i}.dw1,dws{i}.dw2));
    maxaxis=max(maxaxis,max(dws{i}.dw1,dws{i}.dw2));
end
axisincr=1;%平移像素原始零点（0，0）变为（1，1）
for i=1:length(dws)
    dws{i}.dw1=dws{i}.dw1+axisincr;
    dws{i}.dw2=dws{i}.dw2+axisincr;
end
minaxis2=256;
maxaxis2=256;

H=zeros(maxaxis2,maxaxis2);

for i=1:length(dws)
    H(dws{i}.dw1,dws{i}.dw2)= H(dws{i}.dw1,dws{i}.dw2)+1;
end

end
function [trans_zero_pixels]=Get_Merge_Location(H)
%寻找少于128最小列 最小行  0~127 128~255   像素平移后 1~128 129~256
%遍历1~128x轴求和y轴  并选取最小值左零值点down_trans
trans_zero_pixels=cell(4,1);
temp=0;
mins=[];
for i=1:128
    for ii=1:256
        temp=temp+H(i,ii);
    end
    mins(end+1)=temp;
end
[left_trans_cnt,left_transId]=min(mins);
left_trans_Pixel.cnt=left_trans_cnt;
left_trans_Pixel.id=left_transId;
%遍历1~128y轴求和x轴 并选取最小值下零值点left_trans
temp=0;
mins=[];
for i=1:128
    for ii=1:256
        temp=temp+H(ii,i);
    end
    mins(end+1)=temp;
end
[down_trans_cnt,down_transId]=min(mins);
down_trans_Pixel.cnt=down_trans_cnt;
down_trans_Pixel.id=down_transId;
%遍历256~129行求和bin heights 并选取最小值右零值点up_trans
temp=0;
mins=[];
for i=256:-1:129
    for ii=1:256
        temp=temp+H(i,ii);
    end
    mins(end+1)=temp;
end
[right_trans_cnt,right_transId]=min(mins);
right_trans_Pixel.cnt=right_trans_cnt;
right_trans_Pixel.id=257-right_transId;
%遍历256~129列求和bin heights 并选取最小值上零值点right_trans
temp=0;
mins=[];
for i=256:-1:129
    for ii=1:256
        temp=temp+H(ii,i);
    end
    mins(end+1)=temp;
end
[up_trans_cnt,up_transId]=min(mins);
up_trans_Pixel.cnt=up_trans_cnt;
up_trans_Pixel.id=257-up_transId;
trans_zero_pixels{1}=left_trans_Pixel;
trans_zero_pixels{2}=right_trans_Pixel;
trans_zero_pixels{3}=down_trans_Pixel;
trans_zero_pixels{4}=up_trans_Pixel;
%transid 1~256已经迁移
end
function [trans_peak_pixels]=Get_Embed_Location(H)

%寻找少于128最小列 最小行  0~127 128~255   像素平移后 1~128 129~256
%遍历1~128x轴求和y轴  并选取最小值左零值点down_trans
trans_peak_pixels=cell(4,1);
temp=0;
maxs=[];
for i=1:128
    for ii=1:256
        temp=temp+H(i,ii);
    end
    maxs(end+1)=temp;
end
[left_trans_cnt,left_transId]=max(maxs);
left_trans_Pixel.cnt=left_trans_cnt;
left_trans_Pixel.id=left_transId;
%遍历1~128y轴求和x轴 并选取最小值下零值点left_trans
temp=0;
maxs=[];
for i=1:128
    for ii=1:256
        temp=temp+H(ii,i);
    end
    maxs(end+1)=temp;
end
[down_trans_cnt,down_transId]=max(maxs);
down_trans_Pixel.cnt=down_trans_cnt;
down_trans_Pixel.id=down_transId;
%遍历256~129行求和bin heights 并选取最小值右零值点up_trans
temp=0;
maxs=[];
for i=256:-1:129
    for ii=1:256
        temp=temp+H(i,ii);
    end
    maxs(end+1)=temp;
end
[right_trans_cnt,right_transId]=max(maxs);
right_trans_Pixel.cnt=right_trans_cnt;
right_trans_Pixel.id=257-right_transId;
%遍历256~129列求和bin heights 并选取最小值上零值点right_trans
temp=0;
maxs=[];
for i=256:-1:129
    for ii=1:256
        temp=temp+H(ii,i);
    end
    maxs(end+1)=temp;
end
[up_trans_cnt,up_transId]=max(maxs);
up_trans_Pixel.cnt=up_trans_cnt;
up_trans_Pixel.id=257-up_transId;
trans_peak_pixels{1}=left_trans_Pixel;
trans_peak_pixels{2}=right_trans_Pixel;
trans_peak_pixels{3}=down_trans_Pixel;
trans_peak_pixels{4}=up_trans_Pixel;




end
function [trans_peak_pixels]=Extract_Embed_Location(marked_img,excluding_plane)
trans_peak_pixels=cell(4,1);
pixel=[];
id_bin=[];
bin=[];
for kk=1:length(excluding_plane)
    ex=excluding_plane{kk}.x;
    ey=excluding_plane{kk}.y;
    LSB_bin=de2bi(marked_img(ex,ey));
    LSB=LSB_bin(1);
    bin(end+1)=LSB;
    ex=excluding_plane{kk}.x;
    ey=excluding_plane{kk}.y+1;
    LSB_bin=de2bi(marked_img(ex,ey));
    LSB=LSB_bin(1);
    bin(end+1)=LSB;
end
for i=1:4
    id_bin=[];
    for ii=1:8
        id_bin(end+1)=bin(ii);
    end
    bin=bin(9:end);
    id=bi2de(id_bin);
    pixel.id=id;
    trans_peak_pixels{i}=pixel;
end
end
function [PDP2PixelMap]=Get_PDPair_To_Pixel_Map(ori_img2,plane1,H,axisincr)
%输出：像素对到点坐标的映射集合  （结构：PDP2PixelMap{?,?}→pixels{?}→pixel→x,y）
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
function [trans_img,LocateMap]=Preprocess_Img(ori_img,trans_zero_pixels,plane,H,axisincr)
%存储四个值是否为零值点 8位存储可表示
LocateMap=cell(4,1);%记录坐标点 结构Map→平移位置→坐标点→x,y
trans_img=ori_img;%初始化预处理后图像
%%%注意修改 统计信息时使用H原图 当涉及修改对原图像的像素值加减使用axisincr偏移量
left_zero_pixel=trans_zero_pixels{1};
right_zero_pixel=trans_zero_pixels{2};
down_zero_pixel=trans_zero_pixels{3};
up_zero_pixel=trans_zero_pixels{4};


%处理左
LocateMap_bin=[];%记录坐标点的二位值
if(left_zero_pixel.cnt==0)
    %最小值空位
    %平移零值点左边所有位+1 即原图 左像素值小于零值点的像素  像素值+1
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y)<(left_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y)=trans_img(plane{i}.x,plane{i}.y)+1;
        end
    end
    left.flag=0;
    LocateMap{1}=left;
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    left2_len=0;
    for i=1:256
        left2_len=left2_len+H(left_zero_pixel.id+1,i);
    end%记录a+1长度
    left1_len=left_zero_pixel.cnt;%记录a长度
    %初始化坐标信息
    for i=1:length(plane)
        %合并零值点
        if(trans_img(plane{i}.x,plane{i}.y)==left_zero_pixel.id+1-axisincr)
            LocateMap_bin(end+1)=0;
        end
        if(trans_img(plane{i}.x,plane{i}.y)==left_zero_pixel.id-axisincr)
            LocateMap_bin(end+1)=1;
            trans_img(plane{i}.x,plane{i}.y)=trans_img(plane{i}.x,plane{i}.y)+1;
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y)<(left_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y)=trans_img(plane{i}.x,plane{i}.y)+1;
        end
    end
    
    left.flag=1;
    left.data_len=left1_len+left2_len;
    left.data=LocateMap_bin;
    if(left.data_len~=length(LocateMap_bin))
        error('preprocess error');
    end
    LocateMap{1}=left;
end
%处理右
LocateMap_bin=[];
if(right_zero_pixel.cnt==0)
    %最小值空位
    %平移零值点左边所有位+1 即原图 左像素值小于零值点的像素  像素值+1
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y)>(right_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y)=trans_img(plane{i}.x,plane{i}.y)-1;
        end
    end
    right.flag=0;
    LocateMap{2}=right;
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    right2_len=0;
    for i=1:256
        right2_len=right2_len+H(right_zero_pixel.id-1,i);
    end%记录a-1长度
    right1_len=right_zero_pixel.cnt;%记录a长度
    %初始化坐标信息
    for i=1:length(plane)
        %合并零值点
        if(trans_img(plane{i}.x,plane{i}.y)==right_zero_pixel.id-1-axisincr)
            LocateMap_bin(end+1)=0;
        end
        if(trans_img(plane{i}.x,plane{i}.y)==right_zero_pixel.id-axisincr)
            LocateMap_bin(end+1)=1;
            trans_img(plane{i}.x,plane{i}.y)=trans_img(plane{i}.x,plane{i}.y)-1;
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y)<(right_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y)=trans_img(plane{i}.x,plane{i}.y)-1;
        end
    end
    
    right.flag=1;
    right.data_len=right1_len+right2_len;
    right.data=LocateMap_bin;
    if(right.data_len~=length(LocateMap_bin))
        error('preprocess error');
    end
    LocateMap{2}=right;
end
%处理下
LocateMap_bin=[];
if(down_zero_pixel.cnt==0)
    %最小值空位
    %平移零值点左边所有位+1 即原图 左像素值小于零值点的像素  像素值+1
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y+1)<(down_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y+1)=trans_img(plane{i}.x,plane{i}.y+1)+1;
        end
    end
    down.flag=0;
    LocateMap{3}=down;
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    down2_len=0;
    for i=1:256
        down2_len=down2_len+H(i,down_zero_pixel.id+1);
    end%记录a+1长度
    down1_len=down_zero_pixel.cnt;%记录a长度7
    %初始化坐标信息
    for i=1:length(plane)
        %合并零值点
        if(trans_img(plane{i}.x,plane{i}.y+1)==down_zero_pixel.id+1-axisincr)
            LocateMap_bin(end+1)=0;
        end
        if(trans_img(plane{i}.x,plane{i}.y+1)==down_zero_pixel.id-axisincr)
            LocateMap_bin(end+1)=1;
            trans_img(plane{i}.x,plane{i}.y+1)=trans_img(plane{i}.x,plane{i}.y+1)+1;
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y+1)<(down_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y+1)=trans_img(plane{i}.x,plane{i}.y+1)+1;
        end
    end
    
    down.flag=1;
    down.data_len=down1_len+down2_len;
    down.data=LocateMap_bin;
    if(down.data_len~=length(LocateMap_bin))
        error('preprocess error');
    end
    LocateMap{3}=down;
end
%处理上
LocateMap_bin=[];
if(up_zero_pixel.cnt==0)
    %最小值空位
    %平移零值点左边所有位+1 即原图 左像素值小于零值点的像素  像素值+1
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y+1)>(up_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y+1)=trans_img(plane{i}.x,plane{i}.y+1)-1;
        end
    end
    up.flag=0;
    LocateMap{4}=up;
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    up2_len=0;
    for i=1:256
        up2_len=up2_len+H(i,up_zero_pixel.id-1);
    end%记录a+1长度
    up1_len=up_zero_pixel.cnt;%记录a长度7
    %初始化坐标信息
    for i=1:length(plane)
        %合并零值点
        if(trans_img(plane{i}.x,plane{i}.y+1)==up_zero_pixel.id-1-axisincr)
            LocateMap_bin(end+1)=0;
        end
        if(trans_img(plane{i}.x,plane{i}.y+1)==up_zero_pixel.id-axisincr)
            LocateMap_bin(end+1)=1;
            trans_img(plane{i}.x,plane{i}.y+1)=trans_img(plane{i}.x,plane{i}.y+1)-1;
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(trans_img(plane{i}.x,plane{i}.y+1)<(up_zero_pixel.id-axisincr))
            trans_img(plane{i}.x,plane{i}.y+1)=trans_img(plane{i}.x,plane{i}.y+1)-1;
        end
    end
    
    up.flag=1;
    up.data_len=up1_len+up2_len;
    up.data=LocateMap_bin;
    if(up.data_len~=length(LocateMap_bin))
        error('preprocess error');
    end
    LocateMap{4}=up;
end

end
function [embed_bin,preprocess_2rd_img]=Preprocess_Data(preprocess_img,ori_bin,LocateMap,excluding_plane,trans_zero_pixels,trans_peak_pixels,axisincr,L)
%数据格式：总数据长度16bit+零值行列（包括零标志位4bit为1时再加坐标长度，坐标数据）+峰值还原信息+下次L+嵌入信息数据
%编辑坐标表信息合并原始信息
%顺序 左右下上
embed_bin=[];
preprocess_2rd_img=preprocess_img;
%先预留16位嵌入总长度bin位
for i=1:16
    embed_bin(end+1)=0;
end

for k=1:4
    locatemap=LocateMap{k};
    if(locatemap.flag==0)
        embed_bin(end+1)=0;
    else
        embed_bin(end+1)=1;
        %记录坐标信息长度默认15位
        data_len_bin=de2bi(locatemap.data_len);
        while length(data_len_bin)~=15
            data_len_bin(end+1)=0;
        end
        for i=1:15
            embed_bin(end+1)=data_len_bin(i);
        end
        for i=1:length(locatemap.data)
            embed_bin(end+1)=locatemap.data(i);
        end
    end
end
%嵌入零值点8位 还原时记得加一
for i=1:4
    zero_pixel_bin=de2bi((trans_zero_pixels{i}.id)-axisincr);
    while length(zero_pixel_bin)~=8
        zero_pixel_bin(end+1)=0;
    end
    for ii=1:8
        embed_bin(end+1)=zero_pixel_bin(ii);
    end
end

%32位峰值点还原信息  对排除位直接赋值
%峰值点信息bin
bin=[];
trans_peak_pixels_bin=[];
for k=1:4
    temp=trans_peak_pixels{k}.id;
    bin=de2bi(temp);
    while(length(bin)~=8)
        bin(end+1)=0;
    end
    for i=1:8
        trans_peak_pixels_bin(end+1)=bin(i);
    end
end
%还原信息
peak_bin=[];%还原用
bin_cnt=1;
for kk=1:length(excluding_plane)%遍历左坐标 嵌入左右
    %当前坐标
    ex=excluding_plane{kk}.x;
    ey=excluding_plane{kk}.y;
    %当前LSB
    LSB_bin=de2bi(preprocess_2rd_img(ex,ey));
    LSB=LSB_bin(1);
    %待嵌入bin
    bin=trans_peak_pixels_bin(bin_cnt);
    %比较嵌入LSB与bin相同peak_bin为0 不同1
    %提取时直接提取最低有效位
    %LSB 0 bin 0  变化  no  pbin 0   LSB0
    %LSB 0 bin 1 变化   yes pbin  1    LSB1嵌入加1 还原时减一  提取直接取LSB
    %LSB 1 bin 0 变化    yes  pbin 1   LSB 0注意255 1 0 0
    %LSB 1 bin 1 变化     no  pbin 0   LSB 1
    switch LSB==bin
        case true
            peak_bin(end+1)=0;
        case false
            peak_bin(end+1)=1;
            
            if(preprocess_2rd_img(ex,ey)==255)
                preprocess_2rd_img(ex,ey)=0;
            else
                preprocess_2rd_img(ex,ey)=preprocess_2rd_img(ex,ey)+1;
            end
            
    end
    LSB_bin=de2bi(preprocess_2rd_img(ex,ey));
    LSB=LSB_bin(1);
    %  fprintf('%d 处理后 %d\n',bin_cnt,LSB);
    bin_cnt=bin_cnt+1;
    
    %当前坐标
    ex=excluding_plane{kk}.x;
    ey=excluding_plane{kk}.y+1;
    %当前LSB
    LSB_bin=de2bi(preprocess_2rd_img(ex,ey));
    LSB=LSB_bin(1);
    %待嵌入bin
    bin=trans_peak_pixels_bin(bin_cnt);
    switch LSB==bin
        case true
            peak_bin(end+1)=0;
        case false
            peak_bin(end+1)=1;
            if(preprocess_2rd_img(ex,ey)==255)
                preprocess_2rd_img(ex,ey)=0;
            else
                preprocess_2rd_img(ex,ey)=preprocess_2rd_img(ex,ey)+1;
            end
    end
    
    LSB_bin=de2bi(preprocess_2rd_img(ex,ey));
    LSB=LSB_bin(1);
    %fprintf('%d 处理后 %d\n',bin_cnt,LSB);
    bin_cnt=bin_cnt+1;
end
for j=1:length(excluding_plane)*2
    embed_bin(end+1)=peak_bin(j);
end

%嵌入遍历次数 占4位
L_bin=de2bi(L);
while length(L_bin)~=4
    L_bin(end+1)=0;
end
for i=1:length(L_bin)
    embed_bin(end+1)=L_bin(i);
end

%嵌入真实数据
for i=1:length(ori_bin)
    embed_bin(end+1)=ori_bin(i);
end

%修正记载数据总长度的前16位
total_len_bin=de2bi(length(embed_bin));
while length(total_len_bin)~=16
    total_len_bin(end+1)=0;
end
for i=1:16
    embed_bin(i)=total_len_bin(i);
end

end
function [ori_img]=Extract_Preprocess_Img(trans_img,LocateMap,trans_zero_pixels,plane,axisincr)
%LocateMap结构 左右下上 flag 为0无额外信息 为1 有遍历时产生的01  通过遍历对应a +/- 1 加减01还原
%存储四个值是否为零值点
ori_img=trans_img;%初始化预处理后图像
%%%注意修改 统计信息时使用H原图 当涉及修改对原图像的像素值加减使用axisincr偏移量
left_zero_pixel=trans_zero_pixels{1};
right_zero_pixel=trans_zero_pixels{2};
down_zero_pixel=trans_zero_pixels{3};
up_zero_pixel=trans_zero_pixels{4};


%处理左
if(LocateMap{1}.flag==0)
    %最小值空位
    %平移零值点左边所有位-1 即原图 左像素值小于零值点的像素  像素值-1
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y)<(left_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)-1;
        end
    end
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %遍历a+1 与01相减
    locatemap=LocateMap{1}.data;
    locatemap_cnt=1;%坐标位计数
    for i=1:length(plane)
        %还原零值点邻域
        if(ori_img(plane{i}.x,plane{i}.y)==left_zero_pixel.id+1-axisincr)
            if(locatemap_cnt~=length(locatemap))
                ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)-locatemap(locatemap_cnt);
                locatemap_cnt=locatemap_cnt+1;
            end
        end
    end
    %还原聚拢图像
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y)<(left_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)-1;
        end
    end
end
%处理右
if(LocateMap{2}.flag==0)
    %最小值空位
    %
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y)>(right_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)+1;
        end
    end
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    locatemap=LocateMap{2}.data;
    locatemap_cnt=1;%坐标位计数
    for i=1:length(plane)
        %分裂零值点邻域
        if(ori_img(plane{i}.x,plane{i}.y)==right_zero_pixel.id-1-axisincr)
            if(locatema_cnt~=length(locatemap))
                ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)+locatemap(locatemap_cnt);
                locatemap_cnt=locatemap_cnt+1;
            end
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y)<(right_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)+1;
        end
    end
end
%处理下
if(LocateMap{3}.flag==0)
    %最小值空位
    %平移零值点左边所有位+1 即原图 左像素值小于零值点的像素  像素值+1
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y+1)<(down_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y+1)=ori_img(plane{i}.x,plane{i}.y+1)-1;
        end
    end
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    locatemap=LocateMap{2}.data;
    locatemap_cnt=1;%坐标位计数
    for i=1:length(plane)
        %裂解零值点邻域
        if(ori_img(plane{i}.x,plane{i}.y+1)==down_zero_pixel.id+1-axisincr)
            if(locatema_cnt~=length(locatemap))
                ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)-locatemap(locatemap_cnt);
                locatemap_cnt=locatemap_cnt+1;
            end
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y+1)<(down_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y+1)=ori_img(plane{i}.x,plane{i}.y+1)-1;
        end
    end
end
%处理上
if(LocateMap{4}.flag==0)
    %最小值空位
    %平移零值点左边所有位+1 即原图 左像素值小于零值点的像素  像素值+1
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y+1)>(up_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y+1)=ori_img(plane{i}.x,plane{i}.y+1)+1;
        end
    end
else
    %最小值非空位
    %对于零值点左边 同上 不记录位置坐标
    %对于对于零值点处零值点靠近中心合并通过记录a与a+1长度和和数字流记录坐标 a位1 a+1为0
    locatemap=LocateMap{2}.data;
    locatemap_cnt=1;%坐标位计数
    for i=1:length(plane)
        %合并零值点
        if(trans_img(plane{i}.x,plane{i}.y+1)==up_zero_pixel.id-1-axisincr)
            if(locatema_cnt~=length(locatemap))
                ori_img(plane{i}.x,plane{i}.y)=ori_img(plane{i}.x,plane{i}.y)+locatemap(locatemap_cnt);
                locatemap_cnt=locatemap_cnt+1;
            end
        end
    end
    %聚拢图像
    for i=1:length(plane)
        if(ori_img(plane{i}.x,plane{i}.y+1)<(up_zero_pixel.id-axisincr))
            ori_img(plane{i}.x,plane{i}.y+1)=ori_img(plane{i}.x,plane{i}.y+1)+1;
        end
    end
end
end
function [ori_bin,preprocess_img,LocateMap,trans_zero_pixels,L]=Extract_Preprocess_Data(preprocess_2rd_img,embed_bin,excluding_plane,axisincr)
ori_bin=[];
LocateMap=cell(4,1);
%裁剪嵌入提取使用的16位总数据长度
embed_bin=embed_bin(17:end);










for k=1:4
    temp=[];
    if(embed_bin(1)==0)
        temp.flag=0;
        LocateMap{k}=temp;
        ext_len=1;%本次开销信息长度
    else
        %提取坐标长度
        len_bin=[];
        for i=1:15
            len_bin(end+1)=embed_bin(i+1);
        end
        len=bi2de(len_bin);
        data_bin=[];
        for i=1:len
            data_bin(end+1)=embed_bin(i+16);
        end
        temp.flag=1;
        temp.data_len=len;
        temp.data=data_bin;
        LocateMap{k}=temp;
        ext_len=len+16;%本次开销信息长度
    end
    %裁剪已经提取过的信息
    embed_bin=embed_bin(ext_len+1:end);
end
%提取零值点
trans_zero_pixels=cell(4,1);
for i=1:4
    pixelid_bin=[];
    for ii=1:8
        pixelid_bin(end+1)=embed_bin(ii);
    end
    embed_bin=embed_bin(9:end);
    zero_pixel.id=bi2de(pixelid_bin)+axisincr;
    trans_zero_pixels{i}=zero_pixel;
end



preprocess_img=preprocess_2rd_img;
%裁剪关于峰值比对信息1
peak_bin=embed_bin(1:32);
bin_cnt=1;
%遍历excluding_plane对于每一个还原信息位 为1 还原信息减一
for kk=1:length(excluding_plane)
    ex=excluding_plane{kk}.x;
    ey=excluding_plane{kk}.y;
    LSB_bin=de2bi(preprocess_img(ex,ey));
    LSB=LSB_bin(1);
    if(peak_bin(bin_cnt)==1)
        if(preprocess_img(ex,ey)==0)
            preprocess_img(ex,ey)=255;
        else
            preprocess_img(ex,ey)=preprocess_img(ex,ey)-1;
        end
    end
    bin_cnt=bin_cnt+1;
    ex=excluding_plane{kk}.x;
    ey=excluding_plane{kk}.y+1;
    LSB_bin=de2bi(preprocess_img(ex,ey));
    LSB=LSB_bin(1);
    if(peak_bin(bin_cnt)==1)
        if(preprocess_img(ex,ey)==0)
            preprocess_img(ex,ey)=255;
        else
            preprocess_img(ex,ey)=preprocess_img(ex,ey)-1;
        end
    end
    bin_cnt=bin_cnt+1;
end

embed_bin=embed_bin(33:end);%裁剪峰值还原信息

%获取L
L_bin=embed_bin(1:4);
L=bi2de(L_bin);
embed_bin=embed_bin(5:end);%裁剪L的4位

%获取真实数据
ori_bin=embed_bin;
end
function [trans_preprocess_img]=Embed_Translation(preprocess_img,plane,trans_peak_pixels,axisincr,PDP2PixelMap)

trans_preprocess_img=preprocess_img;
%256的峰值点
left=trans_peak_pixels{1}.id-axisincr;
right=trans_peak_pixels{2}.id-axisincr;
down=trans_peak_pixels{3}.id-axisincr;
up=trans_peak_pixels{4}.id-axisincr;
%遍历块平移
for k=1:length(plane)
    leftpixel=trans_preprocess_img(plane{k}.x,plane{k}.y);
    rightpixel=trans_preprocess_img(plane{k}.x,plane{k}.y+1);
    
    %左竖块
    if(leftpixel<left&&down<rightpixel&&rightpixel<up)
        trans_preprocess_img(plane{k}.x,plane{k}.y)=trans_preprocess_img(plane{k}.x,plane{k}.y)-1;
    end
    %右竖块
    if(leftpixel>right&&down<rightpixel&&rightpixel<up)
        trans_preprocess_img(plane{k}.x,plane{k}.y)=trans_preprocess_img(plane{k}.x,plane{k}.y)+1;
    end
    %下竖块
    if(left<leftpixel&&leftpixel<right&&rightpixel<down)
        trans_preprocess_img(plane{k}.x,plane{k}.y+1)=trans_preprocess_img(plane{k}.x,plane{k}.y+1)-1;
    end
    %上竖块
    if(left<leftpixel&&leftpixel<right&&rightpixel>up)
        trans_preprocess_img(plane{k}.x,plane{k}.y+1)=trans_preprocess_img(plane{k}.x,plane{k}.y+1)+1;
    end
    
    %右上块
    if(leftpixel>right&&rightpixel>up)
        trans_preprocess_img(plane{k}.x,plane{k}.y)=trans_preprocess_img(plane{k}.x,plane{k}.y)+1;
        trans_preprocess_img(plane{k}.x,plane{k}.y+1)=trans_preprocess_img(plane{k}.x,plane{k}.y+1)+1;
    end
    %右下块
    if(leftpixel>right&&rightpixel<down)
        trans_preprocess_img(plane{k}.x,plane{k}.y)=trans_preprocess_img(plane{k}.x,plane{k}.y)+1;
        trans_preprocess_img(plane{k}.x,plane{k}.y+1)=trans_preprocess_img(plane{k}.x,plane{k}.y+1)-1;
    end
    %左上块
    if(leftpixel<left&&rightpixel>up)
        trans_preprocess_img(plane{k}.x,plane{k}.y)=trans_preprocess_img(plane{k}.x,plane{k}.y)-1;
        trans_preprocess_img(plane{k}.x,plane{k}.y+1)=trans_preprocess_img(plane{k}.x,plane{k}.y+1)+1;
    end
    %左下块
    if(leftpixel<left&&rightpixel<down)
        trans_preprocess_img(plane{k}.x,plane{k}.y)=trans_preprocess_img(plane{k}.x,plane{k}.y)-1;
        trans_preprocess_img(plane{k}.x,plane{k}.y+1)=trans_preprocess_img(plane{k}.x,plane{k}.y+1)-1;
    end
end

%按序遍历映射表平移线
%映射表1~256  构成【256，256】
%外围已空一位 实际遍历2~255
%256的峰值点
left=trans_peak_pixels{1}.id;
right=trans_peak_pixels{2}.id;
down=trans_peak_pixels{3}.id;
up=trans_peak_pixels{4}.id;
%左
for leftpixel=2:left-1
    %上左横线
    
    rightpixel=up;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            %     fprintf('【%d,%d】[%d,%d]左移空位\t %d→%d\t 上左横线\n',x,y,leftpixel,rightpixel,trans_preprocess_img(x,y),trans_preprocess_img(x,y)-1);
            trans_preprocess_img(x,y)=trans_preprocess_img(x,y)-1;
        end
    end
    %下左横线
    rightpixel=down;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            %   fprintf('【%d,%d】[%d,%d]左移空位\t %d→%d\t 下左横线\n',x,y,leftpixel,rightpixel,trans_preprocess_img(x,y),trans_preprocess_img(x,y)-1);
            trans_preprocess_img(x,y)=trans_preprocess_img(x,y)-1;
        end
    end
    
end
%右
for leftpixel=255:-1:right+1
    %上右横线
    rightpixel=up;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            trans_preprocess_img(x,y)=trans_preprocess_img(x,y)+1;
        end
    end
    %下右横线
    rightpixel=down;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            trans_preprocess_img(x,y)=trans_preprocess_img(x,y)+1;
        end
    end
end
%下
for rightpixel=2:down-1
    %左下竖线
    leftpixel=left;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            trans_preprocess_img(x,y+1)=trans_preprocess_img(x,y+1)-1;
            
        end
    end
    
    %右下竖线
    leftpixel=right;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            trans_preprocess_img(x,y+1)=trans_preprocess_img(x,y+1)-1;
        end
    end
    
end
%上
for rightpixel=255:-1:up+1
    %左上竖线
    leftpixel=left;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            trans_preprocess_img(x,y+1)=trans_preprocess_img(x,y+1)+1;
        end
    end
    %右上竖线
    leftpixel=right;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            trans_preprocess_img(x,y+1)=trans_preprocess_img(x,y+1)+1;
        end
    end
end
end
function [preprocess_img]=Extract_Translation(trans_preprocess_img,plane,trans_peak_pixels,axisincr,PDP2PixelMap)

preprocess_img=trans_preprocess_img;
%256的峰值点
left=trans_peak_pixels{1}.id;
right=trans_peak_pixels{2}.id;
down=trans_peak_pixels{3}.id;
up=trans_peak_pixels{4}.id;


%线平移
%左
for leftpixel=2:left-1
    %上左横线
    rightpixel=up;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            if(x==410&&y==165)
            end
            %  fprintf('【%d,%d】[%d,%d]右移还原\t %d→%d\t 上左横线\n',x,y,leftpixel,rightpixel,preprocess_img(x,y),preprocess_img(x,y)+1);
            preprocess_img(x,y)=preprocess_img(x,y)+1;
        end
    end
    %下左横线
    rightpixel=down;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            if(x==410&&y==165)
            end
            %  fprintf('【%d,%d】[%d,%d]右移还原\t %d→%d\t 下左横线\n',x,y,leftpixel,rightpixel,preprocess_img(x,y),preprocess_img(x,y)+1);
            preprocess_img(x,y)=preprocess_img(x,y)+1;
        end
    end
end
%右
for leftpixel=255:-1:right+1
    %上右横线
    rightpixel=up;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            preprocess_img(x,y)=preprocess_img(x,y)-1;
        end
    end
    %下右横线
    rightpixel=down;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            preprocess_img(x,y)=preprocess_img(x,y)-1;
        end
    end
end
%下
for rightpixel=2:down-1
    %左下竖线
    leftpixel=left;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            preprocess_img(x,y+1)=preprocess_img(x,y+1)+1;
        end
    end
    %右下竖线
    leftpixel=right;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            preprocess_img(x,y+1)=preprocess_img(x,y+1)+1;
        end
    end
end
%上
for rightpixel=255:-1:up+1
    %左上竖线
    leftpixel=left;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            preprocess_img(x,y+1)=preprocess_img(x,y+1)-1;
        end
    end
    %左上竖线
    leftpixel=right;
    if(~isempty(PDP2PixelMap{leftpixel,rightpixel}))
        pixels=PDP2PixelMap{leftpixel,rightpixel};
        for k=1:length(pixels)
            x=pixels{k}.x;
            y=pixels{k}.y;
            preprocess_img(x,y+1)=preprocess_img(x,y+1)-1;
        end
    end
end

%块平移
left=trans_peak_pixels{1}.id-axisincr;
right=trans_peak_pixels{2}.id-axisincr;
down=trans_peak_pixels{3}.id-axisincr;
up=trans_peak_pixels{4}.id-axisincr;
%遍历块平移
for k=1:length(plane)
    leftpixel=preprocess_img(plane{k}.x,plane{k}.y);
    rightpixel=preprocess_img(plane{k}.x,plane{k}.y+1);
    if((plane{k}.x==410||plane{k}.x==410==409)&&(plane{k}.y==165||plane{k}.y==164))
    end
    %左竖块
    if(leftpixel<left&&down<rightpixel&&rightpixel<up)
        preprocess_img(plane{k}.x,plane{k}.y)=preprocess_img(plane{k}.x,plane{k}.y)+1;
    end
    %右竖块
    if(leftpixel>right&&down<rightpixel&&rightpixel<up)
        preprocess_img(plane{k}.x,plane{k}.y)=preprocess_img(plane{k}.x,plane{k}.y)-1;
    end
    %下竖块
    if(left<leftpixel&&leftpixel<right&&rightpixel<down)
        preprocess_img(plane{k}.x,plane{k}.y+1)=preprocess_img(plane{k}.x,plane{k}.y+1)+1;
    end
    %上竖块
    if(left<leftpixel&&leftpixel<right&&rightpixel>up)
        preprocess_img(plane{k}.x,plane{k}.y+1)=preprocess_img(plane{k}.x,plane{k}.y+1)-1;
    end
    
    %右上块
    if(leftpixel>right&&rightpixel>up)
        preprocess_img(plane{k}.x,plane{k}.y)=preprocess_img(plane{k}.x,plane{k}.y)-1;
        preprocess_img(plane{k}.x,plane{k}.y+1)=preprocess_img(plane{k}.x,plane{k}.y+1)-1;
    end
    %右下块
    if(leftpixel>right&&rightpixel<down)
        preprocess_img(plane{k}.x,plane{k}.y)=preprocess_img(plane{k}.x,plane{k}.y)-1;
        preprocess_img(plane{k}.x,plane{k}.y+1)=preprocess_img(plane{k}.x,plane{k}.y+1)+1;
    end
    %左上块
    if(leftpixel<left&&rightpixel>up)
        preprocess_img(plane{k}.x,plane{k}.y)=preprocess_img(plane{k}.x,plane{k}.y)+1;
        preprocess_img(plane{k}.x,plane{k}.y+1)=preprocess_img(plane{k}.x,plane{k}.y+1)-1;
    end
    %左下块
    if(leftpixel<left&&rightpixel<down)
        preprocess_img(plane{k}.x,plane{k}.y)=preprocess_img(plane{k}.x,plane{k}.y)+1;
        preprocess_img(plane{k}.x,plane{k}.y+1)=preprocess_img(plane{k}.x,plane{k}.y+1)+1;
    end
end
end
function [marked_img]=Embed_Data(trans_img,embed_bin,plane,trans_peak_pixels,axisincr)%嵌入信息
marked_img=trans_img;
%256的峰值点
left=trans_peak_pixels{1}.id-axisincr;
right=trans_peak_pixels{2}.id-axisincr;
down=trans_peak_pixels{3}.id-axisincr;
up=trans_peak_pixels{4}.id-axisincr;
embed_bin_len=length(embed_bin);%获取嵌入信息位数
embed_bin_cnt=1;

%遍历像素嵌入和平移
for k=1:length(plane)
    leftpixel=marked_img(plane{k}.x,plane{k}.y);
    rightpixel=marked_img(plane{k}.x,plane{k}.y+1);
    
    %对于角落点的上下左右 线上的像素会干扰提取暂不可用
    %右上角
    if(leftpixel==right&&rightpixel==up)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 右上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,marked_img(plane{k}.x,plane{k}.y),marked_img(plane{k}.x,plane{k}.y)+bin);
            
            marked_img(plane{k}.x,plane{k}.y)=marked_img(plane{k}.x,plane{k}.y)+bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 右上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,marked_img(plane{k}.x,plane{k}.y+1),marked_img(plane{k}.x,plane{k}.y+1)+bin);
            
            marked_img(plane{k}.x,plane{k}.y+1)=marked_img(plane{k}.x,plane{k}.y+1)+bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %左上角
    if(leftpixel==left&&rightpixel==up)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 左上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,marked_img(plane{k}.x,plane{k}.y),marked_img(plane{k}.x,plane{k}.y)-bin);
            
            marked_img(plane{k}.x,plane{k}.y)=marked_img(plane{k}.x,plane{k}.y)-bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 左上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,marked_img(plane{k}.x,plane{k}.y+1),marked_img(plane{k}.x,plane{k}.y+1)+bin);
            
            marked_img(plane{k}.x,plane{k}.y+1)=marked_img(plane{k}.x,plane{k}.y+1)+bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %左下角
    if(leftpixel==left&&rightpixel==down)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 左下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,marked_img(plane{k}.x,plane{k}.y),marked_img(plane{k}.x,plane{k}.y)-bin);
            
            marked_img(plane{k}.x,plane{k}.y)=marked_img(plane{k}.x,plane{k}.y)-bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 左下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,marked_img(plane{k}.x,plane{k}.y+1),marked_img(plane{k}.x,plane{k}.y+1)-bin);
            
            marked_img(plane{k}.x,plane{k}.y+1)=marked_img(plane{k}.x,plane{k}.y+1)-bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %右下角
    if(leftpixel==right&&rightpixel==down)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 右下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,marked_img(plane{k}.x,plane{k}.y),marked_img(plane{k}.x,plane{k}.y)+bin);
            
            marked_img(plane{k}.x,plane{k}.y)=marked_img(plane{k}.x,plane{k}.y)+bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 右下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,marked_img(plane{k}.x,plane{k}.y+1),marked_img(plane{k}.x,plane{k}.y+1)-bin);
            
            marked_img(plane{k}.x,plane{k}.y+1)=marked_img(plane{k}.x,plane{k}.y+1)-bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %}
    %右竖线 (上中下)
    if(leftpixel==right&&rightpixel~=up&&rightpixel~=down&&rightpixel~=up+1&&rightpixel~=down-1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 右竖线\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,marked_img(plane{k}.x,plane{k}.y),marked_img(plane{k}.x,plane{k}.y)+bin);
            
            marked_img(plane{k}.x,plane{k}.y)=marked_img(plane{k}.x,plane{k}.y)+bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %左竖线
    if(leftpixel==left&&rightpixel~=down&&rightpixel~=up&&rightpixel~=up+1&&rightpixel~=down-1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 左竖线\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,marked_img(plane{k}.x,plane{k}.y),marked_img(plane{k}.x,plane{k}.y)-bin);
            
            marked_img(plane{k}.x,plane{k}.y)=marked_img(plane{k}.x,plane{k}.y)-bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %上横线
    if(rightpixel==up&&leftpixel~=left&&leftpixel~=right&&leftpixel~=left-1&&leftpixel~=right+1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 上横线\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,marked_img(plane{k}.x,plane{k}.y+1),marked_img(plane{k}.x,plane{k}.y+1)+bin);
            
            marked_img(plane{k}.x,plane{k}.y+1)=marked_img(plane{k}.x,plane{k}.y+1)+bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %下横线
    if(rightpixel==down&&leftpixel~=left&&leftpixel~=right&&leftpixel~=left-1&&leftpixel~=right+1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=embed_bin(embed_bin_cnt);
            fprintf('序号：%d\t【%d,%d】 \t嵌入%d\t%d→%d 下横线\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,marked_img(plane{k}.x,plane{k}.y+1),marked_img(plane{k}.x,plane{k}.y+1)-bin);
            marked_img(plane{k}.x,plane{k}.y+1)=marked_img(plane{k}.x,plane{k}.y+1)-bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
end
end
function [trans_img,embed_bin]=Extract_Data(marked_img,plane,trans_peak_pixels,axisincr)
trans_img=marked_img;
embed_bin=[];
%256的峰值点
left=trans_peak_pixels{1}.id-axisincr;
right=trans_peak_pixels{2}.id-axisincr;
down=trans_peak_pixels{3}.id-axisincr;
up=trans_peak_pixels{4}.id-axisincr;
embed_bin_len=intmax;
embed_bin_cnt=1;

%遍历像素嵌入和平移
for k=1:length(plane)
    leftpixel=trans_img(plane{k}.x,plane{k}.y);
    rightpixel=trans_img(plane{k}.x,plane{k}.y+1);
    if(embed_bin_cnt==17)%提取前16位长度信息
        embed_bin_len_bin=embed_bin(1:16);
        embed_bin_len=bi2de(embed_bin_len_bin);
    end
    if(plane{k}.y==155||plane{k}.y==154)
    end
    
    %右上角
    if((leftpixel==right||leftpixel==right+1)&&(rightpixel==up||rightpixel==up+1))
        if(embed_bin_cnt<=embed_bin_len)
            bin=leftpixel-right;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 右上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,trans_img(plane{k}.x,plane{k}.y),trans_img(plane{k}.x,plane{k}.y)-bin);
            
            trans_img(plane{k}.x,plane{k}.y)=trans_img(plane{k}.x,plane{k}.y)-bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt==17)%提取前16位长度信息
            embed_bin_len_bin=embed_bin(1:16);
            embed_bin_len=bi2de(embed_bin_len_bin);
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=rightpixel-up;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 右上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,trans_img(plane{k}.x,plane{k}.y+1),trans_img(plane{k}.x,plane{k}.y+1)-bin);
            
            trans_img(plane{k}.x,plane{k}.y+1)=trans_img(plane{k}.x,plane{k}.y+1)-bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %左上角
    if((leftpixel==left||leftpixel==left-1)&&(rightpixel==up||rightpixel==up+1))
        if(embed_bin_cnt<=embed_bin_len)
            bin=left-leftpixel;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 左上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,trans_img(plane{k}.x,plane{k}.y),trans_img(plane{k}.x,plane{k}.y)+bin);
            
            trans_img(plane{k}.x,plane{k}.y)=trans_img(plane{k}.x,plane{k}.y)+bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt==17)%提取前16位长度信息
            embed_bin_len_bin=embed_bin(1:16);
            embed_bin_len=bi2de(embed_bin_len_bin);
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=rightpixel-up;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 左上角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,trans_img(plane{k}.x,plane{k}.y+1),trans_img(plane{k}.x,plane{k}.y+1)-bin);
            
            trans_img(plane{k}.x,plane{k}.y+1)=trans_img(plane{k}.x,plane{k}.y+1)-bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %左下角
    if((leftpixel==left||leftpixel==left-1)&&(rightpixel==down||rightpixel==down-1))
        if(embed_bin_cnt<=embed_bin_len)
            bin=left-leftpixel;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 左下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,trans_img(plane{k}.x,plane{k}.y),trans_img(plane{k}.x,plane{k}.y)+bin);
            
            trans_img(plane{k}.x,plane{k}.y)=trans_img(plane{k}.x,plane{k}.y)+bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt==17)%提取前16位长度信息
            embed_bin_len_bin=embed_bin(1:16);
            embed_bin_len=bi2de(embed_bin_len_bin);
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=down-rightpixel;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 左下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,trans_img(plane{k}.x,plane{k}.y+1),trans_img(plane{k}.x,plane{k}.y+1)+bin);
            
            trans_img(plane{k}.x,plane{k}.y+1)=trans_img(plane{k}.x,plane{k}.y+1)+bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %右下角
    if((leftpixel==right||leftpixel==right+1)&&(rightpixel==down||rightpixel==down-1))
        if(embed_bin_cnt<=embed_bin_len)
            bin=leftpixel-right;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 右下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,trans_img(plane{k}.x,plane{k}.y),trans_img(plane{k}.x,plane{k}.y)-bin);
            
            trans_img(plane{k}.x,plane{k}.y)=trans_img(plane{k}.x,plane{k}.y)-bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
        if(embed_bin_cnt==17)%提取前16位长度信息
            embed_bin_len_bin=embed_bin(1:16);
            embed_bin_len=bi2de(embed_bin_len_bin);
        end
        if(embed_bin_cnt<=embed_bin_len)
            bin=down-rightpixel;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 右下角\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,trans_img(plane{k}.x,plane{k}.y+1),trans_img(plane{k}.x,plane{k}.y+1)+bin);
            
            trans_img(plane{k}.x,plane{k}.y+1)=trans_img(plane{k}.x,plane{k}.y+1)+bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %}
    %右竖线 (上中下)
    if((leftpixel==right||leftpixel==right+1)&&rightpixel~=up&&rightpixel~=up+1&&rightpixel~=down&&rightpixel~=down-1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=leftpixel-right;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 右竖线\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,trans_img(plane{k}.x,plane{k}.y),trans_img(plane{k}.x,plane{k}.y)-bin);
            
            trans_img(plane{k}.x,plane{k}.y)=trans_img(plane{k}.x,plane{k}.y)-bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %左竖线
    if((leftpixel==left||leftpixel==left-1)&&rightpixel~=down&&rightpixel~=up&&rightpixel~=down-1&&rightpixel~=up+1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=left-leftpixel;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 左竖线\n',embed_bin_cnt,plane{k}.x,plane{k}.y,...
                bin,trans_img(plane{k}.x,plane{k}.y),trans_img(plane{k}.x,plane{k}.y)+bin);
            
            trans_img(plane{k}.x,plane{k}.y)=trans_img(plane{k}.x,plane{k}.y)+bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %上横线
    if((rightpixel==up||rightpixel==up+1)&&leftpixel~=left&&leftpixel~=right&&leftpixel~=left-1&&leftpixel~=right+1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=rightpixel-up;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 上横线\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,trans_img(plane{k}.x,plane{k}.y+1),trans_img(plane{k}.x,plane{k}.y+1)-bin);
            
            trans_img(plane{k}.x,plane{k}.y+1)=trans_img(plane{k}.x,plane{k}.y+1)-bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
    %下横线
    if((rightpixel==down||rightpixel==down-1)&&leftpixel~=left&&leftpixel~=right&&leftpixel~=left-1&&leftpixel~=right+1)
        if(embed_bin_cnt<=embed_bin_len)
            bin=down-rightpixel;
            fprintf('序号：%d\t【%d,%d】 \t提取%d\t%d→%d 下横线\n',embed_bin_cnt,plane{k}.x,plane{k}.y+1,...
                bin,trans_img(plane{k}.x,plane{k}.y+1),trans_img(plane{k}.x,plane{k}.y+1)+bin);
            
            trans_img(plane{k}.x,plane{k}.y+1)=trans_img(plane{k}.x,plane{k}.y+1)+bin;
            embed_bin(embed_bin_cnt)=bin;
            embed_bin_cnt=embed_bin_cnt+1;
        end
    end
end

end
