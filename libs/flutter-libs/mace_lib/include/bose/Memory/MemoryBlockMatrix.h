#pragma once
#ifndef MEMORYBLOCKMATRIX_H
#define MEMORYBLOCKMATRIX_H

#include "MemoryBlock.h"

namespace bosepro
{
    /**
     * \class       MemoryBlockMatrix
     *
     * \brief       Matrix of MemoryBlock objects 
     *
     * \details     Row major, such that a M x N matrix is comprised of M MemoryBlocks of N length.
     *               Jagged matrix are not allowed, meaning all rows must have the same length.
     *
     *               The level of math support is as needed for the calculations of the engine.
     *               The math supported, mimics the behavior of a Matlab matrix and will yield the same results.
     *
     *               There are aliases for common primitives at the bottom of this file
     *
     *               See also MemoryBlock
     */
    template <typename Type>
    class MemoryBlockMatrix final
    {
    public:
                                    ~MemoryBlockMatrix()                                                        noexcept {free();}
                                    MemoryBlockMatrix(std::size_t rows = 0, std::size_t cols = 0, Type val = 0)          {resize(rows, cols, val);}
                                    MemoryBlockMatrix(std::initializer_list<MemoryBlock<Type>> vals, bool asRows = true) {set(vals, asRows);}
                                    MemoryBlockMatrix(const MemoryBlockMatrix& other)                                    : MemoryBlockMatrix(other.rows(), other.cols()){for(std::size_t i = 0; i < rows(); ++i)m_mba[i] = other.m_mba[i];}
                                    MemoryBlockMatrix(MemoryBlockMatrix&& other)                                noexcept : MemoryBlockMatrix(){swap(*this, other);}
        MemoryBlockMatrix&          operator=(MemoryBlockMatrix&& other)                                        noexcept {swap(*this, other); return *this;}
        MemoryBlockMatrix&          operator=(const MemoryBlockMatrix& other)                                            {auto tmp(other); swap(*this, tmp); return *this;}

                                    //NaN aware equality operators (exact, see also fuzzyEqual)
        friend bool                 operator!=(const MemoryBlockMatrix& lhs, const MemoryBlockMatrix& rhs)            {return !(lhs == rhs);}
        friend bool                 operator==(const MemoryBlockMatrix& lhs, const MemoryBlockMatrix& rhs)
                                    {
                                        bool equal = false;

                                        if(lhs.size() == rhs.size())
                                        {
                                            equal = true;

                                            //not auto vectorizable
                                            for(std::size_t i = 0; i < lhs.rows(); ++i)
                                            {
                                                if(lhs[i] != rhs[i])
                                                {
                                                    equal = false;
                                                    break;
                                                }
                                            }
                                        }

                                        return equal;
                                    }

                                    //NaN aware equality for all elements having same value
        inline bool                 operator!=(Type val)                                                const noexcept    {return !(operator==(val));}
        inline bool                 operator==(Type val)                                                const noexcept
                                    {
                                        bool success = false;

                                        if(isValid())
                                        {
                                            success = true;

                                            for(const auto& mb : m_mba)
                                            {
                                                if(mb != val)
                                                {
                                                    success = false;
                                                    break;
                                                }
                                            }
                                        }

                                        return success;
                                    }

                                    //Mathematical matrix notation indexing (without bounds checking)
        Type&                       operator()(std::size_t row, std::size_t col)                              noexcept {assert(row < rows()); assert(col < cols()); return m_mba[row][col];}
        const Type&                 operator()(std::size_t row, std::size_t col)                        const noexcept {assert(row < rows()); assert(col < cols()); return m_mba[row][col];}

