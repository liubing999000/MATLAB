%**************************************************************************
% 对样本数据进行主成分分析,使其降至N维
% Y 降维后的样本数据
% X 原始空间的样本数据； trainX 训练样本的集合； N 要求降至的维数
%**************************************************************************

function [Y] = PCA(X,trainX,N)
[yVectors,yValues,Psi] = pc_evectors(trainX,N);
Y = yVectors' * X;    %利用此特征阵得到降维后的样本数据



