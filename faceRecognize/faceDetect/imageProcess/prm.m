%**********************************************
%  prm algorithm
%  在此算法中，如果没有类k的训练样本，我们则假设类k的均值为0，协方差也为0
%***********************************************
function yClass = prm(Y,trainY,train_label,CLASSNUM)
%*****求其within-class covariance 矩阵*******
ALLNUM = size(trainY,2);
yMean = zeros(size(trainY,1),CLASSNUM); %均值
yClassCount = zeros(1,CLASSNUM);    %K类的个数
yCov = zeros(size(trainY,1),1);
yCovTotal = zeros(size(trainY,1),1);
for temp = 1:ALLNUM
   class_label = train_label(temp);
   yMean(:,class_label) = yMean(:,class_label) + trainY(:,temp);
   yClassCount(class_label) = yClassCount(class_label) + 1;
end
for temp =1:CLASSNUM
    if yClassCount(temp)> 0 
        yMean(:,temp) = yMean(:,temp)./yClassCount(temp);
    end
end
for temp =1:ALLNUM
    class_label = train_label(temp);
    if yClassCount(class_label) >=2 
        yCov = trainY(:,temp) - yMean(:,class_label);
        yCov = yCov .* yCov;
        yCov = yCov./(yClassCount(class_label) -1);
        yCovTotal = yCovTotal + yCov;
    end
end
yCovTotal = yCovTotal./CLASSNUM;
%*******分类器的实现**************
yTemp = Y * ones(1,CLASSNUM);
yCovTemp = yCovTotal * ones(1,CLASSNUM);
yTemp = yTemp - yMean;
yClassifier = sum( (yTemp.* yTemp)./yCovTemp, 1);
[yValue,yClass] = min(yClassifier);