                                    //Get elements by index
        MemoryBlock<Type>           operator()(const MBidx& idx)                                        const
                                    {
                                        MemoryBlock<Type> mb;

                                        if(isValid() && idx.isValid())
                                        {
                                            std::size_t r = 0;
                                            std::size_t c = 0;

                                            const std::size_t rows = this->rows();
                                            const std::size_t cols = this->cols();

                                            std::vector<Type> tmp;

                                            const auto& mbm = *this;

                                            for(std::size_t i = 0; i < idx.size(); i++)
                                            {
                                                r = static_cast<std::size_t>(std::floor(idx[i] / cols));
                                                c = static_cast<std::size_t>(idx[i] % cols);

                                                if(r < rows && c < cols)
                                                {
                                                    tmp.push_back(mbm(r, c));
                                                }
                                            }

                                            mb = std::move(MemoryBlock<Type>(tmp));
                                        }

                                        return mb;
                                    }

                                    //Addition: Both dimensions must match, result is lhs.cols() x lhs.rows()
        friend MemoryBlockMatrix    operator+(MemoryBlockMatrix lhs, const MemoryBlockMatrix& rhs)            noexcept
                                    {
                                        if(lhs.rows() == rhs.rows() && 
                                            lhs.cols() == rhs.cols() && 
                                            lhs.isValid() && rhs.isValid())
                                        {
                                            for(std::size_t i = 0; i < lhs.rows(); ++i)
                                            {
                                                lhs.m_mba[i] += rhs.m_mba[i];
                                            }
                                        }

                                        return lhs;
                                    }

                                    //Subtraction: Both dimensions must match, result is lhs.cols() x lhs.rows()
        friend MemoryBlockMatrix    operator-(MemoryBlockMatrix lhs, const MemoryBlockMatrix& rhs)            noexcept
                                    {
                                        if(lhs.rows() == rhs.rows() && 
                                            lhs.cols() == rhs.cols() && 
                                            lhs.isValid() && rhs.isValid())
                                        {
                                            for(std::size_t i = 0; i < lhs.rows(); ++i)
                                            {
                                                lhs.m_mba[i] -= rhs.m_mba[i];
                                            }
                                        }

                                        return lhs;
                                    }

                                    //Multiplication: lhs.cols() must match rhs.rows(), result is lhs.rows() x rhs.cols()
        friend MemoryBlockMatrix    operator*(const MemoryBlockMatrix& lhs, MemoryBlockMatrix rhs)            noexcept
                                    {
                                        MemoryBlockMatrix ans;

                                        if(lhs.cols() == rhs.rows() && lhs.isValid() && rhs.isValid())
                                        {
                                            //C = AB for an n × m matrix A and an m × p matrix B, then C is an n × p matrix

                                            const auto n = lhs.rows();
                                            const auto m = lhs.cols();//also rhs.rows()
                                            const auto p = rhs.cols();

                                            assert(m == rhs.rows());

                                            if(ans.resize(n, p))
                                            {
                                                //Because row access is far more cache friendly
                                                rhs.transpose();

                                                for(std::size_t i = 0; i < n; ++i)
                                                {
                                                    auto& lr = lhs[i]; //ith row
                                                    auto& ar = ans[i]; //ith row

                                                    //Sum product of lhs row and rhs rows
                                                    for(std::size_t j = 0; j < p; ++j)
                                                    {
                                                        ar[j] += (lr * rhs[j]).sum();
                                                    }
                                                }
                                            }
                                        }
                                        else
                                        {
                                            assert(0 && "Invalid inputs");

                                            //Nop
                                            ans = std::move(lhs);
                                        }

                                        return ans;
                                    }

