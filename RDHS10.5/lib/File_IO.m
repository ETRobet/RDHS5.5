function FileIO=File_IO
FileIO.getCurPath=@getCurPath;

FileIO.openFileDialog=@openFileDialog;
FileIO.openDirDialog=@openDirDialog;

FileIO.openBinFileDialog=@openBinFileDialog;
FileIO.openLibFileDialog=@openLibFileDialog;
FileIO.openOutFileDialog=@openOutFileDialog;
FileIO.openResFileDialog=@openResFileDialog;


FileIO.generateDecFile=@generateDecFile;
FileIO.generateDecFileTDHS=@generateDecFileTDHS;
FileIO.generateStrFile=@generateStrFile;
FileIO.generateImgFile=@generateImgFile;

FileIO.readDecFile=@readDecFile;
FileIO.readImgFile=@readImgFile;
FileIO.readStrFile=@readStrFile;



end


function [curProg_path,curRes_path,curBin_path,curLib_path,curOut_path,curProgFather_path] =getCurPath()
%获得当前路径
%输出 当前程序路径，当前资源路径；输入
curProg_p1=mfilename('fullpath');%获取程序路径
i=strfind(curProg_p1,'\');%匹配路径分隔符
curProg_path=curProg_p1(1:i(end-1));%程序路径
curProgFather_path=curProg_p1(1:i(end-2));%程序父目录
if ~exist([curProg_path,'\res'])
    mkdir([curProg_path,'\res'])         % 若不存在，在当前目录中产生一个子目录‘Figure’
end
if ~exist([curProg_path,'\out'])
    mkdir([curProg_path,'\out'])         % 若不存在，在当前目录中产生一个子目录‘Figure’
end
curRes_path=fullfile([curProg_path 'res']);%资源路径
curBin_path=fullfile([curProg_path 'bin']);%二进制文件
curLib_path=fullfile([curProg_path 'lib']);%库文件
curOut_path=fullfile([curProg_path 'out']);%输出文件
end

function [filename,filepath] = openFileDialog(varargin)
%UNTITLED9 此处显示有关此函数的摘要
%   此处显示详细说明'
curProg_path=getCurPath();
if ~exist([curProg_path,'\',varargin{1}])
    mkdir([curProg_path,'\',varargin{1}])         % 若不存在，在当前目录中产生一个子目录‘Figure’
end
switch nargin
    case 2
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开程序文件',varargin{2});
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 1
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开程序文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 0
        [filename,filepath]=uigetfile('','打开程序文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    otherwise
        cd(curProg_path);%先返回再报错
        error('too many parameters');
end
cd(curProg_path);
filepath=fullfile([filepath filename]);
end

function [filepath] = openDirDialog(varargin)
%UNTITLED9 此处显示有关此函数的摘要
%   此处显示详细说明'
[curProg_path,~,~,~,~,curProgFather_path]=getCurPath();
if ~exist([curProg_path,'\',varargin{1}])
    mkdir([curProg_path,'\',varargin{1}])         % 若不存在，在当前目录中产生一个子目录‘Figure’
end
switch nargin
    case 2

        [filepath]=uigetdir([curProg_path,varargin{1}],varargin{2});
        if(filepath==0)
            cd(curProg_path);
            error('non dir selected');
        end
    case 1
        [filepath]=uigetdir([curProg_path,varargin{1}]);
        if(filepath==0)
            cd(curProg_path);
            error('non dir selected');
        end
    case 0
        [filepath]=uigetdir(curProgFather_path);
        if(filepath==0)
            cd(curProg_path);
            error('non dir selected');
        end
    otherwise
        cd(curProg_path);%先返回再报错
        error('too many parameters');
end
cd(curProg_path);

end

function [filename,filepath] = openBinFileDialog(varargin )
%UNTITLED9 此处显示有关此函数的摘要
%   此处显示详细说明'
[curProg_path,~,curBin_path]=getCurPath();
cd(curBin_path);
switch nargin
    case 2
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开程序文件',varargin{2});
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 1
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开二进制文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 0
        [filename,filepath]=uigetfile('','打开二进制文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    otherwise
        cd(curProg_path);%先返回再报错
        error('too many parameters');
end
cd(curProg_path);
filepath=fullfile([filepath filename]);
end

function [filename,filepath] = openLibFileDialog(varargin )
%UNTITLED9 此处显示有关此函数的摘要
%   此处显示详细说明'
[curProg_path,~,~,curLib_path]=getCurPath();
cd(curLib_path);
switch nargin
    case 2
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开程序文件',varargin{2});
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 1
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开库文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 0
        [filename,filepath]=uigetfile('','打开库文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    otherwise
        cd(curProg_path);%先返回再报错
        error('too many parameters');
end
cd(curProg_path);
filepath=fullfile([filepath filename]);
end

function [filename,filepath] = openOutFileDialog( varargin )
%UNTITLED9 此处显示有关此函数的摘要
%   此处显示详细说明'
[curProg_path,~,~,~,curOut_path]=getCurPath();
cd(curOut_path);
switch nargin
    case 2
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开输出文件',varargin{2});
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 1
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开输出文件',varargin{1});
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 0
        [filename,filepath]=uigetfile('','打开输出文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    otherwise
        cd(curProg_path);%先返回再报错
        error('too many parameters');
end
cd(curProg_path);
filepath=fullfile([filepath filename]);
end

function [filename,filepath] = openResFileDialog(varargin)
%UNTITLED9 此处显示有关此函数的摘要
%   此处显示详细说明
[curProg_path,curRes_path]=getCurPath();
cd(curRes_path);
switch nargin
    case 2
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开程序文件',varargin{2});
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 1
        [filename,filepath]=uigetfile(['*','.',varargin{1}],'打开资源文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    case 0
        [filename,filepath]=uigetfile('','打开资源文件');
        if(filepath==0)
            cd(curProg_path);
            error('non file selected');
        end
    otherwise
        cd(curProg_path);%先返回再报错
        error('too many parameters');
end
cd(curProg_path);
filepath=fullfile([filepath filename]);
end

function [] = generateDecFile( path,msg )
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
dlmwrite(path,msg)
i=strfind(path,'\');%匹配路径分隔符
Father_path=path(1:i(end-1));%程序父目录
system(['explorer ' Father_path]);
end
function [] = generateDecFileTDHS( path,leftpeak_pixels,rightpeak_pixels,ECs)
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
msg_cnt=1;
ECs_len=length(ECs);
for i=1:ECs_len
    msg(msg_cnt)=leftpeak_pixels{i}.x;
    msg_cnt=msg_cnt+1;
    msg(msg_cnt)=rightpeak_pixels{i}.x;
    msg_cnt=msg_cnt+1;
    msg(msg_cnt)=ECs(i);
    msg_cnt=msg_cnt+1;
end
dlmwrite(path,msg)
i=strfind(path,'\');%匹配路径分隔符
Father_path=path(1:i(end-1));%程序父目录
system(['explorer ' Father_path]);
end
function [] = generateStrFile( path,msg )
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
fp=fopen(path,'w+','n','UTF-8');
fprintf(fp,'%s ',msg);
i=strfind(path,'\');%匹配路径分隔符
Father_path=path(1:i(end-1));%程序父目录
system(['explorer ' Father_path]);
fclose(fp);
end

function [] = generateImgFile( path,img)
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
imwrite(img,path);

i=strfind(path,'\');%匹配路径分隔符
Father_path=path(1:i(end-1));%程序父目录
system(['explorer ' Father_path]);

end

function [datas] = readDecFile(  path)
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
datas= dlmread(path) ;
end

function [img] = readImgFile( path )
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
img=imread(path);%读取原始图像
end

function [msg] = readStrFile( path)
%GENERATE_FILE 此处显示有关此函数的摘要
%   此处显示详细说明
fp=fopen(path,'r');
msg=fgets(fp);
fclose(fp);
end



