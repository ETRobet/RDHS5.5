%输出：半平面1，半平面2，半平面1长度，半平面2长度   （半平面结构：plane→pixel→x,y） 
%输入：待划分图像
%顺序从左到右 从上到下 plane1首元素为1，1
%奇偶行划分 plane1第一个   若偶数全排 若奇数 舍去最后一行
img=zeros(64);
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
        for i=1:img_V
        img(i,img_V)=128;
        end
        cnt=1;
        for ii=1:img_H
            for jj=1:img_V-1
                coord.x=ii;
                coord.y=jj;
                odd_flag=mod(pixel_cnt,2);
                switch odd_flag
                    case 1
                        plane1{plane1_cnt}=coord;
                        plane1_cnt=plane1_cnt+1;
                        img(ii,jj)=0;
                    case 0
                        plane2{plane2_cnt}=coord;
                        plane2_cnt=plane2_cnt+1;
                        img(ii,jj)=255;
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
                                img(ii,jj)=0;
                            case 0
                                plane2{plane2_cnt}=coord;
                                plane2_cnt=plane2_cnt+1;
                                img(ii,jj)=255;
                        end
                        
                        pixel_cnt=pixel_cnt+1;
                        
                    end
        end
end
imshow(uint8(img))