                                    //Division: Handles Matlab left and right division mrdivide & mldivide
        friend MemoryBlockMatrix    operator/(MemoryBlockMatrix lhs, const MemoryBlockMatrix& rhs)            noexcept
                                    {
                                        MemoryBlockMatrix ans;

                                        if(lhs.isValid() && rhs.isValid())
                                        {
                                            if(lhs.isScalar() || rhs.isScalar())                        //left|right scalar
                                            {
                                                ans = lhs.isScalar() ? rhs / lhs(0, 0) : lhs / rhs(0, 0);
                                            }
                                            else if(lhs.isSquare() && rhs.cols() == lhs.cols())         //right square
                                            {
                                                assert(0 && "Not implemented, lack of need");
                                            }
                                            else if(lhs.isSquare() && rhs.rows() == lhs.rows())         //left square
                                            {
                                                ans = lhs.lup().solve(rhs);
                                            }
                                            else if(lhs.isRectangular() && rhs.cols() == lhs.cols())    //right rectangular
                                            {
                                                assert(0 && "Not implemented, lack of need");
                                            }
                                            else if(lhs.isRectangular() && rhs.rows() == lhs.rows())    //left rectangular
                                            {
                                                assert(0 && "Not implemented, lack of need");
                                            }
                                            else
                                            {
                                                assert(0 && "Not implemented, lack of need");           //Nop
                                            }
                                        }

                                        return ans;
                                    }

                                    //Division by scalar
        friend MemoryBlockMatrix    operator/(MemoryBlockMatrix lhs, Type rhs)                                noexcept
                                    {
                                        MemoryBlockMatrix ans;

                                        if(lhs.isValid())
                                        {
                                            ans = std::move(lhs);

                                            const auto r = math::SafeDivide(1.0, rhs);

                                            for(auto& row : ans.m_mba)
                                            {
                                                row *= r;
                                            }
                                        }

                                        return ans;
                                    }

