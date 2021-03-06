import  numpy as np
cimport numpy as np
cimport cython

ctypedef np.float_t DTYPE_t

cdef class IntegratorsClass:
    cdef:
        readonly int N, M, kI, kE, nClass
        readonly double gIh, gIc, fh, ep, gI
        readonly double gIsp, gIcp, gIhp, ars, kapE
        readonly np.ndarray rp0, Ni, dxdt, CM, FM, TR, sa, iaa, hh, cc, mm, alpha
        readonly dict paramList

    cpdef set_contactMatrix(self, double t, contactMatrix)

@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SIR(IntegratorsClass):
    """
    Susceptible, Infected, Removed (SIR)

    * Ia: asymptomatic
    * Is: symptomatic
    """

    cdef:
        readonly np.ndarray beta, gIa, gIs, fsa

    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SIRS(IntegratorsClass):
    """
    Susceptible, Infected, Removed, Susceptible (SIRS)

    * Ia: asymptomatic
    * Is: symptomatic
    """
    cdef:
        readonly double beta, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEIR(IntegratorsClass):
    """
    Susceptible, Exposed, Infected, Removed (SEIR)

    * Ia: asymptomatic
    * Is: symptomatic
    """
    cdef:
        readonly np.ndarray beta, gIa, gIs, gE, fsa
    cpdef rhs(self, rp, tt)

@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEI8R(IntegratorsClass):
    """
    Susceptible, Exposed, Infected, Removed (SEIR). The infected class has 5 groups.

    * Ia: asymptomatic
    * Is: symptomatic
    * Ih: hospitalized
    * Ic: ICU
    * Im: Mortality

    The transitions are,

    * S  ---> E
    * E  ---> Ia, Is
    * Ia ---> R
    * Is ---> Is',Ih, R
    * Ih ---> Ih',Ic, R
    * Ic ---> Ic',Im, R
    """

    cdef:
        readonly double beta, gE, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)





@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SIkR(IntegratorsClass):
    """
    Susceptible, Infected, Removed (SIkR). Method of k-stages of I
    """
    cdef:
        readonly double beta, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEkIkR(IntegratorsClass):
    """
    Susceptible, Infected, Removed (SIkR). Method of k-stages of I

    See: Lloyd, Theoretical Population Biology 60, 59􏰈71 (2001), doi:10.1006􏰅tpbi.2001.1525.
    """
    cdef:
        readonly double beta, gE, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEkIkIkR(IntegratorsClass):
    """
    Susceptible, Infected, Removed (SIkR). Method of k-stages of I

    See: Lloyd, Theoretical Population Biology 60, 59􏰈71 (2001), doi:10.1006􏰅tpbi.2001.1525.
    """
    cdef:
        readonly double beta, gE, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEAIR(IntegratorsClass):
    """
    Susceptible, Exposed, Asymptomatic and infected, Infected, Removed (SEAIR)

    * Ia: asymptomatic
    * Is: symptomatic
    * E: exposed
    * A : Asymptomatic and infectious
    """
    cdef:
        readonly double beta, gE, gA, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEAI8R(IntegratorsClass):
    """
    Susceptible, Exposed, Activates, Infected, Removed (SEAIR). The infected class has 5 groups:

    * Ia: asymptomatic
    * Is: symptomatic
    * Ih: hospitalized
    * Ic: ICU
    * Im: Mortality

    The transitions are,

    * S  ---> E
    * E  ---> A
    * A  ---> Ia, Is
    * Ia ---> R
    * Is ---> Ih, Is', R
    * Ih ---> Ic, Ih', R
    * Ic ---> Im, Ic', R
    """
    cdef:
        readonly double beta, gE, gA, gIa, gIs, fsa
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEAIRQ(IntegratorsClass):
    """
    Susceptible, Exposed, Asymptomatic and infected, Infected, Removed, Quarantined (SEAIRQ)

    * Ia: asymptomatic
    * Is: symptomatic
    * E: exposed
    * A: Asymptomatic and infectious
    * R: removed (recovered or deceased)
    * Q: quarantined
    """

    cdef:
        readonly np.ndarray beta, gE, gA, gIs, gIa, fsa
        readonly np.ndarray tS, tE, tA, tIa, tIs
    cpdef rhs(self, rp, tt)

@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEAIRQ_testing(IntegratorsClass):
    """
    Susceptible, Exposed, Asymptomatic and infected, Infected, Removed, Quarantined (SEAIRQ)

    * Ia: asymptomatic
    * Is: symptomatic
    * E: exposed
    * A: Asymptomatic and infectious
    * R: removed (recovered or deceased)
    * Q: quarantined
    """

    cdef:
        readonly double beta, gE, gA, gIa, gIs, fsa
        readonly double tS, tE, tA, tIa, tIs
    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(True)
@cython.cdivision(False)
@cython.nonecheck(True)
cdef class Spp(IntegratorsClass):
    """
    Given a model specification, the Spp class generates a custome-made compartment epidemic model.
    """

    cdef:
        readonly np.ndarray constant_terms, linear_terms, infection_terms
        readonly np.ndarray parameters
        readonly list param_keys
        readonly dict class_index_dict
        readonly np.ndarray _lambdas

    cpdef rhs(self, rp, tt)




@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEI5R(IntegratorsClass):
    cdef:
        readonly double beta, gE, gA, gIa, gIs, fsa
    """
    Susceptible, Exposed, Infected, Removed (SEIR). The infected class has 5 groups:

    * Ia: asymptomatic
    * Is: symptomatic
    * Ih: hospitalized
    * Ic: ICU
    * Im: Mortality
    """

    cpdef rhs(self, rp, tt)





@cython.wraparound(False)
@cython.boundscheck(False)
@cython.cdivision(True)
@cython.nonecheck(False)
cdef class SEAI5R(IntegratorsClass):
    cdef:
        readonly double beta, gE, gA, gIa, gIs, fsa
    """
    Susceptible, Exposed, Activates, Infected, Removed (SEAIR). The infected class has 5 groups:

    * Ia: asymptomatic
    * Is: symptomatic
    * Ih: hospitalized
    * Ic: ICU
    * Im: Mortality
    """
    cpdef rhs(self, rp, tt)
