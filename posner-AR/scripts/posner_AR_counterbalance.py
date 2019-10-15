# posner AR generation
import os
import pandas as pd
import numpy as np
from collections import Counter

# Parameters
# dir_main = '/Users/h/Documents/projects_local/fractional_factorials/posner-AR'
dir_posner = '/Users/h/Documents/projects_local/fractional_factorials/posner-AR'

# 0. For loop
for sub in list(range(1,151)):
    # 1. load AR generation ________________________________________________________
    cue_vfilename = os.path.join(dir_posner, 'design', 's01_cue-sequence', 'sub-' + '{:03d}'.format(sub) + '_cuesequence.csv')
    cue_v = pd.read_csv(cue_vfilename)

    # 2. count number of valids ________________________________________________________
    valid_map = {1: 'invalid', 0: 'valid'}
    cue_v['valid_type'] = cue_v['1'].map(valid_map)
    cue_v['cue'] = 0
    cue_v['target'] = 0
    a = dict(Counter(cue_v.valid_type))

    # 3 invalid cue left right ________________________________________________________
    invalid = np.repeat(['left', 'right'], int(a['invalid']/2))
    np.random.shuffle(invalid)
    invalid_loc = list(cue_v.loc[cue_v['valid_type'] == 'invalid'].index)

    for ind, loca in enumerate(invalid_loc):
        cue_v.loc[loca, 'cue'] = invalid[ind].copy()

    # 4 valid cue left right ________________________________________________________
    valid = np.repeat(['left', 'right'], int(a['valid']/2))
    np.random.shuffle(valid)
    valid_loc = list(cue_v.loc[cue_v['valid_type'] == 'valid'].index)
    # create half right and half left cue
    for ind, loca in enumerate(valid_loc):
        cue_v.loc[loca, 'cue'] = valid[ind].copy()

    # 5 target location ____________________________________________________________
    cue_v.loc[(cue_v.valid_type == 'invalid') & (cue_v['cue'] == 'left'), 'target'] = 'right'
    cue_v.loc[(cue_v.valid_type == 'invalid') & (cue_v['cue'] == 'right'), 'target'] = 'left'
    cue_v.loc[(cue_v.valid_type == 'valid') & (cue_v['cue'] == 'left'), 'target'] = 'left'
    cue_v.loc[(cue_v.valid_type == 'valid') & (cue_v['cue'] == 'right'), 'target'] = 'right'

    save_filename = os.path.join(dir_posner, 'design', 's02_counterbalance', 'sub-' + '{:03d}'.format(sub) + '_task-posner_counterbalance.csv')
    cue_v.to_csv(save_filename)

# columns:
# condition type
# target location
# cue location
# fixation duration