                                    //Fuzzy equality with error tolerance (NaN tolerant)
        bool                        fuzzyEqual(const MemoryBlockMatrix& rhs, double err = 1e-12)        const
                                    {
                                        bool success = false;

                                        const auto& lhs = *this;

                                        if(lhs.rows() == rhs.rows() && lhs.cols() == rhs.cols())
                                        {
                                            if(lhs.isValid())
                                            {
                                                success = true;

                                                for(std::size_t i = 0; i < lhs.rows(); ++i)
                                                {
                                                    if(!lhs[i].fuzzyEqual(rhs[i], err))
                                                    {
                                                        success = false;
                                                        break;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                //Both are empty, so that's equality too
                                                success = true;
                                            }
                                        }

                                        return success;
                                    }

                                    //Validity and cols all have same size
        inline bool                 isValid()                                                           const noexcept
                                    {
                                        bool valid = false;

                                        if(rows())
                                        {
                                            const auto cols = this->cols();

                                            if(cols)
                                            {
                                                valid = true;

                                                for(auto const& mb : m_mba)
                                                {
                                                    //Test validity and ensure all cols have same size
                                                    if(!mb.isValid() || mb.size() != cols)
                                                    {
                                                        valid = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }

                                        return valid;
                                    }

                                    //Dimensions
        inline std::size_t          rows()                                                              const noexcept {return m_mba.size();}
        inline std::size_t          cols()                                                              const noexcept {return m_mba.size() ? m_mba[0].size() : 0;}
        inline std::size_t          size()                                                              const noexcept {return rows() * cols();}

                                    //Set contents, resizing as necessary : vals are set as rows by default, else cols
        bool                        set(std::initializer_list<MemoryBlock<Type>> vals, bool asRows = true)
                                    {
                                        bool success = false;

                                        if(validate(vals))
                                        {
                                            //Dimensions based on vals being row or col data
                                            const std::size_t r = asRows ? vals.size()       : sizeOfFirst(vals);
                                            const std::size_t c = asRows ? sizeOfFirst(vals) : vals.size();

                                            if(resize(r, c))
                                            {
                                                success = true;

                                                std::size_t n = 0;

                                                //Add vals
                                                for(auto& v : vals)
                                                {
                                                    success = asRows ? this->row(v, n++) : this->col(v, n++);

                                                    if(!success)
                                                    {
                                                        //Should never get here
                                                        assert(0 && "set failed");
                                                        free();
                                                        break;
                                                    }
                                                }
                                            }
                                        }

                                        return success;
                                    }

                                    //Resize
        bool                        resize(std::size_t rows, std::size_t cols, Type val = 0)
                                    {
                                        //Deallocate on any size disparity
                                        if(this->rows() != rows || this->cols() != cols)
                                        {
                                            free();
                                        }

                                        //Allocate if necessary
                                        if(rows > 0 && cols > 0 && !isValid())
                                        {
                                            m_mba.resize(rows, MemoryBlock<Type>(cols, val));

                                            if(!isValid())
                                            {
                                                //Deallocate to ensure we aren't half allocated
                                                free();
                                            }
                                        }

                                        return isValid();
                                    }

                                    //Deallocate and set size to 0,0
        void                        free()                                                                    noexcept {m_mba.clear();}

                                    //Get row by index : optional start col and count to get subset
        MemoryBlock<Type>           row(std::size_t row, std::size_t col = 0, std::size_t cols = -1)    const noexcept
                                    {
                                        MemoryBlock<Type> val;

                                        if(isValid() && row < rows() && col < this->cols())
                                        {
                                            if(cols > this->cols())
                                            {
                                                cols = this->cols();
                                            }

                                            const auto end = std::min(col + cols, this->cols());

                                            if(val.resize(end - col))
                                            {
                                                for(std::size_t i = col, j = 0; i < end; ++i, ++j)
                                                {
                                                    val[j] = (*this)[row][i];
                                                }
                                            }
                                        }

                                        return val;

                                    }

                                    //Set row by index : optional start col
        bool                        row(const MemoryBlock<Type>& mb, std::size_t row, std::size_t col = 0)    noexcept 
                                    {
                                        bool success = false;

                                        if(row < rows() && col + mb.size() <= cols())
                                        {
                                            success = true;

                                            const auto end = col + mb.size();

                                            auto& lhs = (*this)[row];

                                            for(std::size_t i = col, j = 0; i < end; ++i, ++j)
                                            {
                                                lhs[i] = mb[j];
                                            }
                                        }

                                        return success;
                                    }

                                    //Get col by index : optional start row and count to get subset
        MemoryBlock<Type>           col(std::size_t col, std::size_t row = 0, std::size_t rows = -1)    const noexcept
                                    {
                                        MemoryBlock<Type> val;

                                        if(isValid() && col < cols() && row < this->rows())
                                        {
                                            if(rows > this->rows())
                                            {
                                                rows = this->rows();
                                            }

                                            const auto end = std::min(row + rows, this->rows());

                                            if(val.resize(end - row))
                                            {
                                                for(std::size_t i = row, j = 0; i < end; ++i, ++j)
                                                {
                                                    val[j] = (*this)[i][col];
                                                }
                                            }
                                        }

                                        return val;
                                    }

                                    //Set col by index : optional start row
        bool                        col(const MemoryBlock<Type>& mb, std::size_t col, std::size_t row = 0)    noexcept 
                                    {
                                        bool success = false;

                                        if(col < cols() && row + mb.size() <= rows())
                                        {
                                            success = true;

                                            const auto end = row + mb.size();

                                            auto& lhs = (*this);

                                            for(std::size_t i = row, j = 0; i < end; ++i, ++j)
                                            {
                                                lhs(i, col) = mb[j];
                                            }
                                        }

                                        return success;
                                    }

                                    //Extract subset matrix from (r1, c1) thru (r2, c2) inclusive. r2/c2 as -1 for end of rows()/cols()
        MemoryBlockMatrix           extract(std::size_t r1, std::size_t c1, std::size_t r2 = -1, std::size_t c2 = -1) const noexcept
                                    {
                                        MemoryBlockMatrix mbm;

                                        math::SwapIf(r2, r1);
                                        math::SwapIf(c2, c1);

                                        if(r1 < rows() && c1 < cols() && isValid())
                                        {
                                            const auto rend = size() ? this->rows() - 1 : 0;
                                            const auto cend = size() ? this->cols() - 1 : 0;

                                            r1 = std::min(r1, rend);
                                            r2 = std::min(r2, rend);

                                            c1 = std::min(c1, cend);
                                            c2 = std::min(c2, cend);

                                            const auto rn = r2 - r1 + 1;
                                            const auto cn = c2 - c1 + 1;

                                            if(mbm.resize(rn, cn))
                                            {
                                                const auto& rhs = *this;

                                                for(std::size_t rr = r1, lr = 0; rr <= r2; ++rr, ++lr)
                                                {
                                                    for(std::size_t rc = c1, lc = 0; rc <= c2; ++rc, ++lc)
                                                    {
                                                        mbm(lr, lc) = rhs(rr, rc);
                                                    }
                                                }
                                            }
                                        }

                                        return mbm;
                                    }

                                    //Layout tests
        inline bool                 isNull()                                                            const noexcept {return rows() == 0 || cols() == 0;}
        inline bool                 isRow()                                                             const noexcept {return isValid() && rows() == 1 && cols() > 1;}
        inline bool                 isColumn()                                                          const noexcept {return isValid() && cols() == 1 && rows() > 1;}
        inline bool                 isScalar()                                                          const noexcept {return isValid() && size() == 1;}
        inline bool                 isSquare()                                                          const noexcept {return isValid() && rows() == cols();}
        inline bool                 isRectangular()                                                     const noexcept {return isValid() && cols() != rows();}

                                    //Content tests
        inline bool                 isZero()                                                            const noexcept {return *this == 0;}

                                    //An identiy matrix is a square matrix with ones on 
                                    //the main diagonal and zeros elsewhere. It is denoted by Iₙ
        inline bool                 isIdentity()                                                        const noexcept {return isDiagonal(1) && isOffDiagonal(0);}

                                    //A diagonal matrix is a matrix in which the 
                                    //entries outside the main diagonal are all zero
        inline bool                 isDiagonal()                                                        const noexcept {return isOffDiagonal(0);}

                                    //Test for either Upper|Lower triangular
        inline bool                 isTriangular()                                                      const noexcept {return isSquare() && (isTriangular(Portion::Upper) || isTriangular(Portion::Lower));}

        enum class                  Portion{Upper, Lower};

                                    //A triangular matrix is a special kind of square matrix. 
                                    //A square matrix is called lower triangular if all the entries 
                                    //above the main diagonal are zero (Portion::Lower). 
                                    //Similarly, a square matrix is called upper triangular if all 
                                    //the entries below the main diagonal are zero (Portion::Upper)
        bool                        isTriangular(Portion p)                                             const noexcept
                                    {
                                        bool success = false;

                                        if(isSquare())
                                        {
                                            success = true;

                                            const int k  = 0;

                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);

                                                    if((p == Portion::Upper && diagonal < k) ||
                                                       (p == Portion::Lower && diagonal > k))
                                                    {
                                                        if(0 != (*this)(i, j))
                                                        {
                                                            success = false;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        return success;
                                    }

                                    //Elements on the main diagonal are all 1 (also called unit triangular)
        bool                        isUniTriangular()                                                   const noexcept {return isDiagonal(1);}

                                    //Zero's the elements not on and above|below (Upper|Lower) the kth diagonal
        MemoryBlockMatrix           triangular(Portion p, int k = 0)                                    const noexcept
                                    {
                                        MemoryBlockMatrix mbm(*this);

                                        //Do not test for out of bounds k here; because it is a limit 

                                        if(mbm.isSquare())
                                        {

                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);

                                                    if((p == Portion::Upper && diagonal < k) ||
                                                       (p == Portion::Lower && diagonal > k))
                                                    {
                                                        mbm(i, j) = 0;
                                                    }
                                                }
                                            }
                                        }

                                        return mbm;
                                    }

                                    //Return kth diagonal
        MemoryBlock<Type>           diagonal(int k = 0)                                                 const noexcept
                                    {
                                        MemoryBlock<Type> mb;

                                        assert(std::abs(k) < rows());

                                        if(isSquare() && std::abs(k) < rows())
                                        {
                                            std::vector<Type> v;
                                            
                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);

                                                    if(diagonal == k)
                                                    {
                                                        v.emplace_back((*this)(i, j));
                                                    }
                                                }
                                            }

                                            mb = MemoryBlock<Type>(v);
                                        }

                                        return mb;
                                    }

                                    //Create a diagonal matrix with the elements of mb on the main diagonal
        static MemoryBlockMatrix    diagonal(MemoryBlock<Type> mb) 
                                    {
                                        MemoryBlockMatrix mbm(mb.size(), mb.size());

                                        if(mbm.isValid())
                                        {
                                            for(std::size_t i = 0; i < mbm.cols(); ++i)
                                            {
                                                mbm(i, i) = mb[i];
                                            }
                                        }

                                        return mbm;
                                    }

                                    //Create an identiy matrix, square matrix with 1's on the main diagonal
        static MemoryBlockMatrix    identity(std::size_t rows)
                                    {
                                        MemoryBlockMatrix mbm(rows, rows);
                                        mbm.setDiagonal(1);
                                        return mbm;
                                    }

                                    //Interchanges the row and column index for each element
        MemoryBlockMatrix&          transpose()                                                               noexcept {return *this = transposed();}
        MemoryBlockMatrix           transposed()                                                        const noexcept
                                    {
                                        MemoryBlockMatrix mbm;

                                        if(mbm.resize(cols(), rows()))
                                        {
                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                mbm.col((*this)[i], i);
                                            }
                                        }

                                        return mbm;
                                    }

