#pragma once

#ifndef POLYFIT_H
#define POLYFIT_H

#include <cmath>
#include <vector>
#include <iterator>
#include "Math/FuzzyCompare.h"
#include "Math/MathUtils.h"

namespace bosepro::math
{
    /**
    * \brief    Helper for xgeqp3, ported from Matlab coder from polyfit
    * \param    n - number of base values
    * \param    x - data collection comprised of base values * num coeffs
    * \param    ix0 - base index to start from
    */
    static double xnrm2(std::size_t n, const std::vector<double>& x, std::size_t ix0)
    {
        double y = 0.0;

        if (n > 0)
        {
            if (n == 1)
            {
                y = std::abs(x[ix0 - 1]);
            }
            else
            {
                auto scale = 2.2250738585072014E-308;
                auto kend = (ix0 + n) - 1;
                for (auto k = ix0; k <= kend; k++)
                {
                    auto absxk = std::abs(x[k - 1]);
                    if (absxk > scale)
                    {
                        auto t = math::SafeDivide(scale, absxk);
                        y = 1.0 + y * t * t;
                        scale = absxk;
                    }
                    else
                    {
                        auto t = math::SafeDivide(absxk, scale);
                        y += t * t;
                    }
                }
                y = scale * math::SafeSqrt(y);
            }
        }
        return y;
    }

    /**
    * \brief    Helper for xgeqp3
    * \param    u0 - data value
    * \param    u1 - scaled value
    * \return   y - computed value
    */
    static double rt_hypotd_snf(double u0, double u1)
    {
        double y = 0.0;
        double a = std::abs(u0);
        double b = std::abs(u1);
        if (a < b)
        {
            a = math::SafeDivide(a, b);
            y = b * math::SafeSqrt(a * a + 1.0);
        }
        else if (a > b)
        {
            b = math::SafeDivide(b, a);
            y = a * math::SafeSqrt(b * b + 1.0);
        }
        else if (std::isnan(b))
        {
            y = b;
        }
        else
        {
            y = a * 1.4142135623730951; // sqr(2)?
        }
        return y;
    }

    /**
    * \brief    Helper for xgeqp3
    * \param    n - adjusted numX - cur coefficient - 1
    * \param    a - computed value
    * \param    x - data collection sized by x inputs values x coefficients
    * \param    ix0 - base index to data collection (block of coefficient range)
    * \return   void
    */
    static void xscal(std::size_t n, double a, std::vector<double>& x, std::size_t ix0)
    {
        std::size_t i1 = (ix0 + n) - 1;
        for (std::size_t k = ix0; k <= i1; k++)
        {
            x[k - 1] *= a;
        }
    }


