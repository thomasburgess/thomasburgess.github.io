---
title: Rectangle areas!
tags:
  - blog
  - area
  - maths
  - kid
article_header:
  type: cover
  image:
    src: /assets/images/2024-07-30/skyline.png
mathjax: true
description: Dad & kid Exploring Areas of Rectangles and Squares.
---

*Dad & kid Exploring Areas of Rectangles and Squares.*

Recently, I did a small exploration of the areas of rectangles and squares with my 7-year-old kid who loves learning about math. 
Here we consider rectangles with two positive integer side lengths, $$a$$ and $$b$$. 
The area of a rectangle is $$A = a \cdot b$$, and its   circumference is $$C = 2a + 2b$$. Together, we computed $$A$$ for various $$a$$ and $$b$$ with increasing square side $$s$$.

| $$s$$ | $$a$$ | $$b$$ | $$A$$ | Comment |
|:----|:----|:----|:----|:--------------|
|   2 |   1 |   3 |   3 | *One less than square* |
|   2 |   2 |   2 |   4 | *Square!*       |
|   2 |   3 |   1 |   4 | *Same as first row!* |
|   3 |   1 |   5 |   5 | *Four less than square* |
|   3 |   2 |   4 |   8 | *One less than square* |
|   3 |   3 |   3 |   9 | *Square!*       |
|   4 |   1 |   7 |   7 | *Nine less than square* |
|   4 |   2 |   6 |  12 | *Four less than square* | 
|   4 |   3 |   5 |  15 | *One less than square!* |
|   4 |   4 |   4 |  16 | *Square!*       |

I should note, the basic observations here were done by someone who only knows basic arithmetic operations and is curious. I added some formula to explain the ideas better to myself.

## Observations

My kid made some exciting observations:

1. Given a fixed circumference, the area $$A$$ is largest when the rectangle is a square, that is, when $$a = b = s$$.
2. When the sides are one unit shorter and one unit longer than $$s$$, the area is always one unit smaller than $$s^2$$.

### First observation

Let's investigate the first observation. Suppose the sides of the rectangle are $$a = s - n$$ and $$b = s + n$$, where $$n$$ is an offset such that $$|n| < s$$. With this setup, we have:
\\[
\begin{aligned}
    C = 2(s - n) + 2(s + n) = 4s \\\ 
    A = (s + n)(s - n) = s^2 - n^2
\end{aligned}
\\]
Since $$s^2$$ and $$n^2$$ are positive, the area $$A$$ is largest when $$n = 0$$, which proves the first observation.

### Second observation

Now, let's examine the second observation. The difference in areas between a square and a rectangle with sides $$s - n$$ and $$s + n$$ is:
\\[
\Delta A = s^2 - (s + n)(s - n) = s^2 - (s^2 - n^2) = n^2.
\\]
So, indeed, for $$n = 1$$, the difference in area is $$1$$.

## Final observation

Finally, let's consider also negative $$n$$, and examine $$A$$ for $$s=4$$ and $$s=5$$:

| n  | a | b |  A | s=4 chart |
|:---|:--|:--|:---| :--- | 
| -3 | 1 | 7 | 7 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
| -2 | 2 | 6 | 12 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
| -1 | 3 | 5 | 15 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare$$ |
|  0 | 4 | 4 | 16 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare$$ $$\blacksquare$$ |
|  1 | 5 | 3 | 15 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare$$ |
|  2 | 6 | 2 | 12 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
|  3 | 7 | 1 | 7 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |

| n  | a | b |  A | s=5 chart |
|:---|:--|:--|:---| :--- | 
| -4 | 1 | 9 |  9 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
| -3 | 2 | 8 | 16 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
| -2 | 3 | 7 | 21 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
| -1 | 4 | 6 | 24 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare$$ |
|  0 | 5 | 5 | 25 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare$$ $$\blacksquare$$ |
|  1 | 6 | 4 | 24 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare$$ |
|  2 | 7 | 3 | 21 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
|  3 | 8 | 2 | 16 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |
|  4 | 9 | 1 |  9 | $$\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare\blacksquare$$ |

We chose to call this a skyscraper plot (we drew ours vertically).
We observed that this skyscraper is actually a bunch of squares stacked. First, a 1x1 square then a 3x3, then 5x5, and so on. With this we can derive a fun formula for the area of any skyscraper:

\\[
A(s) = \sum_{n=1}^{s} (2n-1)^2 = \frac{1}{3}s(4s^2 - 1)\,.
\\]

(Simplified formula from [OEIS](https://oeis.org/A000447)).

This simple problem was a lot more fun than I expected, and I found the final 
formula surprisingly beautiful.
