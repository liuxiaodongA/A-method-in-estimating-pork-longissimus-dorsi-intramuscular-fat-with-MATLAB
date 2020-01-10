clear all;     % Clear all variables
clc;           % Clear screen
cd('C:\Users\69028\Desktop\test');
dsamp = dir('*.png'); 
[numM,numN] = size(dsamp);
result = zeros(numM,4);
%% 
for num = 1:numM;
tic            % Record the time when image processing starts
% num = 1;
name=dsamp(num).name;
f=imread(name);
ycbcr_f = rgb2ycbcr(f);
level = graythresh(ycbcr_f(:,:,3));
bw = im2bw(ycbcr_f(:,:,3),level);
bw = imfill(bw,'holes');                           % Filling holes
bw = bwareaopen(bw,1000000);      % Delete some small noise,you can change the size.
reg =  regionprops(bw);
rect = reg.BoundingBox;
rect(1:2) = rect(1:2)-100;
rect(3:4) = rect(3:4)+200;
if rect(1) < 0
    rect(1) = 0;
else
end
if rect(2) < 0
    rect(2) = 0;
else
end
tmpr = imcrop(bw,rect);
% Corrosion treatment
se=strel('disk',200);
tmpr1=imerode(tmpr,se);
tmpr2= cat(3,tmpr,tmpr,tmpr);
tmpr3= cat(3,tmpr1,tmpr1,tmpr1);
%Remove background
I_rmbg = imcrop(f,rect);
I_rmbg(tmpr2 == 0) = 0;
I = imcrop(f,rect);
I(tmpr3 == 0) = 0;     
% Block the picture
[row,col] = size(tmpr);
M = floor(row/110);
N = floor(col/110);
m1 = 110;
n1 = 110;
m2 = m1*ones(1,M);
n2 = n1*ones(1,N);
if row-M*m1 == 0
    m = m2;
else
    m = [m2,row-M*m1];
end
if col-N*n1 == 0
    n=n2;
else
    n = [n2,col-N*n1];
end
I_gray = I(:,:,3);
I_gmin = double(min(I_gray(I_gray>0))-1);
I_gmax = double(max(I_gray(:)));
if I_gmax > 0
   I_gray = mat2gray(I_gray,[I_gmin,I_gmax]);
else
end
cutoff = mat2cell(I_gray,m,n);
M = ceil(row/m1);
N = ceil(col/n1);
I_mode = double(mode(I_gray(I_gray ~= 0)));
for i = 1:M
    for j = 1:N
	   ct = cell2mat(cutoff(i,j));
	   if max(ct(:)) ~= 0
           ct_mode = double(mode(ct(ct~= 0)));
           ct_max = double(max(ct(ct ~= 0)));
           rec = I_mode/(ct_mode*7);
           level_ct =  double(ct_mode+ct_max*rec);
           if level_ct > 1
               level_ct = 1 ;
           end
           ct_bw = im2bw(ct,level_ct);
           cutoff{i,j} = ct_bw;
       else
         cutoff{i,j} = logical(ct);
       end
    end
end
sample = cell2mat(cutoff);
sample = bwareaopen(sample,600);
sample2= cat(3,sample,sample,sample);
I_color = I;
I_color(sample2 == 1) = 0;
% imwrite([I_rmbg,I;I_color,uint8(sample2*255)],[sprintf('%03d',num),name(1:8),'.png'],'png');
display([sprintf('%03d', num),  name]);
% Calculated area
result(num,1) = num;   % Sample number
result(num,2) = numel(tmpr1(tmpr1 ~= 0));   % Sample target area
result(num,3) = sum(sample(:));      % Target region fat area
result(num,4) = sum(sample(:))/numel(tmpr1(tmpr1 ~= 0));      % The proportion of target region fat area
toc         % Record the end of image processing
end
%
today = datestr(now,29);
xlswrite([today,'_extract_pork_fat_area_result.xls'],result);