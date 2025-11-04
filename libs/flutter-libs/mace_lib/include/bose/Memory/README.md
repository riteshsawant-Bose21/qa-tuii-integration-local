# Memory

[DrStrange](../../../README.md) - [MACE](../../README.md) - [Source](../README.md) - Memory
  
## Overview

Memory is the *poorly* named directory that contains helper objects for managing heap allocated, contiguous memory blocks of arithmetic type and for providing a means for easily performing various arithmetic operations upon them in an optimized manner.

The impetus for, and benefit of, are many:

 1. Error reduction and leak prevention when dealing with heap memory
 2. Facilitation of various memory management methods and paradigms
 3. Facilitation of performance related efforts such as vectorization
 4. NaN aware methods and handling {equality, min/max, etc}

### Implementation

---
The classes available are [MemoryBlock](#memoryblock) and [MemoryBlockMatrix](#memoryblockmatrix). The latter being a collection of N instances of the former.  

See [Note](#note) for additional comments regarding the MemoryBlockMatrix implementation.

### MemoryBlock

---
The MemoryBlock class is the core object responsible for managing heap allocated, contiguous memory blocks, of arithmetic types and for providing a means for easily performing various arithmetic operations upon them in an optimized manner. 

Most methods have been optimized to leverage auto vectorization. The [Advanced Vector Extension](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions) instruction set being used is determined at build time via a build switch. Typically the [AVX](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions#Advanced_Vector_Extensions) set is used as it is the oldest and has the most market penetration.

An area for performance improvement is to add [expression templates](https://en.wikipedia.org/wiki/Expression_templates). 

#### NaN Handling

MemoryBlock is _NaN_ aware in that most, if not all, methods that can be adversely effected by _NaN_'s have special handling to avoid the ill effects.

Take equality for example. _NaN_'s are never equal, which means that the equality operator `operator==` must ensure that it is not comparing _NaN_'s before declaring inequality. As must `fuzzyEqual`, `min`, `max`, `indexOfMin`, `indexOfMax` and various other methods.

In floating-point cases there are other classifications such as subnormal, infinity or negative zero that may be undesirable. Further, only the caller will know when these case are or are not desirable. As such there are methods available to `replace` or `purge` values by category.

For example `std::atan2` is sign aware and does not treat 0 as equal to -0, despite `0.0 == -0.0` evaluating to true. Further, the following is true for `std::atan2`, which can cause adverse effects.
 - If y is ±0 and x is negative or -0, ±π is returned
 - If y is ±0 and x is positive or +0, ±0 is returned

Thus being able to replace -0 with 0 is necessary in some cases, and can easily be achieved as such `foo.replace(MB64f::Category::NegativeZero, 0.0);`

#### Helpers

There are various helper methods available such as :
- Trigonometric functions `cos`, `sin`, and `exp`,
- [Linear](https://en.wikipedia.org/wiki/Linear_interpolation#Linear_interpolation_between_two_known_points) and [bilinear](https://en.wikipedia.org/wiki/Bilinear_interpolation#Unit_square) interpolation,
- rounding to _n_ points of precision
- `apply` a `std::function` to each element
- `clamp` to range
- Test if all elements are positive or negative values
- Test if all elements are zero
- `set` all elements to the same value or incrementally
- `tokenize` to create a string with caller specified precision and delimiter
- `abs` absolute value
- `sum` of all elements
- `fuzzyEqual` with error tolerance (default is 1e-12)

#### Maths

MemoryBlock fully supports all arithmetic and compound arithmetic operations with MemoryBlock's and scalars of the same type. 

In order to execute any `lhs` to `rhs` operation, the following must evaluate to true `lhs.size() == rhs.size()`.  The resultant size is `lhs.size()`.

If `rhs` is a scalar, a temporary MemoryBlock of size `lhs.size()` is created and filled with the scalar value before proceeding with the operation; thus only a single path exists for each operation.

### MemoryBlockMatrix

---
The MemoryBlockMatrix class is a collection of MemoryBlock objects. It is row major, such that a M x N matrix is comprised of M MemoryBlocks of N length. Jagged matrix are not allowed, meaning that all rows must have the same length.

#### Note 

>This is not the most ideal approach from a performance perspective, however from an implementation perspective it was considerably faster. And considering the use cases and involved time frame, this was by far the better option at the time of writing. Should the need for solving large linear equations increase, there are plenty of available solvers available. Until such time, this approach is sufficient.

The level of math support offered by this class is limited to what was needed for the calculations of the MACE engine at the time of writing. The math that is supported mimics the behavior of the Matlab matrix and will yield the same results.

#### Matrix Composition

There are various methods available for getting and setting matrix contents by row, partial row, column, and partial column; as well as an `extract` method for extraction of a matrix subset. 

Additionally there are methods for some of the common matrix types such as square, rectangular, diagonal, and triangular; as well as the associated create, get, set and test methods.

These, combined with the constructors, `set`, and `resize` methods yield a simple and easy to use matrix class. Moreover, it is now considerably easier when porting from Matlab or using Matlab scripts as a reference.

#### Matrix Math

##### Addition

In  in order to execute `lhs + rhs`, the following must evaluate to true `lhs.rows() == rhs.rows() && lhs.cols() == rhs.cols()` . The resultant matrix is size `lhs.rows()` x `rhs.cols()`

##### Subtraction

In  in order to execute `lhs - rhs`, the following must evaluate to true `lhs.rows() == rhs.rows() && lhs.cols() == rhs.cols()`. The resultant matrix is size `lhs.rows()` x `rhs.cols()`

##### Multiplication

In order to execute `lhs * rhs`, the following must evaluate to true `lhs.cols() == rhs.rows()`.  The resultant matrix is size `lhs.rows()` x `rhs.cols()`

This is a computationally expensive operation and as such there is no shortage of [efficiency algorithms](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm) available.  None of which are specifically being used by this implementation. Primarily due to lack of need, see also [Note](#note).  Our current implementation is taking approximately 13ms to execute a 28x4097 * 4097x28 operation; which is more than performant enough for our existing needs of 28x4097 * 4097x1 and 4097x28 * 28x1.

##### Division

In order to execute `lhs / scalar`, ye need but ask. The resultant matrix is size `lhs.rows()` x `lhs.cols()` 

In order to execute `lhs / rhs ` , the following must evaluate to true `lhs.isSquare() && rhs.rows() == lhs.rows()`. The resultant matrix is size `lhs.rows()` x `rhs.cols()`

This is matrix left division, or Matlab mldivide, which solves the system of linear equations <a href="https://www.codecogs.com/eqnedit.php?latex=Ax=b" target="_blank"><img src="https://latex.codecogs.com/svg.latex?Ax=b" title="Ax=b" /></a>.  See [Decomposition](#decomposition) for more information. 

##### Decomposition

The matrix [decomposition](https://en.wikipedia.org/wiki/Matrix_decomposition) method being used is a [LU factorization with partial pivoting](https://en.wikipedia.org/wiki/LU_decomposition#LU_factorization_with_partial_pivoting). Not only is this method numerically stable, but it's the method used by Matlab's matrix left division operation; and parity with Matlab is critical.

The [Gaussian elimination](https://en.wikipedia.org/wiki/LU_decomposition#Using_Gaussian_elimination) algorithm is being used by this implementation, which requires only <a href="https://www.codecogs.com/eqnedit.php?latex={\textstyle\frac{2}{3}}n^{3}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?{\textstyle\frac{2}{3}}n^{3}" title="{\textstyle\frac{2}{3}}n^{3}" /></a> floating-point operations.
