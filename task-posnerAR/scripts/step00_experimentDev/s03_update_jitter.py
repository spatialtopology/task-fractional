#!/usr/bin/env python
"""
This code adjusts the jitter files (creates via s02_posner_jitter_sim.m)
so that the total length of the experiment is kept constant across simulations

parameters to tweak:
* main_dir
* total_jitter_length: 300 e.g. 120 trials * average jitter 2.5s = 300 s
* num_trials_to_change: 10 e.g. adjust jitter for a subset of 10 trials
"""

import pandas as pd
import ntpath
import os
import glob
import numpy as np
from decimal import Decimal

__author__ = "Heejung Jung"
__version__ = "1.0.1"
__email__ = "heejung.jung@colorado.edu"
__status__ = "Production"


# parameters to change _______________________________________________________________________
main_dir = '/Users/h/Documents/projects_local/fractional_factorials/task-posnerAR/design'
total_jitter_length = 300
num_trials_to_change1 = 10
num_trials_to_change2 = 20
update_dir = os.path.join(main_dir, 's03_updatejitter')
if not os.path.exists(update_dir):
    os.makedirs(update_dir)
for ind in range(30):
    # 1) load txt save_filename ________________________________________________
    jitter_filename = os.path.join(main_dir, 's02_jitter',
    'posner_Events_best_design_of_10000_under_ideal_length_sec_ver-'+str('{0:03d}'.format(ind+1))+'.txt')
    basename = os.path.splitext(ntpath.basename(jitter_filename))[0]
    opti = pd.read_csv(jitter_filename, sep = "\t")

    # 2) round number 2 decimal points ___________________________________
    opti_r = opti.copy()
    opti_r['ISI1'] = opti_r['ISI1'].astype(float).round(decimals=1)
    # 3) calculated sum ________________________________________________________
    total = opti_r['ISI1'].sum()

    # 4) if sum is smaller than 240 sec, _______________________________________
    # randomly select indices and add 240/number _______________________________
    if total < total_jitter_length:
        diff = total_jitter_length - total
        increments = diff / num_trials_to_change1

        subset = opti_r.loc[opti_r.ISI1 > 1.5,].sample(n=num_trials_to_change1)
        subset.ISI1  = subset.ISI1 + increments.round(2)
        for num in range(0,len(subset)):
            opti_r.iloc[subset.iloc[num].name] = subset.iloc[num]

    # 5) if sum is greater than 240 sec, _______________________________________
    # identify those greater than 1.5 and subtract 240/number __________________
    elif total >= total_jitter_length:
        diff = abs(total_jitter_length-total)
        increments = diff / num_trials_to_change2
        subset = opti_r.loc[opti_r.ISI1 > 1.5,].sample(n=num_trials_to_change2)
        subset.ISI1  = subset.ISI1 - increments.round(2)
        for num in range(0,len(subset)):
            opti_r.iloc[subset.iloc[num].name] = subset.iloc[num]

    opti_r['ISI1'] = opti_r['ISI1'].astype(float).round(decimals=1)
    opti_r['ISI1'] = opti_r['ISI1'].apply(lambda x: '{0:0>2}'.format(x))
    opti_r.drop("Unnamed: 4", axis=1, inplace=True)
    save_filename = os.path.join(main_dir, 's03_updatejitter', basename + '.csv')
    opti_r.to_csv(save_filename,index=False)
