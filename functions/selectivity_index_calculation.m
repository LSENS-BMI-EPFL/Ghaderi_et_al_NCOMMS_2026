
function [discrimination_index,p_value,X,Y,auc]=selectivity_index_calculation(data,labels,method,permutations,nboot)

switch method

    case 'bootpermut'
        opt = statset('UseParallel',true);
        [AUCboot]=bootstrp(nboot,@(x,y)naghdi(x,y),labels,data,'Options',opt);
        index_boot=(AUCboot-0.5)*2;
        parfor i=1:permutations
            permlabels=labels(randperm(length(labels)));
            [~,~,~,auc_rand] = perfcurve(permlabels,data,1);
            index_rand(i)=(auc_rand-0.5)*2;
        end
        for i=1:nboot
            p_value(i)= mean( abs(index_boot(i)) <= abs(index_rand),2 );
        end
        p_value=mean(p_value);
        discrimination_index=mean(index_boot);
        % without bootstarp
    case 'permut'
        [xboot,yboot,~,auc] = perfcurve(labels,data,1);
        discrimination_index=(auc-0.5)*2;

        parfor i=1:permutations
            permlabels=labels(randperm(length(labels)));
            [~,~,~,auc_rand] = perfcurve(permlabels,data,1);
            index_rand(i)=(auc_rand-0.5)*2;
        end
        p_value=mean( abs(discrimination_index) <= abs(index_rand) );

        % perc=prctile(index_rand,[2.5,97.5]);
        % p=index<perc(1) | index>perc(2);
        % p=~p;
end
%%

auc=1;
X=1;
Y=1;


end

function [AUC]=naghdi(labels,data)
[~,~,~,AUC]=perfcurve(labels,data,1);
end