                                    //Output of lup : such that A = P'*L*U
                                    struct LUP
                                    {
                                        MemoryBlockMatrix L; //Lower unit triangular matrix
                                        MemoryBlockMatrix U; //Upper triangular matrix
                                        MemoryBlockMatrix P; //Permutation matrix
                                        MBidx             p; //Permutation vector

                                        inline bool isValid() const noexcept 
                                        {
                                            return P.size() == L.size() && L.size() == U.size() && p.isValid() &&
                                                   P.isSquare() && L.isUniTriangular() && U.isTriangular(Portion::Upper);
                                        }

                                        //Solve A = P'*L*U
                                        inline auto A() const
                                        {
                                            return isValid() ? P.transposed()*L*U : MemoryBlockMatrix();
                                        }

                                        //Solve a general system Ax=b
                                        inline auto solve(const MemoryBlockMatrix& b) const noexcept
                                        {
                                            return subBackward(subForward(P * b));
                                        }

                                        //Solves the unit lower triangular system Lx=b using forward substition
                                        inline auto subForward(const MemoryBlockMatrix& b) const noexcept
                                        {
                                            MemoryBlockMatrix y;

                                            if(isValid() && b.isValid() && L.rows() == b.rows())
                                            {
                                                const auto rows = b.rows();
                                                const auto cols = b.cols();

                                                Type sum = 0;

                                                if(y.resize(rows, cols))
                                                {
                                                    //Process per column
                                                    for(std::size_t j = 0; j < cols; ++j)
                                                    {
                                                        //Solve for y1 of col
                                                        y(0, j) = b(0, j) / L(0, 0);

                                                        //Process each element on col j
                                                        for(std::size_t i = 1; i < rows; ++i)
                                                        {
                                                            sum = 0;

                                                            //Solve for yi of col 
                                                            for(std::size_t k = 0; k < i; ++k)
                                                            {
                                                                sum += L(i, k) * y(k, j);
                                                            }

                                                            //Fwd substitution with b
                                                            y(i, j) = (b(i, j) - sum) / L(i, i);
                                                        }
                                                    }
                                                }
                                            }

                                            return y;
                                        }

