%*************************************************************************
%  AdaBoost.M2 和PRM（Probabilistic reasoning models 1）的结合
%  参考文献:  
%  1. Chengjun Liu and Harry Wechsler, "Robust Coding Schemes for
%  Indexing and Retrieval from Large Face Database", IEEE Trans. Image 
%  Processing, vol.9, 132-137, 2000
%  2. Yoav Freund and Robert E.Schapire, "A Decision-Theoretic Generalization of 
%  On-line Learning and an Application to Boosting, Journal of computer and 
%  system sciences,55.119-139 (1997)    
%**************************************************************************
%  算法描述：
%     通过不停的改变权重，然后根据权重重新采样
%  
%********************************************************************
%
%
%***********************************************************************
clear;
%***********************************************************************
EACHNUM = 10;
TT = 200; %boosting的次数
CLASSNUM = 10;
fp = fopen('result.txt','w');
CLASSRATE = zeros(58,50,TT);
PseudoLoss = zeros(1,TT);

  %---------------------------训练集与测试集的预处理-------------------------------------------%
for CLASSNUM = 30:2:30
ALLNUM = CLASSNUM * EACHNUM;
for DIMNUM = 50:50                                                
    % *****************初始化样本*******************************
    for i=1:CLASSNUM
        s{i}=strcat('s',int2str(i));
    end
    trainface=[];
    for i=1:CLASSNUM  %训练样本数据
        loadface=loadimages(strcat('D:\code\matlab\face_for_train\',s{i},'\'), '', 'bmp');
        trainface=[trainface loadface];
        train_label((i-1)*EACHNUM+1:i*EACHNUM)=i;
    end
   testface=[];
    for i=1:CLASSNUM  %测试样本数据
        testface=[testface loadimages(strcat('D:\code\matlab\face_for_test\',s{i},'\'), '', 'bmp')];
        test_label((i-1)*EACHNUM+1:i*EACHNUM)=i;
    end
    
    MASK = ones(size(trainface{1}));   %将二维图像矩阵转换为一维向量
    index = find(MASK);
    trainX = zeros(size(index,1),size(trainface,2));
    for i = 1:ALLNUM
    trainX(:,i) = trainface{i}(index)./256;%将数据归一化到[0,1]之间
    end
    testX=zeros(size(index,1),size(testface,2));
    for i=1:size(testface,2),
        testX(:,i)=testface{i}(index)./256;
    end
    %clear trainface testface;  %清除变量，释放内存
    %***********************初始化样本*************************************

    %*********对图像进行PCA降维处理,AdaBoost.M2是基于PCA降维后的数据的*****
%    fprintf(1,'begin PCA\n');
    trainY = PCA(trainX,trainX,DIMNUM);%数据进行PCA算法降维
    testY = PCA(testX,trainX,DIMNUM);
    %clear trianX testX;
    yResult = zeros(1,ALLNUM);
%    fprintf(1,'begin test\n');
    %***********PCA降维*****************************************************
    
    %---------------------------训练集与测试集的预处理-------------------------------------------%
    
    
    
    %******************AdaBoost.M2的初始化*************************************
    DD = ones(TT,ALLNUM);  %样本的分布
    HH = zeros(ALLNUM,CLASSNUM,TT); %结果
    HHH = zeros(TT,CLASSNUM,ALLNUM);%???????
    QQ = zeros(ALLNUM,CLASSNUM,TT); %???????
    WW = zeros(ALLNUM,CLASSNUM,TT); %权重
    result_label = zeros(1,ALLNUM);%?????
    W = zeros(TT,ALLNUM);%权重
    DD(1,:) = 1/ALLNUM;
    for temp =1:ALLNUM  %初始化样本权重
        WW(temp,:,1) = DD(1,temp)/(CLASSNUM -1);%一张图片属于某一类的概率相等
        WW(temp,train_label(temp),1) = 0; %分类正确的，让其权重为0
    end
    
    for t = 1:TT  %boosting的次数
        W(t,:) = sum(WW(:,:,t),2)';%所有权重之和
        for temp = 1:ALLNUM
            QQ(temp,:,t) = WW(temp,:,t)./W(t,temp);
        end
        DD(t,:) = W(t,:)./sum(W(t,:));  %归一化
        
        %统计弱分类器的准确率
        nRightCount = 0;
        for temp = 1:ALLNUM
            yClass = prm_distribution(trainY(:,temp),trainY,train_label,DD(t,:),CLASSNUM,EACHNUM);%%%%？？？？？？
            HH(temp,yClass,t) = 1;
            if yClass == train_label(temp)
                nRightCount = nRightCount + 1;
            end
        end  
        
        TrainError(t) = (ALLNUM-nRightCount)/ALLNUM;%计算分类的错误率
        for test = 1:ALLNUM
            testYY = testY(:,test);
            yClass = prm_distribution(testYY,trainY,train_label,DD(t,:),CLASSNUM,EACHNUM);
            HHH(t,yClass,test) = 1;
        end
        pseudo_loss = 0; %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for temp = 1:ALLNUM %计算pseudo_loss
            incorrect_total = sum(QQ(temp,:,t).* HH(temp,:,t));  %QQ(temp,train_label(temp),t) =0
            pseudo_inc = DD(t,temp) * (1- HH(temp,train_label(temp),t) + incorrect_total);
            pseudo_loss = pseudo_loss + pseudo_inc;
        end  %计算pseudo_loss
        if pseudo_loss == 0 
            TT = t-1;
            break;
        end
        pseudo_loss = pseudo_loss/2;
        PseudoLoss(t) = pseudo_loss;
        bt = pseudo_loss/(1-pseudo_loss);
        
        for temp = 1:ALLNUM  %设置新的权重
            for tmp = 1:CLASSNUM
                temp_power = (1+ HH(temp,train_label(temp),t)  - HH(temp,tmp,t) )/2;
                WW(temp,tmp,t+1) = WW(temp,tmp,t) * (bt.^temp_power);
            end
        end%设置新的权重
        
        for test = 1:ALLNUM
            HHH(t,:,test) = HHH(t,:,test).*log(1/bt);%计算弱分类器的权重
        end
        %fprintf(1,'CLASSNUM = %d,t=%d,nRightCount=%d,pseudo_loss=%d,bt = %d\n',CLASSNUM,t,nRightCount,pseudo_loss,bt);
        %fprintf(fp,'CLASSNUM = %d,t=%d,nRightCount=%d,pseudo_loss=%d,bt = %d\n',CLASSNUM,t,nRightCount,pseudo_loss,bt);
    end  
    %***AdaBoost*************************************************************************
    
    
    
    %将多个弱分类器合并成一个强分类器
    for t = 1:TT
        for test = 1:ALLNUM  %依据权重得到最终分类
            hfx = zeros(1,CLASSNUM);
            hfx = sum(HHH(1:t,:,test),1);
            [yValue,yClass] = max(hfx);
            yResult(1,test) = yClass;            
        end   
        %*******计算识别率***************
        nRightCount = 0;  
        for i = 1:ALLNUM
            if test_label(i) == yResult(1,i)
                nRightCount = nRightCount + 1;
            end
        end    
        CLASSRATE(CLASSNUM,DIMNUM,t) = nRightCount/ALLNUM;
        fprintf(1,'t=%d,DIM= %d,RightCount=%d,RightRatio=%d\n',t,DIMNUM,nRightCount,CLASSRATE(CLASSNUM,DIMNUM,t));
        fprintf(fp,'t=%d,DIM= %d,RightCount=%d,RightRatio=%d\n',t,DIMNUM,nRightCount,CLASSRATE(CLASSNUM,DIMNUM,t));
    end
    

%     [plValue,plIndex] = sort(PseudoLoss);
%     for  test = 1:ALLNUM
%         hfx = zeros(1,CLASSNUM);
%         for t=1:TT/2
%             hfx = hfx + HHH(plIndex(t),:,test);            
%         end
%          [yValue,yClass] = max(hfx);
%          yResult(1,test) = yClass;
%     end
%      %*******计算识别率***************
%      nRightCount = 0;  
%      for i = 1:ALLNUM
%         if test_label(i) == yResult(1,i)
%             nRightCount = nRightCount + 1;
%         end
%     end 
%     CLASSRATE(CLASSNUM,DIMNUM) = nRightCount/ALLNUM;
%     fprintf(1,'t=%d,DIM= %d,RightCount=%d,RightRatio=%d\n',TT,DIMNUM,nRightCount,CLASSRATE(CLASSNUM,DIMNUM));
%     fprintf(fp,'t=%d,DIM= %d,RightCount=%d,RightRatio=%d\n',TT,DIMNUM,nRightCount,CLASSRATE(CLASSNUM,DIMNUM));

end  %DIMNUM
end
save('m2_cr.mat','CLASSRATE');
fclose(fp);







