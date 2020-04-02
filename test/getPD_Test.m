TDHS=Two_Dimensional_Histogram_Shift;
odd_len=5;
even_len=6;
oddplane=ones(odd_len);
aa=0;
for i=1:5
    for j=1:5
        oddplane(i,j)=aa+1;
        aa=aa+1;
    end
end
evenplane=ones(even_len);
aa=0;
for i=1:6
    for j=1:6
        evenplane(i,j)=aa+1;
        aa=aa+1;
    end
end


ori_img2=evenplane;

[plane1,plane2,plane1_len,plane2_len]=TDHS.getHalfPlane(ori_img2);
dws=cell(plane1_len,1);
tempdw.dw1=0;
tempdw.dw2=0;
for i=1:plane1_len
tempdw.dw1=TDHS.getPD1(ori_img2,plane1{i});
tempdw.dw2=TDHS.getPD2(ori_img2,plane1{i});
dws{i}=tempdw;
end

epdws1=ones(even_len)*100;
for i=1:plane1_len
    epdws1(plane1{i}.x,plane1{i}.y)=dws{i}.dw1;
end
epdws2=ones(even_len)*100;
for i=1:plane2_len
    epdws2(plane1{i}.x,plane1{i}.y)=dws{i}.dw2;
end

hh=TDHS.getTDHS(dws);