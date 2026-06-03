function resp=movsum_pg(A,win_length,win_step)
st=1;
en=st+win_length-1;
flg=1;
while en<= length(A)
resp(flg)=sum(A(st:en));
st=st+win_step;
en=st+win_length-1;
flg=flg+1;
end