                                        //Solves the upper triangular system Ux=b using backward substitution
                                        inline auto subBackward(const MemoryBlockMatrix& b) const noexcept
                                        {
                                            MemoryBlockMatrix x;

                                            if(isValid() && b.isValid() && U.rows() == b.rows())
                                            {
                                                const auto rows = b.rows();
                                                const auto cols = b.cols();
                                                const auto n    = rows - 1;

                                                Type sum = 0;

                                                if(x.resize(rows, cols))
                                                {
                                                    //Process per column
                                                    for(std::size_t j = 0; j < cols; ++j)
                                                    {
                                                        //Solve xn of col
                                                        x(n, j) = b(n, j) / U(n, n);

                                                        //Process each element on col j
                                                        for(int i = static_cast<int>(n - 1); i >= 0; --i)
                                                        {
                                                            sum = 0;

                                                            //Sum col from i to rows
                                                            for(std::size_t k = i + 1; k < rows; ++k)
                                                            {
                                                                sum += U(i, k) * x(k, j);
                                                            }

                                                            //Backwards substitution with b
                                                            x(i, j) = (b(i, j) - sum) / U(i, i);
                                                        }
                                                    }
                                                }
                                            }

                                            return x;
                                        }
                                    };

                                    //Lower-Upper decomposition with partial pivot
        LUP                         lup()                                                               const noexcept
                                    {
                                        LUP ans;

                                        if(isSquare())
                                        {
                                            const std::size_t n = rows();

                                            std::size_t swapIndex = 0;

                                            //Working copy
                                            MemoryBlockMatrix A(*this);

                                            MemoryBlockMatrix& P = ans.P;
                                            P = MemoryBlockMatrix::identity(n);

                                            MBidx& p = ans.p;
                                            p = MBidx(n, 0, 1);

                                            for(std::size_t i = 0; i < n - 1; ++i)
                                            {
                                                //Find row in col i that has greatest magnitude
                                                swapIndex = i + A.col(i, i).abs().indexOfMax();

                                                if(swapIndex != i)
                                                {
                                                    //Swap rows
                                                    std::swap(A[i], A[swapIndex]);
                                                    std::swap(P[i], P[swapIndex]);
                                                    std::swap(p[i], p[swapIndex]);
                                                }

                                                //Get reciprocal to save same mips
                                                const auto inv = 1.0/A(i, i); //Allow NaN's here 

                                                //ith step of Gaussian elimination
                                                for(std::size_t j = i + 1; j < n; ++j)
                                                {
                                                    A(j, i) *= inv;

                                                    for(std::size_t k = i + 1; k < n; ++k)
                                                    {
                                                        A(j, k) -= A(j, i) * A(i, k);
                                                    }
                                                }
                                            }

                                            //Stuff upper and lower triangular for return
                                            ans.U = std::move(A.triangular(Portion::Upper));
                                            ans.L = std::move(A.triangular(Portion::Lower, -1));
                                            ans.L.setDiagonal(1); //Cheaper than adding MemoryBlockMatrix::identity(n)
                                        }

                                        return ans;
                                    }


