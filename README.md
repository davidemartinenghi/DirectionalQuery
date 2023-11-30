# Directional Queries
This is a swift project for testing effectiveness and efficiency of directional queries with a heap-based implementation using no index.

## Features

- Performs sequential linear and directional top-k queries given a CSV file containing the dataset.
- Reports statistics at the console.

## How to use

Experiments can be run on any CSV dataset through a call to the `experiment` function, which takes four parameters:
-  `name` : the name of the CSV dataset (without the `.csv` extension).
-  `attributes` : an array of `String`, each corresponding to an attribute of the CSV file to be used in the experiment.
-  `ks` : an array of `Int`, corresponding to the values of k to be tested in the experiment.
-  `beta` : an array of `Double`, corresponding to the values of beta to be tested in the experiment.

The experiment will consist of a series of tests on the data contained in the dataset called `name`, on the attributes listed in `attributes` and for every value of *k* in `ks` and every value of *beta* in `betas`.


The main file already includes several experiments and refers to the directory "~/cleanData", which can be changed by modifying the `datasetDir` variable directly in the code.
The above directory should contain the following CSV files:
- NBAstats2WithId.csv
- NBAstats3WithId.csv
- anti2dWithId.csv
- empWithId.csv
- householdWithId.csv
- synt2A1000000WithId.csv
- synt3A10000000WithId.csv
- synt3A1000000WithId.csv
- synt3A100000WithId.csv
- synt3A10000WithId.csv
- synt3A5000000WithId.csv
- synt3A500000WithId.csv
- synt3A50000WithId.csv
- synt4A1000000WithId.csv
- synt5A1000000WithId.csv
- synt6A1000000WithId.csv

All of these can be downloaded from https://www.dropbox.com/scl/fo/9pgg7kdx9txb113854x29/h?rlkey=7rcv56emiq6b4y8zrkeazyins&dl=0

Alternatively, you can comment out all calls to `experiment` and `syntheticExperiment` in the main file and run an experiment to a specific CSV dataset of your choice.

## Output
The output consists of statistical information printed at the console in a comma-separated format.
In particular, the output includes:
- `k` : output size
- `d` : number of dimensions
- `N` : dataset size
- `beta` : value of beta (i.e., the mean-distance parameter, where beta=1 means linear query)
- `avgPrec` : average precision
- `avgRec` : average recall
- `avgDist` : average distance or dispersion
- `cumulRec` : cumulative recall
- `time` : average execution time
- `cumulEvol` : cumulative exclusive volume
- `cumulGrid` : cumulative grid resistance
