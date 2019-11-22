#!/usr/bin/env python

"""
This code first counterbalances the number of cue and targets,
based on the valid/invalid sequence from s01_AR_seq_generator.m

second, the updated jitters will be concatenated
to form a full counterbalance csv file.
"""

import os
import pandas as pd
import numpy as np
from collections import Counter
import random

__author__ = "Heejung Jung"
__version__ = "1.0.1"
__email__ = "heejung.jung@colorado.edu"
__status__ = "Production"


# Parameters _______________________________________________________________________
dir_posner = '/Users/h/Documents/projects_local/fractional_factorials/task-posnerAR'

# 0. For loop
for sub in list(range(1,151)):
    print(sub)
    cue_v = pd.DataFrame()
    invalid = []
    valid = []
# 1. load AR generation ________________________________________________________
    cue_vfilename = os.path.join(dir_posner, 'design', 's01_cue-sequence', 'sub-' + '{:03d}'.format(sub) + '_cuesequence.csv')
    cue_v = pd.read_csv(cue_vfilename, header = None)
    cue_v=cue_v.rename(columns = {0:'AR_invalid_sequence'})

# 2. count number of valids ________________________________________________________
    valid_map = {1: 'invalid', 0: 'valid'}
    cue_v['valid_type'] = cue_v.iloc[:,0].map(valid_map)
    cue_v['cue'] = 0
    cue_v['target'] = 0
    a = dict(Counter(cue_v.valid_type))

# 3 invalid cue left right ________________________________________________________

    if (a['invalid']%2) == 0:
        invalid = np.repeat(['left', 'right'], int(a['invalid']//2))
        np.random.shuffle(invalid)
        invalid_loc = list(cue_v.loc[cue_v['valid_type'] == 'invalid'].index)
        print(len(invalid_loc))
        print(len(invalid))
        for ind, loca in enumerate(invalid_loc):
            cue_v.loc[loca, 'cue'] = invalid[ind]

    else:
        invalid = np.repeat(['left', 'right'], int(a['invalid']//2))
        invalid = np.append(invalid, random.sample(set(['left','right']), 1))
        np.random.shuffle(invalid)
        invalid_loc = list(cue_v.loc[cue_v['valid_type'] == 'invalid'].index)
        print(len(invalid_loc))
        print(len(invalid))
        for ind, loca in enumerate(invalid_loc):
            cue_v.loc[loca, 'cue'] = invalid[ind]

# 4 valid cue left right ________________________________________________________
    if (a['valid']%2) == 0:
        valid = np.repeat(['left', 'right'], int(a['valid']//2))
        np.random.shuffle(valid)
        valid_loc = list(cue_v.loc[cue_v['valid_type'] == 'valid'].index)
        # create half right and half left cue
        for ind, loca in enumerate(valid_loc):
            cue_v.loc[loca, 'cue'] = valid[ind]
    else:
        valid = np.repeat(['left', 'right'], int(a['valid']//2))
        valid = np.append(valid, random.sample(set(['left','right']), 1))
        np.random.shuffle(valid)
        valid_loc = list(cue_v.loc[cue_v['valid_type'] == 'valid'].index)
        # create half right and half left cue
        for ind, loca in enumerate(valid_loc):
            cue_v.loc[loca, 'cue'] = valid[ind]

# 5 target location ____________________________________________________________
    cue_v.loc[(cue_v.valid_type == 'invalid') & (cue_v['cue'] == 'left'), 'target'] = 'right'
    cue_v.loc[(cue_v.valid_type == 'invalid') & (cue_v['cue'] == 'right'), 'target'] = 'left'
    cue_v.loc[(cue_v.valid_type == 'valid') & (cue_v['cue'] == 'left'), 'target'] = 'left'
    cue_v.loc[(cue_v.valid_type == 'valid') & (cue_v['cue'] == 'right'), 'target'] = 'right'

# 6. load jitter and combine with counterbalance sequence ________________________________________________________
    ind = sub%30
    jitter_filename = os.path.join(dir_posner, 'design', 's03_updatejitter',
        'posner_Events_best_design_of_10000_under_ideal_length_sec_ver-'+str('{0:03d}'.format(ind+1))+'.csv')
    jitter = pd.read_csv(jitter_filename, header = 0)
    # cue_v=cue_v.rename(columns = {0:'AR_invalid_sequence'})
    # cue_v['jitter'] = jitter['ISI1']
    cue_v.insert(0, "jitter", jitter['ISI1'], True)

    save_filename = os.path.join(dir_posner, 'design', 's04_counterbalance', 'sub-' + '{:04d}'.format(sub) + '_task-posner_counterbalance.csv')
    cue_v.to_csv(save_filename,index=False)