        inline friend void          swap(MemoryBlockMatrix& lhs, MemoryBlockMatrix& rhs)                      noexcept
                                    {
                                        std::swap(lhs.m_mba, rhs.m_mba);
                                    }

    private:
                                    //Set elements on kth diagonal to same value
        bool                        setDiagonal(Type val, int k = 0)                                          noexcept
                                    {
                                        bool success = false;

                                        assert(std::abs(k) < rows());

                                        if(isSquare() && std::abs(k) < rows())
                                        {
                                            success = true;
                                            
                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);
                                                    if(diagonal == k)
                                                    {
                                                        (*this)(i, j) = val;
                                                    }
                                                }
                                            }
                                        }

                                        return success;
                                    }

                                    //Set elements off kth diagonal to same value
        bool                        setOffDiagonal(Type val, int k = 0)                                       noexcept
                                    {
                                        bool success = false;

                                        assert(std::abs(k) < rows());

                                        if(isSquare() && std::abs(k) < rows())
                                        {
                                            success = true;
                                            
                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);

                                                    if(diagonal != k)
                                                    {
                                                        (*this)(i, j) = val;
                                                    }
                                                }
                                            }
                                        }

                                        return success;
                                    }

                                    //Test if elements on kth diagonal are all the same value
        bool                        isDiagonal(Type val, int k = 0)                                     const noexcept
                                    {
                                        bool success = false;

                                        assert(std::abs(k) < rows());

                                        if(isSquare() && std::abs(k) < rows())
                                        {
                                            success = true;
                                            
                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);

                                                    if(diagonal == k)
                                                    {
                                                        if(val != (*this)(i, j))
                                                        {
                                                            success = false;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        return success;
                                    }

                                    //Test if off kth diagonal elements are all equal to same value
        bool                        isOffDiagonal(Type val, int k = 0)                                  const noexcept
                                    {
                                        bool success = false;

                                        assert(std::abs(k) < rows());

                                        if(isSquare() && std::abs(k) < rows())
                                        {
                                            success = true;
                                            
                                            for(std::size_t i = 0; i < rows(); ++i)
                                            {
                                                for(std::size_t j = 0; j < cols(); ++j)
                                                {
                                                    auto diagonal = static_cast<int>(j) - static_cast<int>(i);

                                                    if(diagonal != k)
                                                    {
                                                        if(val != (*this)(i, j))
                                                        {
                                                            success = false;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        return success;
                                    }

    protected:
                                    //Subscript operators (without bounds checking)
        MemoryBlock<Type>&          operator[](std::size_t row)                                               noexcept {assert(row < rows()); return m_mba[row];} //protected : to enforce non jagged matrix
        const MemoryBlock<Type>&    operator[](std::size_t row)                                         const noexcept {assert(row < rows()); return m_mba[row];} 

                                    //Helper to get size of first element in vals
        inline std::size_t          sizeOfFirst(std::initializer_list<MemoryBlock<Type>> vals)          const noexcept
                                    {
                                        auto it = vals.begin();

                                        return it == nullptr ? 0 : it->size();
                                    }

                                    //Validate list : ensure each MB is of same length
        inline bool                 validate(std::initializer_list<MemoryBlock<Type>> vals)             const noexcept
                                    {
                                        bool valid = false;

                                        if(vals.size())
                                        {
                                            valid = true;

                                            const std::size_t size = sizeOfFirst(vals);

                                            for(auto it = vals.begin(); it != vals.end(); ++it)
                                            {
                                                if(it != nullptr)
                                                {
                                                    if(it != vals.begin() && size != it->size())
                                                    {
                                                        valid = false;
                                                        break;
                                                    }
                                                }
                                            }
                                        }

                                        return valid;
                                    }

    private:
        using MBArray           = std::vector<MemoryBlock<Type>>;
        MBArray                 m_mba;

        static_assert(std::is_arithmetic<Type>::value, "Error: arithmetic type must be used");
    };

    //Index
    using MBMidx = MemoryBlockMatrix<std::size_t>;

    //64 bit aliases
    using MBM64u = MemoryBlockMatrix<uint64_t>;
    using MBM64i = MemoryBlockMatrix<int64_t>;
    using MBM64f = MemoryBlockMatrix<double>; 

    //32 bit aliases
    using MBM32u = MemoryBlockMatrix<uint32_t>;
    using MBM32i = MemoryBlockMatrix<int32_t>;
    using MBM32f = MemoryBlockMatrix<float>;

}//bosepro

#endif //MEMORYBLOCKMATRIX_H