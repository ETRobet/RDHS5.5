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
clear aa i j;
[op1,op2,op1_len,op2_len]=TDHS.getHalfPlane(oddplane);
[ep1,ep2,ep1_len,ep2_len]=TDHS.getHalfPlane(evenplane);
opp=ones(odd_len)*128;
for i=1:op1_len
    opp(op1{i}.x,op1{i}.y)=255;
end
for i=1:op2_len
    opp(op2{i}.x,op2{i}.y)=0;
end
epp=ones(even_len)*2;
for i=1:ep1_len
    epp(ep1{i}.x,ep1{i}.y)=255;
end
for i=1:ep2_len
    epp(ep2{i}.x,ep2{i}.y)=0;
end
figure;
subplot(1,2,1);
imshow(opp,'InitialMagnification','fit');
subplot(1,2,2);
imshow(epp,'InitialMagnification','fit');
