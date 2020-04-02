
%{


a=1.5
g=ceil(a);
gg=floor(a);

a1=mod(5,2);
a2=mod(6,2);
a3=mod(7,2);
aa=cell(3,1);
coord.x=1;
coord.y=2;
a{1}=coord;
a{1}.x
a{1}.y

mintemp=min(dws{1}.dw1,dws{1}.dw2);
for i=1:length(dws)
mintemp=min(mintemp,min(dws{1}.dw1,dws{1}.dw2));
end
disp(mintemp);


-3+1-(-3)
dw3=1;
dw4=1;
H=zeros(10,10);
H(dw3,dw4)=-4;

figure;
mesh(double(H));


for i=5:-1:1
disp(i)
end




coord.x=6;
coord.y=2;

dwPairPixel=cell(1,1);

%dwPairPixel{8,3}=pixels;
if(isempty(dwPairPixel{8,3}))
   pixels=cell(1,1);
    pixels{1}=coord;
dwPairPixel{8,3}=pixels;
disp('yes');
else
disp('??');
end
a=[];
dwPairPixel{8,3}{end+1}=coord;
aa=cell(1,1);
aa{end+1}=coord
%}

a=[1 1 0];
a(3)