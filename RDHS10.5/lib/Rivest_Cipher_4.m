function RC4=Rivest_Cipher_4
RC4.ksa=@KSA;
RC4.prga=@PRGA;

RC4.main=@main;

RC4.codingHeader=@codingHeader;
RC4.decodingHeader=@decodingHeader;
RC4.codingByFile=@Coding_By_File;
RC4.decodingByFile=@Decoding_By_File;
end
function [ S ] = KSA( key )

key = char(key);
key = uint16(key);

key_length = size(key,2);
S=0:255;

j=0;
for i=0:1:255
    j =  mod( j + S(i+1) + key(mod(i, key_length) + 1), 256);
    S([i+1 j+1]) = S([j+1 i+1]);
end

end

function [ key ] = PRGA( S, n )
%S is the result from KSA function
%n number of characters to be encrypted

i = 0;
j = 0;
key = uint16([]);
%each iteration we will append one key value

while n> 0
    n = n - 1;
    i = mod( i + 1, 256);
    j = mod(j + S(i+1), 256);
    S([i+1 j+1]) = S([j+1 i+1]);
    K = S( mod(  S(i+1) + S(j+1)   , 256)  + 1  );
    key = [key, K];
    
    
end

end

function [res_in_unicode,res_in_hex]=main(plaintext,key)


Z = uint8(PRGA(KSA(key), size(plaintext,2)));

P = uint8(char(plaintext));

res = bitxor(Z, P);

%printing result in hex and unicode
res_in_hex = mat2str(dec2hex(res,2));
res_in_unicode = char(res);
end

function [ msg,header ] = codingHeader( ori_msg,varargin )
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明
if(nargin==1)
    header=strcat(num2str(length(ori_msg)),'@');
elseif(nargin==2)
    header=strcat(num2str(length(ori_msg)),varargin{1});
else
    error('too many parameter');
end
%生成文件首部（len）
msg=strcat(header,ori_msg);



end
function [ msg_startId,header ] = decodingHeader(ori_msg)
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明
msg =ori_msg;
expression = '\d+@';
header_matches = regexp(msg,expression,'match');
if(length(header_matches)==0)
    header_len=0;
    %生成原始信息
    header=[];
    msg_startId=1;
    
else
    header_len=length(header_matches{1});
    %生成原始信息
    header=header_matches{1}(1:header_len);
    msg_startId=header_len+1;
end
end






function [ secret_msg,data_header ] = Coding_By_File(ori_msg,RC4_key,RC4_flag,ext_flag)
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明
if(RC4_flag)
    curProg_p1=mfilename('fullpath');%获取程序路径
    i=strfind(curProg_p1,'\');%匹配路径分隔符
    curProg_path=curProg_p1(1:i(end-1));%程序路径
    curRes_path=fullfile([curProg_path 'res']);%资源路径
    cd(curRes_path);
    [filename,filepath]=uigetfile('*.txt','打开RC4密钥文件','RC4_key.txt');
    if(filepath==0)
        cd(curProg_path);
        error('non file selected');
    end
    cd(curProg_path);
    ori_RC4_filepath=fullfile([filepath filename]);
    
    fp=fopen(ori_RC4_filepath,'r');
    RC4_key=fgets(fp);
    fclose(fp);
    
    if(ext_flag)%纯二进制追求容量或无额外信息
        [ori_data,data_header]=codingHeader(ori_msg);%嵌入数据首部
    else
        ori_data=ori_msg;data_header=[];
    end
    RC4_msg=main(ori_data,RC4_key);
    secret_msg=RC4_msg;
end

end

function [ ori_msg,data_header ] = Decoding_By_File(msg_pak,RC4_flag,ext_flag)
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明


if(RC4_flag)
    curProg_p1=mfilename('fullpath');%获取程序路径
    i=strfind(curProg_p1,'\');%匹配路径分隔符
    curProg_path=curProg_p1(1:i(end-1));%程序路径
    curRes_path=fullfile([curProg_path 'res']);%资源路径
    cd(curRes_path);
    [filename,filepath]=uigetfile('*.txt','打开RC4密钥文件','RC4_key.txt');
    if(filepath==0)
        cd(curProg_path);
        error('non file selected');
    end
    cd(curProg_path);
    ori_RC4_filepath=fullfile([filepath filename]);
    
    fp=fopen(ori_RC4_filepath,'r');
    RC4_key=fgets(fp);
    fclose(fp);
    
    
    
    
    recover_msg=main(msg_pak,RC4_key);
    if(ext_flag)%有额外信息
        [msg_startId,data_header]=decodingHeader(recover_msg); %文件头读取
        data_header_len=length(data_header);%解析文件头
        data_header_msg=data_header(1:data_header_len-1);
        if(isempty(data_header_msg))
            data_header_msg=[];
            error('illegal RC4msg');
        else
            data_header_msg=str2num(data_header_msg);
            msg_endId=data_header_msg;
        end
        recover_msg=recover_msg(msg_startId:msg_endId+msg_startId-1);
    
    else
        data_header=[];
    end
    ori_msg=recover_msg;
    
end

end





