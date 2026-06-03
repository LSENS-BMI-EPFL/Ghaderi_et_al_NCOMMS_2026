function v = fn_gram_schmidt_process(v)

nanix = isnan(v);
v(nanix)=0;

for ii = 1:1:size(v,2)
    %     v(:,ii) = v(:,ii) / norm(v(:,ii));
    for jj = ii+1:1:size(v,2)
        v(:,jj) = v(:,jj) - proj(v(:,ii),v(:,jj));
    end
end
end




    
function p = proj(u,v)
% This function projects vector v on vector u
p = (dot(u,v) / dot(u,u)) * u;
end