    /**
    * \brief    worker for calc of values, taus and jpvt to contribute to coefficient calculation of polynomial least squares fit.
    * \param    :   numX - number of provided x values to caller (part of size of processing array)
    * \param    :   numCoeffs - number of coefficients based on degree + 1.  (numX * numCoeffs = size of processing array A)
    * \param    :   A - collection of double values per coefficient
    * \param    :   tau - one per lower of x vals or coefficients
    * \param    :   jpvt - one per coefficient, seems to be used to adjust coefficient indices
    * \return   : void
    */
    static void xgeqp3(std::size_t numX, std::size_t numCoeffs, std::vector<double>& A, std::vector<double>& tau, std::vector<std::size_t>& jpvt)
    {
        std::size_t lessXOrCoeffs;
        if (numX <= numCoeffs)
        {
            lessXOrCoeffs = numX;
        }
        else
        {
            lessXOrCoeffs = numCoeffs;
        }

        jpvt.resize(numCoeffs);

        if (numCoeffs > 0)
        {
            jpvt[0] = 1;
            std::size_t yk = 1;
            for (auto k = 2U; k <= numCoeffs; k++)
            {
                yk++;
                jpvt[k - 1] = yk;
            }
        }

        if (A.size() > 0)
        {
            std::vector<double>work(numCoeffs);
            std::vector<double> vn1(numCoeffs);
            std::vector<double> vn2(numCoeffs);

            std::size_t k = 1;
            for (auto nmi = 0U; nmi < numCoeffs; nmi++)
            {
                vn1[nmi] = xnrm2(numX, A, k);
                vn2[nmi] = vn1[nmi];
                k += numX;
            }
            std::size_t iy;
            std::size_t yk;
            double smax;
            double s;
            for (std::size_t i = 0; i < lessXOrCoeffs; i++)
            {
                std::size_t ix = 0;
                auto i_i = i + i * numX;
                auto nmi = numCoeffs - i;
                auto mmi = (numX - i) - 1;
                if (nmi < 1)
                {
                    yk = 0;
                }
                else
                {
                    yk = 1;
                    if (nmi > 1)
                    {
                        ix = i;
                        smax = std::abs(vn1[i]);
                        for (k = 2; k <= nmi; k++)
                        {
                            ix++;
                            s = std::abs(vn1[ix]);
                            if (s > smax)
                            {
                                yk = k;
                                smax = s;
                            }
                        }
                    }
                }

                auto b_n = (i + yk) - 1;
                if (b_n + 1 != i + 1)
                {
                    ix = numX * b_n;
                    iy = numX * i;
                    for (k = 1; k <= numX; k++)
                    {
                        smax = A[ix];
                        A[ix] = A[iy];
                        A[iy] = smax;
                        ix++;
                        iy++;
                    }

                    auto jpvt1 = jpvt[b_n];
                    jpvt[b_n] = jpvt[i];
                    jpvt[i] = jpvt1;
                    vn1[b_n] = vn1[i];
                    vn2[b_n] = vn2[i];
                }

                if (i + 1 < numX)
                {
                    auto absxk = A[i_i];
                    s = 0.0;
                    if (!(1 + mmi <= 0))
                    {
                        smax = xnrm2(mmi, A, i_i + 2);
                        if (smax != 0.0)
                        {
                            smax = rt_hypotd_snf(A[i_i], smax);
                            if (A[i_i] >= 0.0)
                            {
                                smax = -smax;
                            }

                            if (std::abs(smax) < 1.0020841800044864E-292)
                            {
                                yk = 0;
                                do
                                {
                                    yk++;
                                    xscal(mmi, 9.9792015476736E+291, A, i_i + 2);
                                    smax *= 9.9792015476736E+291;
                                    absxk *= 9.9792015476736E+291;
                                } while (!(std::abs(smax) >= 1.0020841800044864E-292));

                                smax = xnrm2(mmi, A, i_i + 2);
                                smax = rt_hypotd_snf(absxk, smax);
                                if (absxk >= 0.0)
                                {
                                    smax = -smax;
                                }

                                s = math::SafeDivide((smax - absxk), smax);
                                xscal(mmi, math::SafeDivide(1.0, (absxk - smax)), A, i_i + 2);
                                for (k = 1; k <= yk; k++)
                                {
                                    smax *= 1.0020841800044864E-292;
                                }

                                absxk = smax;
                            }
                            else
                            {
                                s = math::SafeDivide((smax - A[i_i]), smax);
                                xscal(mmi, math::SafeDivide(1.0, (A[i_i] - smax)), A, i_i + 2);
                                absxk = smax;
                            }
                        }
                    }
                    tau[i] = s;
                    A[i_i] = absxk;
                }
                else
                {
                    tau[i] = 0.0;
                }

                std::size_t lastc;

                if (i + 1 < numCoeffs)
                {
                    auto absxk = A[i_i];
                    A[i_i] = 1.0;
                    auto i_ip1 = (i + (i + 1) * numX) + 1;
                    std::size_t lastv = 0;
                    if (tau[i] != 0.0)
                    {
                        lastv = mmi + 1;
                        yk = i_i + mmi;
                        while ((lastv > 0) && (A[yk] == 0.0))
                        {
                            lastv--;
                            yk--;
                        }

                        lastc = nmi - 1;
                        auto exitg2 = false;
                        while ((!exitg2) && (lastc > 0))
                        {
                            yk = i_ip1 + (lastc - 1) * numX;
                            k = yk;
                            auto exitg1 = 0;
                            do
                            {

                                if (k <= (yk + lastv) - 1)
                                {
                                    if (A[k - 1] != 0.0)
                                    {
                                        exitg1 = 1;
                                    }
                                    else
                                    {
                                        k++;
                                    }
                                }
                                else
                                {
                                    lastc--;
                                    exitg1 = 2;
                                }
                            } while (exitg1 == 0);

                            if (exitg1 == 1)
                            {
                                exitg2 = true;
                            }
                        }
                    }
                    else
                    {
                        lastv = 0;
                        lastc = 0;
                    }

                    if (lastv > 0)
                    {
                        std::size_t i0 = 0;
                        if (lastc != 0)
                        {
                            for (iy = 1; iy <= lastc; iy++)
                            {
                                work[iy - 1] = 0.0;
                            }

                            iy = 0;
                            i0 = i_ip1 + numX * (lastc - 1);
                            yk = i_ip1;
                            while ((numX > 0) && (yk <= i0))
                            {
                                ix = i_i;
                                smax = 0.0;
                                b_n = (yk + lastv) - 1;
                                for (k = yk; k <= b_n; k++)
                                {
                                    smax += A[k - 1] * A[ix];
                                    ix++;
                                }

                                work[iy] += smax;
                                iy++;
                                yk += numX;
                            }
                        }

                        if (!(-tau[i] == 0.0))
                        {
                            yk = i_ip1 - 1;
                            b_n = 0;
                            for (nmi = 1U; nmi <= lastc; nmi++)
                            {
                                if (!math::isApproximatelyZero(work[b_n]))
                                {
                                    smax = work[b_n] * -tau[i];
                                    ix = i_i;
                                    i0 = lastv + yk;
                                    for (k = yk; k + 1 <= i0; k++)
                                    {
                                        A[k] += A[ix] * smax;
                                        ix++;
                                    }
                                }

                                b_n++;
                                yk += numX;
                            }
                        }
                    }

                    A[i_i] = absxk;
                }

                for (nmi = i + 1; nmi + 1 <= numCoeffs; nmi++)
                {
                    yk = (i + numX * nmi) + 1;
                    if (vn1[nmi] != 0.0)
                    {
                        smax = std::abs(math::SafeDivide(A[i + numX * nmi], vn1[nmi]));
                        smax = 1.0 - smax * smax;
                        if (smax < 0.0)
                        {
                            smax = 0.0;
                        }

                        s = math::SafeDivide(vn1[nmi], vn2[nmi]);
                        s = smax * (s * s);
                        if (s <= 1.4901161193847656E-8)
                        {
                            if (i + 1 < numX)
                            {
                                smax = 0.0;
                                if (!(mmi < 1))
                                {
                                    if (mmi == 1)
                                    {
                                        smax = std::abs(A[yk]);
                                    }
                                    else
                                    {
                                        s = 2.2250738585072014E-308;
                                        b_n = yk + mmi;
                                        while (yk + 1 <= b_n)
                                        {
                                            auto absxk = std::abs(A[yk]);
                                            double t;
                                            if (absxk > s)
                                            {
                                                t = math::SafeDivide(s, absxk);
                                                smax = 1.0 + smax * t * t;
                                                s = absxk;
                                            }
                                            else
                                            {
                                                t = math::SafeDivide(absxk, s);
                                                smax += t * t;
                                            }
                                            yk++;
                                        }
                                        smax = s * math::SafeSqrt(smax);
                                    }
                                }

                                vn1[nmi] = smax;
                                vn2[nmi] = vn1[nmi];
                            }
                            else
                            {
                                vn1[nmi] = 0.0;
                                vn2[nmi] = 0.0;
                            }
                        }
                        else
                        {
                            vn1[nmi] *= math::SafeSqrt(smax);
                        }
                    }
                }
            }
        }
    }


