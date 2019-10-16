import pandas as pd
import ntpath
import os
import glob
import numpy as np
from decimal import Decimal


# jitter _______________________________________________________________________
main_dir = '/Users/h/Documents/projects_local/fractional_factorials/posner-AR/design'

for ind in range(30):
    # 1) load txt save_filename ________________________________________________
    jitter_filename = os.path.join(main_dir, 's02_jitter',
    'posner_Events_best_design_of_10000_under_ideal_length_sec_ver-'+str('{0:03d}'.format(ind+1))+'.txt')
    basename = os.path.splitext(ntpath.basename(jitter_filename))[0]
    opti = pd.read_csv(jitter_filename, sep = "\t")

    # 2) round number 1 decimal and zero pad ___________________________________
    opti_r = opti.copy()
    opti_r['ISI1'] = opti_r['ISI1'].astype(float).round(decimals=1)
    # 3) calculated sum ________________________________________________________
    total = opti_r['ISI1'].sum()

    # 4) if sum is smaller than 240 sec, _______________________________________
    # randomly select indices and add 240/number _______________________________
    if total < 240:
        diff = 240 - total
        increments = diff / 10

        subset = opti_r.loc[opti_r.ISI1 > 1.5,].sample(n=10)
        subset.ISI1  = subset.ISI1 + increments
        for num in range(0,len(subset)):
            opti_r.iloc[subset.iloc[num].name] = subset.iloc[num]
    # 5) if sum is greater than 240 sec, _______________________________________
    # identify those greater than 1.5 and subtract 240/number __________________
    elif total >= 240:
        diff = abs(240-total)
        increments = diff / 20
        subset = opti_r.loc[opti_r.ISI1 > 1.5,].sample(n=20)
        subset.ISI1  = subset.ISI1 - increments
        for num in range(0,len(subset)):
            opti_r.iloc[subset.iloc[num].name] = subset.iloc[num]

    opti_r.drop("Unnamed: 4", axis=1, inplace=True)
    save_filename = os.path.join(dir_posner, 'design', 's03_updatejitter', basename + '.csv')
    opti_r.to_csv(save_filename,index=False)
