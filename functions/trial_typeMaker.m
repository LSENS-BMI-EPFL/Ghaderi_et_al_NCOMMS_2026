function trial_type=trial_typeMaker(whisker_stim,context)

for itrail=1:length(whisker_stim)
stim=whisker_stim(itrail);
tone=context(itrail);

if stim==1 & strcmp(tone,'go_tone')
  trial_type(itrail)  =1;
end

if stim==0 & strcmp(tone,'go_tone')
  trial_type(itrail)  =2;
end

if stim==1 & strcmp(tone,'nogo_tone')
  trial_type(itrail)  =3;
end

if stim==0 & strcmp(tone,'nogo_tone')
  trial_type(itrail)  =4;
end

if stim==1 & strcmp(tone,'no_tone')
  trial_type(itrail)  =5;
end

end