    /*
     * \brief   Port of Matlab's polyfit that supports nth degree polynomial
     *          p(x)=c0*X^n + c1*X^n-1 + ...cn*x + cn+1, so for degree 2 we have p(x) = c0*X^2 + c1*X + c2
     * \param   : ForwardIt xBegin
     * \param   : ForwardIt xEnd
     * \param   : ForwardIt yBegin
     * \param   : ForwardIt yEnd
     * \param   : degree
     * \return  : coeffs vector of doubles ordered by highest degree first.
     * \details : Exported with Coder App to C then refactored a little.
     *            polyfit(x,y,2) equivalent to fit(x,y,'poly2')
     *            Most variables as Matlab exported. A few were renamed for clarity.
     *            This is their version of least squares optimization probably
     *            with some special sauce for real world edge case handling.
     *            An academic approach to polynomial least squares can be found here: https://mathworld.wolfram.com/LeastSquaresFittingPolynomial.html
     *            But for expediency, did a direct Matlab port to save time as it was found with spline (and 3 versions of academic code) that the academic approach was insufficient when using real world data.
     *            Given decades of experience baked into that code, did not want to try to reinvent that.
     *            Support any container, via FwdIterator
     *            
     */
    template<class ForwardIt> auto polyfit(ForwardIt xBegin, ForwardIt xEnd, ForwardIt yBegin, ForwardIt yEnd, const uint32_t degree /*=2*/)
    {
        const auto numCoeffs = degree + 1;
        std::vector<double> coeffs;
        coeffs.resize(numCoeffs);
        const auto numX = static_cast<size_t>(xEnd - xBegin);
        const auto numY = static_cast<size_t>(yEnd - yBegin);
        assert(numX == numY && "size of X and Y values must match!");

        if (numX == numY)
        {
            std::vector<double> V(numX * numCoeffs);

            if (V.size() > 0)
            {
                // Setup V with the different poly degrees, lots of looping in exported code but it is avoiding branching in the loop.
                // Also, what was exported is cache friendly as it is looping different sections of memory.  Made this fact more obvious by changing loop bounds rather than doing calcs per index.
                for (auto ix = numX * degree; ix < V.size(); ix++) // was 0u to numX, but then ix + numX * degree per assignment.
                {
                    V[ix] = 1.0; // initialize values for highest degree to 1.0
                }

                if (degree > 0.0)
                {
                    const auto degreeLess1 = degree - 1;
                    auto ixStart = numX * degreeLess1;
                    auto ixEnd = ixStart + numX;
                    auto xIter = xBegin;
                    for (auto ixV = ixStart; ixV < ixEnd && xIter != xEnd; ixV++, ++xIter)
                    {
                        V[ixV] = *xIter; // values for next degree down gets x values.
                    }

                    auto remainingDegrees = degree - 1; //static_cast<unsigned int>( (1.0 + (-1.0 - (degree - 1.0))) / -1.0); // silly machine generation!
                    remainingDegrees = std::max(0U, remainingDegrees);
                    for (auto j = 0U; j < remainingDegrees; j++)
                    {
                        const auto midDegree = degree - 1 - j; // for degree 2, this goes 1, one loop to fill in values from 0 - numX.  Otherwise does intermediate degrees down to this range.
                        xIter = xBegin;
                        ixStart = numX * (midDegree - 1);
                        ixEnd = ixStart + numX;
                        std::size_t ixX = 0;
                        for (auto ix = ixStart; ix < ixEnd && xIter != xEnd; ix++, ++xIter, ixX++)
                        {
                            V[ix] = *xIter * V[ixEnd + ixX]; // read next degree values to mult
                        }
                    }
                }
            }

            std::size_t lessOfXOrCoeffs = numCoeffs;
            if (numX <= numCoeffs)
            {
                lessOfXOrCoeffs = numX;
            }

            std::vector<double> tau(lessOfXOrCoeffs);
            std::vector<std::size_t> jpvt(numCoeffs); // holds index
            std::vector<double> B;

            // this is the workhorse of the algorithm. It calculates and updates V, tau and jpvt which are then used to assign the coefficients of the resulting polynomial.
            xgeqp3(numX, numCoeffs, V, tau, jpvt);

            for (auto yIter = yBegin; yIter != yEnd; ++yIter)
            {
                B.push_back(*yIter);
            }

            for (auto ci = 0U; ci < lessOfXOrCoeffs; ci++)
            {
                if (!math::isApproximatelyZero(tau[ci]))
                {
                    auto wj = B[ci];
                    auto ixB = ci + 1;
                    auto ixStart = ixB + numX * ci;
                    auto ixEnd = ixStart + (numX - ixB);
                    for (auto ix = ixStart; ix < ixEnd; ix++, ixB++)
                    {
                        wj += V[ix] * B[ixB];
                    }

                    wj *= tau[ci];
                    if (!math::isApproximatelyZero(wj))
                    {
                        B[ci] -= wj;
                        for (auto ix = ci + 1; ix < numX; ix++)
                        {
                            B[ix] -= V[ix + numX * ci] * wj;
                        }
                    }
                }
            }

            for (auto ci = 0U; ci < lessOfXOrCoeffs; ci++) // forward loop
            {
                auto adjCi = static_cast<std::size_t>(jpvt[ci] - 1);
                coeffs[adjCi] = B[ci];
            }

            for (auto rci = lessOfXOrCoeffs - 1; rci + 1 > 0; rci--) // reverse loop
            {
                auto adjCi = static_cast<std::size_t>(jpvt[rci] - 1);
                coeffs[adjCi] = math::SafeDivide(coeffs[adjCi], V[rci + numX * rci]);
                for (auto ix = 0U; ix < rci; ix++) // remaining up to reverse index
                {
                    auto adjIx = static_cast<std::size_t>(jpvt[ix] - 1);
                    coeffs[adjIx] -= coeffs[adjCi] * V[ix + numX * rci];
                }
            }
        }
        return coeffs;
    }

    /**
    * \brief    application of coefficients to source X data.
    */
    template<class ForwardIt> auto polyval(ForwardIt xBegin, ForwardIt xEnd, std::vector<double>coeffs)
    {
        std::vector<double> yVals;        
        for (auto it = xBegin; it < xEnd; ++it)
        {
            // apply the polynomial coefficients, start with the last one and go up a degree at a time adding each one together.
            double newY = 0.0;
            if (!coeffs.empty())
            {
                newY = coeffs.back(); // start with last one.
            }

            // apply the remaining coefficients to the src value.
            for (std::size_t c = 0; c < coeffs.size() - 1; c++)
            {
                auto degree = c + 1;
                auto ci = coeffs.size() - c - 2;
                newY += coeffs[ci] * std::pow(*it, degree);
            }
            yVals.push_back(newY);
        }
        return yVals;
    }

}
#endif
