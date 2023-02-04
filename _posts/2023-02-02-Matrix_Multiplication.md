---
title: Optimizing matrix multiplication
tags:
  - blog
  - python
  - numpy
  - coding
  - maths
  - matrix
mathjax: true
#article_header:
#  type: cover
#  image:
#    src: /assets/images/2022-10-20/header.png
#image: /assets/images/2022-10-20/header_crop.png
categories: blog
author: thomasburgess
description: Optimizing slow matrix operations
---

# Introduction

I was asked to speed the inner loop that runs many times inside a 
[Markov Chain Monte Carlo](https://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo).

The slowest part of each iteration is taking the product of the [Z-scores](https://en.wikipedia.org/wiki/Standard_score) of a constant matrix, $$X$$, and float-valued vectors $$u$$ or $$v$$. Here, $$X$$ is a tall $$n \times m$$ matrix with $$n=45000$$ and $$m=3$$ with all elements in $$X$$ are $$-1$$, $$0$$ or $$1$$. The vectors $$u$$ and $$v$$ have lengths $$m$$ (long) and $$n$$ (short) respectively.

\\[
    a = \left(\frac{X-\mu_X}{\sigma_X}\right)^T u
    \,,\quad\,
    b = \left(\frac{X-\mu_X}{\sigma_X}\right) v \,.
\\]

This post is about different approaches to improving performance. Possibly, some insights here are applicable beyond the details of the specific problem.

## Project setup

I wrote and evaluated this code in a [jupyter lab (v3.5.2)](https://jupyter.org) notebook in [python (v3.10.4)](https://www.python.org) on my M1-pro MacBook Pro. Additionally, the [numpy (v1.22.4)](https://numpy.org) and [scipy (v1.8.1)](https://scipy.org) packages were installed. 

{% details Click to expand imports for python code... %}
```python
# Imports
import numpy as np
from scipy.linalg import blas
from scipy.sparse import csc_matrix
```
{% enddetails %}

### Generating data

A random $$X$$ is generated with `make_X`. 
This generates an $$r\times c$$ matrix $$M$$ with uniform random numbers,
and return a version with elements $$-1$$ when $$M_{ij}<p$$,
$$+1$$ when $$M_{ij} > 1-p$$, and $$0$$ otherwise. 
For this data, `dtype` can be set to 
[`np.byte`](https://numpy.org/doc/stable/reference/arrays.scalars.html#numpy.byte).
The vectors $$u$$ and $$v$$ are generated directly with the random number generator.

{% details Click to expand data generation python code... %}
```python
def make_X(rows, cols, rng, prob):
    """Generate random data

    Args:
        rows (int): Number of rows to generate
        cols (int): Number of columns to generate
        rng (np.random.Generator): Random number generator instance to use
        prob (float): probability of getting -1 or 1

    Returns:
        np.ndarray: rows x cols Matrix with -1, 0, 1 elements
    """
    return np.where(M < prob, -1, np.where(M > 1 - prob, 1, 0)).astype(np.byte)


# Constants
ROWS = 45000  # Random X matrix rows
COLS = 3  # Random X matrix columns
SEED = 1337  # Random seed
PROB = 1 / 10  # Probability of -1 and +1 in matrix

# Get the random number generator
rng = np.random.default_rng(SEED)

# Make X matrix and e vector
X = make_X(rows=ROWS, cols=COLS, rng=rng, prob=PROB)
u = rng.random(size=ROWS)
v = rng.random(size=COLS)

# Mean and std for Z score calculation
X_mu = np.mean(X, axis=0)
X_sigma = np.std(X, axis=0)
```
{% enddetails %}

### Evaluating calculations

Different implementations are tested using `time_calc`. 
It asserts that the function reproduces a known output. 
Furthermore, it measures performance with the 
[`%timeit`](https://docs.python.org/3/library/timeit.html) 
notebook magic that only works in a notebook.

{% details Click to expand `time_calc` python code... %}

```python
def time_calc(calc, expected=None, tag="", **kwargs):
    """
    Args:
        calc (callable): function to evaluate with keyword arguments
        expected (optional): known output to compare to calc output
        tag (str): Tag to print to remember what was evaluated
        kwargs (dict): keyword arguments to pass to calc
    """
    if tag:
        print(f"--- [{tag}] ---")
    if expected is not None:
        np.testing.assert_almost_equal(calc(**kwargs), expected)
    %timeit calc(**kwargs)
```
{% enddetails %}


## Problem 1 - long vector $$u$$

The baseline implementation `calc_baseline` provides the known 
output (`expected`) and performance data to compare other approaches.

```python
def calc_baseline(X, u, X_mu, X_sigma):
    return ((X - X_mu) / X_sigma).T @ u

# Compute expected result, to be used in subsequent calls to time_calc
expected = calc_baseline(X=X, u=u, X_mu=X_mu, X_sigma=X_sigma)
```

{% details Click to expand `time_calc` call for `calc_baseline`... %}

```python
time_calc(
    calc=calc_baseline,
    tag="baseline",
    expected=expected,
    X=X,
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
)

>>> --- [blas] ---
>>> 1.02 ms ± 4.42 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
```

{% enddetails %}

One loop takes 1 ms. If it runs a million times, the baseline implementation contributes 15 minutes to the run time.

As $$X$$, $$\mu_X$$, and $$\sigma_X$$ are constant, an obvious improvement would be to pre-calculated the normalized matrix:

\\[
X_Z = \frac{X - \mu_X}{\sigma_X}\,.
\\]

```python

def calc_Z(X_Z, u):
    return X_Z @ u
```

{% details Click to expand `time_calc` call for `calc_Z`... %}
```python
time_calc(calc=calc_Z, tag="Z", expected=expected, X_Z=((X - X_mu) / X_sigma).T, u=u)

>>> --- [Z] ---
>>> 447 µs ± 3.51 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
```
{% enddetails %}

which already cuts the baseline runtime in more than half! 


### BLAS

Numpy uses [`BLAS`](https://netlib.org/blas/) behind the scenes. 
Sometimes it is faster to call BLAS directly.
SciPy exposes matrix-vector multiplication as 
[`dgemv`]( https://docs.scipy.org/doc/scipy/reference/generated/scipy.linalg.blas.dgemv.html#scipy.linalg.blas.dgemv). 
(Here, `d` stands for double precision `ge` for general matrix, and `mv` for matrix-vector). By giving `trans=1` to the method, there is no need to transpose the input matrix.

```python
def calc_blas(X, u, X_mu, X_sigma):
    return blas.dgemv(1.0, (X - X_mu) / X_sigma, u, trans=1)


def calc_blas_Z(X_Z, u):
    return blas.dgemv(1.0, X_Z, u, trans=1)
```

BLAS performance depends on the memory layout of the arrays used, this can be changed by [copying](https://numpy.org/doc/stable/reference/generated/numpy.copy.html) arrays to F (FORTRAN) order. The same is true for `numpy` routines, so to evaluate direct BLAS calls, I will compare plain calls, calls with F ordering, and non-BLAS calls with F-ordering.

{% details Click to expand `time_calc` calls and results... %}

```python
time_calc(
    calc=calc_blas, tag="blas", expected=expected, X=X, u=u, X_mu=X_mu, X_sigma=X_sigma
)
time_calc(
    calc=calc_blas_Z, tag="blas Z", expected=expected, X_Z=((X - X_mu) / X_sigma), u=u
)
time_calc(
    calc=calc_blas,
    tag="blas F",
    expected=expected,
    X=X.copy(order="F"),
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
time_calc(
    calc=calc_blas_Z,
    tag="blas Z F",
    expected=expected,
    X_Z=((X - X_mu) / X_sigma).copy(order="F"),
    u=u,
)
time_calc(
    calc=calc_baseline,
    tag="baseline F",
    expected=expected,
    X=X.copy(order="F"),
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
time_calc(
    calc=calc_Z,
    tag="Z F",
    expected=expected,
    X_Z=((X - X_mu) / X_sigma).copy(order="F").T,
    u=u,
)

>>> --- [blas] ---
>>> 642 µs ± 9.64 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
>>> --- [blas Z] ---
>>> 72.3 µs ± 334 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
>>> --- [blas F] ---
>>> 129 µs ± 4.5 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
>>> --- [blas Z F] ---
>>> 29.6 µs ± 149 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
>>> --- [baseline F] ---
>>> 133 µs ± 3.69 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
>>> --- [Z F] ---
>>> 30.4 µs ± 671 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
```
{% enddetails %}

Just using BLAS does make the code run 2-6x faster. Changing to F-ordered memory makes it 8-15x faster. This improvement also happens for the original Numpy-only functions.

Lesson: memory layout can make a big difference. With the correct input, BLAS doesn't improve performance. The Z method with F-ordering now is 35x faster than the baseline method!

### Algebraic manipulation

The Z-method misses the structure of $$X$$. The product $$X^T u$$ should run faster than $$(X-X_\mu)^T u$$ as the matrix is all integers and have many zeroes. And by rearranging the expression for $$a$$, it is possible to use this instead.

\\[
    a = 
    \frac{1}{X_\sigma} \left( X^T u - X_\mu \sum_i u \right)\,.
\\]

```python
def calc_rearranged(X, u, X_mu, X_sigma):
    return (X.T @ u - X_mu * u.sum()) / X_sigma

```

{% details Click to expand `time_calc` calls and results.for `calc_rearranged`.. %}
```python
time_calc(
    calc=calc_rearranged,
    tag="rearranged",
    expected=expected,
    X=X,
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
)

>>> --- [rearranged] ---
>>> 84.8 µs ± 1.25 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
```
{% enddetails %}

This runs 84$$\mu$$s, which is much better than the baseline, but still worse than using $$X_Z$$ with F-ordering.
Here, tricks with memory layout or using BLAS no longer improves the performance. 
Perhaps, `bool` matrices are even faster? Taking $$X_+$$ as a boolean matrix with `True` for positive elements in $$X$$, and similarly, for negatives with $$X_-$$, the expression can be further rearranged:
\\[
    a = 
    \frac{1}{\sigma_X} \left( X_+^T u - X_-^T u - \mu_X \sum_i  u_i \right)\,.
\\]


```python
def calc_split(u, X_mu, X_sigma, X_plus, X_minus):
    return (X_plus.T @ u - X_minus.T @ u - X_mu * u.sum()) / X_sigma
``` 

{% details Click to expand `time_calc` calls and results for `calc_split`... %}

```python
time_calc(
    calc=calc_split,
    tag="split",
    expected=expected,
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
    X_plus=X == 1,
    X_minus=X == -1,
)

>>> 156 µs ± 293 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
```
{% enddetails %}

That's half the speed of `calc_rearranged`. Building on the split method, one can avoid the matrix product altogether! Let $$d_{i,j}^\pm$$ be the indices $$i,j$$ corresponding to the non-zero elements in $$X_\pm$$. Now the product becomes $$X_+^T u = \sum_iu_{d_{i,j}}^+ $$, so that

\\[
 a = \frac{1}{\sigma_X} \left( \sum_{i} u_{d_{i,j}}^+ - \sum_i u_{d_{i,j}}^- - \mu_X \sum_i u_i \right)\,.
\\]

```python

def extract_indices(X, q):
    rc = np.argwhere(X == q)
    return tuple(np.extract(rc[:, 1] == i, rc[:, 0]) for i in range(X.shape[1]))


def calc_index(u, X_mu, X_sigma, X_idx_plus, X_idx_minus):
    return (
        np.fromiter(
            (
                u[X_idx_plus[i]].sum() - u[X_idx_minus[i]].sum()
                for i in range(X_mu.shape[0])
            ),
            u.dtype,
        )
        - X_mu * u.sum()
    ) / X_sigma

```

{% details Click to expand `time_calc` calls and results for `calc_index`... %}

```python
time_calc(
    calc=calc_index,
    tag="index",
    expected=expected,
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
    X_idx_plus=extract_indices(X, 1),
    X_idx_minus=extract_indices(X, -1),
)

>>> 48.2 µs ± 221 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
```
{% enddetails %}

Not quite as good as the Z method with F-ordering. What performs the best likely depends on what data in $$X$$ happens to look like.

### Sparse matrices 

There are many 0s in the matrix, perhaps this problem can be approach using [sparse matrices](https://en.wikipedia.org/wiki/Sparse_matrix) can be useful, these are availible in [SciPy](https://docs.scipy.org/doc/scipy/reference/sparse.html). For this problem a [`csc_matrix`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csc_array.html#scipy.sparse.csc_array) is the best fit for $$X$$. As only $$X$$ changes, the method above work with the sparse inputs without any changes except for `calc_index` that doesn't use matrices at all.

{% details Click to expand `time_calc` calls and results... %}

```python
time_calc(
    calc=calc_baseline,
    tag="sparse baseline",
    expected=expected,
    X=csc_matrix(X, dtype=np.byte),
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
time_calc(
    calc=calc_Z,
    tag="sparse Z",
    expected=expected,
    X_Z=csc_matrix(((X - X_mu) / X_sigma).T, dtype=X_mu.dtype),
    u=u,
)
time_calc(
    calc=calc_rearranged,
    tag="sparse rearranged",
    expected=expected,
    X=csc_matrix(X, dtype=np.byte),
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
time_calc(
    calc=calc_split,
    tag="sparse split",
    expected=expected,
    u=u,
    X_mu=X_mu,
    X_sigma=X_sigma,
    X_plus=csc_matrix(X == 1, dtype=bool),
    X_minus=csc_matrix(X == -1, dtype=bool),
)

>>> --- [sparse baseline] ---
>>> 153 µs ± 6.08 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
>>> --- [sparse Z] ---
>>> 274 µs ± 94.4 ns per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
>>> --- [sparse rearranged] ---
>>> 64.7 µs ± 77 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
>>> --- [sparse split] ---
>>> 85 µs ± 101 ns per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
```
{% enddetails %}

Sparse matrices improve all the tested methods w.r.t. the baseline. Still, the index method is better, and the best way remains to use the Z-method with F-ordering.


## Problem 2 - short vector $$v$$

The baseline for this problem is very similar to the previous one. Only the transpose is missing. And the same trick with a pre-calculated $$Z$$ is possible
```python
def calc_baseline(X, v, X_mu, X_sigma):
    return ((X-X_mu)/X_sigma) @ v

def calc_Z(X_Z, v):
    return X_Z @ v

expected = calc_baseline(X=X, v=v, X_mu=X_mu, X_sigma=X_sigma)
```

Next, test `baseline` and `Z` for the original input, F-ordering and sparse matrices:

{% details Click to expand `time_calc` calls and results... %}

```python
time_calc(calc_baseline, tag="baseline", X=X, v=v, X_mu=X_mu, X_sigma=X_sigma)
time_calc(
    calc_baseline,
    tag="baseline F",
    X=X.copy(order="F"),
    v=v,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
time_calc(
    calc_baseline,
    tag="baseline sparse",
    expected=expected,
    X=csc_matrix(X, dtype=np.byte),
    v=v,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
time_calc(calc_Z, tag="Z", expected=expected, X_Z=(X - X_mu) / X_sigma, v=v)
time_calc(
    calc_Z,
    tag="Z F",
    expected=expected,
    X_Z=((X - X_mu) / X_sigma).copy(order="F"),
    v=v,
)
time_calc(
    calc_Z,
    tag="Z sparse",
    expected=expected,
    X_Z=csc_matrix((X - X_mu) / X_sigma, dtype=e.dtype),
    v=v,
)
time_calc(calc_baseline, tag="baseline", X=X, v=v, X_mu=X_mu, X_sigma=X_sigma)
time_calc(
    calc_baseline,
    tag="baseline sparse",
    expected=expected,
    X=csc_matrix(X, dtype=np.byte),
    v=v,
    X_mu=X_mu,
    X_sigma=X_sigma,
)
ti
time_calc(calc_Z, tag="Z", expected=expected, X_Z=(X - X_mu) / X_sigma, v=v)
time_calc(
    calc_Z,
    tag="Z sparse",
    expected=expected,
    X_Z=csc_matrix((X - X_mu) / X_sigma, dtype=v.dtype),
    v=v,
)

--- [baseline] ---
908 µs ± 68.9 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
--- [baseline F] ---
260 µs ± 47.7 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
--- [baseline sparse] ---
302 µs ± 42.6 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
--- [Z] ---
53.6 µs ± 1.26 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
--- [Z F] ---
29.2 µs ± 1.07 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
--- [Z sparse] ---
87.3 µs ± 1.2 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
```

{% enddetails %}

The most efficient calculation is using the Z-method with F-ordering.

## Summary

The baseline implementations were improved by pre-calculating the normalized matrix $$X_Z$$, using SciPy's direct interface to BLAS routines, algebraically rearranging the expression, and by using sparse matrices. Sparse matrices can help, especially when the data is sparse enough. It is also possible to exploit the structure of the matrix to get similarly good performance. Overall, the best performance was achieved by using the pre-normalized matrix with F-ordering of the array memory. Table 1 and 2 summarizes the achieved speed-ups for the different improvements.

{% figure [caption:"**Table 1**: Problem 1 - Durations and speed-ups w.r.t. baseline for all tests"] %}

| Method            | Duration (µs) | Speed-up |
|-------------------|---------------|----------|
| Baseline          | 1020.0        | 1.00     |
| Z                 | 448.0         | 2.28     |
| BLAS              | 642.0         | 1.59     |
| BLAS Z            | 72.3          | 14.11    |
| BLAS F            | 129.0         | 7.91     |
| BLAS Z F          | 29.6          | 34.46    |
| Baseline F        | 133.0         | 7.67     |
| Z F               | 30.4          | 33.55    |
| Rearranged        | 83.4          | 12.23    |
| Split             | 156.0         | 6.54     |
| index             | 48.2          | 21.16    |
| sparse baseline   | 159.0         | 6.42     |
| sparse Z          | 276.0         | 3.70     |
| sparse rearranged | 65.6          | 15.55    |
| sparse split      | 85.8          | 11.89    |

{% endfigure %}

{% figure [caption:"**Table 2**: Problem 2 - durations and speed-ups w.r.t. baseline for all tests"] %}

|      Method     | Duration (µs) | Speed-up |
| --------------- | ------------- | -------- |
| baseline        |         908.0 |     1.00 |
| Baseline F      |         260.0 |     3.49 |
| Baseline sparse |         302.0 |     3.01 |
| Z               |          53.6 |    16.94 |
| Z F             |          29.2 |    31.10 |
| Z sparse        |          87.3 |    10.40 |

{% endfigure %}
