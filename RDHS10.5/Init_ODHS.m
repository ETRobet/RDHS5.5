clc;clear;
addpath('bin');addpath('lib');addpath('out');addpath('res');

FileIO=File_IO;
RC4=Rivest_Cipher_4;
ODHS=One_Dimensional_Histogram_Shift_Coding;
DC=Data_Convert;
DP=Data_Process;

RC4_flag=true;
ext_flag=false;
if(RC4_flag==true)%RC加密必须
    ext_flag=true;
end
overload_solution='clip';%clip group  group动态调整循环生成new 灰度与img时间几何增长，调试不出来
data_type='A';%字符A,纯数字B，含有中文字符U 中文字符暂不完全支持 影响转码容量 不影响存储方式默认数字字符8byte 中文24byte  暂不支持ASCII的纯数字6byte转码存储
if(RC4_flag)%RC4 加密开启后强制数据类型位‘U’
    data_type='U';
end