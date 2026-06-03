

function [spikeData]=addGloubalCluIsterID(spikeData)
en=0;
for SessionCounter=1:length(spikeData.SessionName)
    ClusterIDinsession= 1:length(spikeData.cluster{SessionCounter});
    index=sum(en)+ClusterIDinsession;
    en=[en;ClusterIDinsession(end)];
    spikeData.GlobalclusterID{SessionCounter,1}=index;
end




