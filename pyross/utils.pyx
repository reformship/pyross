import  numpy as np
cimport numpy as np
cimport cython
from libc.math cimport sqrt, pow, log
from cython.parallel import prange
cdef double PI = 3.1415926535
from scipy.sparse import spdiags
import matplotlib.pyplot as plt

class GPR:
    def __init__(self, nS, nT, iP, nP, xS, xT, yT):
        self.nS   =  nS           # # of test data points
        self.nT   =  nT           # # of training data points
        self.iP   =  iP           # # inverse of sigma
        self.nP   =  nP           # # number of priors
        self.xS   =  xS           # test input
        self.xT   =  xT           # training input
        self.yT   =  yT           # training output

        self.yS   =  0            # test output
        self.yP   =  0            # prior output
        self.K    =  0            # kernel
        self.Ks   =  0            # kernel
        self.Kss  =  0            # kernel
        self.mu   =  0            # mean
        self.sd   =  0            # stanndard deviation


    def calcDistM(self, r, s):
        '''Calculate distance matrix between 2 1D arrays'''
        return r[..., np.newaxis] - s[np.newaxis, ...]


    def calcKernels(self):
        '''Calculate the kernel'''
        cc = self.iP*0.5
        self.K   = np.exp(-cc*self.calcDistM(self.xT, self.xT)**2)
        self.Ks  = np.exp(-cc*self.calcDistM(self.xT, self.xS)**2)
        self.Kss = np.exp(-cc*self.calcDistM(self.xS, self.xS)**2)
        return


    def calcPrior(self):
        '''Calculate the prior'''
        L  = np.linalg.cholesky(self.Kss + 1e-6*np.eye(self.nS))
        G  = np.random.normal(size=(self.nS, self.nP))
        yP = np.dot(L, G)
        return


    def calcMuSigma(self):
        '''Calculate the mean'''
        self.mu =  np.dot(self.Ks.T, np.linalg.solve(self.K, self.yT))

        vv = self.Kss - np.dot(self.Ks.T, np.linalg.solve(self.K, self.Ks))
        self.sd = np.sqrt(np.abs(np.diag(vv)))

        # Posterior
        L       = np.linalg.cholesky(vv + 1e-6*np.eye(self.nS))
        self.yS = self.mu.reshape(-1,1) + np.dot(L, np.random.normal(size=(self.nS, self.nP)))
        return


    def plotResults(self):
        plt.plot(self.xT, self.yT, 'o', ms=10, mfc='#348ABD', mec='none', label='training set' )
        plt.plot(self.xS, self.yS, '#dddddd', lw=1.5, label='posterior')
        plt.plot(self.xS, self.mu, '#A60628', lw=2, label='mean')

        # fill 95% confidence interval (2*sd about the mean)
        plt.fill_between(self.xS.flat, self.mu-2*self.sd, self.mu+2*self.sd, color="#348ABD", alpha=0.4, label='2 sigma')
        plt.axis('tight'); plt.legend(fontsize=15); plt.rcParams.update({'font.size':18})


    def runGPR(self):
        self.calcKernels()
        self.calcPrior()
        self.calcMuSigma()
        self.plotResults()


def parse_model_spec(model_spec, param_keys):

    # First, extract the classes
    class_list = model_spec['classes']
    nClass = len(class_list) # total number of classes

    # Make dictionaries for class and parameter index look-up
    class_index_dict = {class_name:i for (i, class_name) in enumerate(class_list)}
    params_index_dict = {param: i for (i, param) in enumerate(param_keys)}

    try:
        # dictionaries of all constant, linear and all infection terms
        constant_dict = {}
        linear_dict = {}
        infection_dict = {}
        for class_name in class_list:
            reaction_dict = model_spec[class_name]
            if 'constant' in reaction_dict.keys():
                constant_dict[class_name] = reaction_dict['constant']
            if 'linear' in reaction_dict.keys():
                linear_dict[class_name] = reaction_dict['linear']
            if 'infection' in reaction_dict.keys():
                infection_dict[class_name] = reaction_dict['infection']

        # parse the constant term
        constant_term_set = set() # used to check for duplicates
        constant_term_list = []
        for (k, val) in constant_dict.items():
            for (rate,) in val:
                if (k, rate) in constant_term_set:
                    raise Exception('Duplicate constant term: {}, {}'.format(k, rate))
                else:
                    sign = 1
                    constant_term_set.add((k, rate))
                    class_index = class_index_dict[k]
                    if rate.startswith('-'):
                        rate = rate[1:]
                        sign = -1
                    rate_index = params_index_dict[rate]
                    constant_term_list.append([rate_index, class_index, sign])

        if len(constant_term_list) > 0: # add one class for Ni
            class_index_dict['Ni'] = nClass
            nClass += 1 # add one class for Ni

        # parse the linear terms into a list of [rate_index, reagent_index] and a dictionary for the product
        linear_terms_set = set() # used to check for duplicates
        linear_terms_list = [] # collect all linear terms
        linear_terms_destination_dict = {} # a dictionary for the product
        for (k, val) in linear_dict.items():
            for (reagent, rate) in val:
                if (reagent, rate) in linear_terms_set:
                    raise Exception('Duplicates linear terms: {}, {}'.format(reagent, rate))
                else:
                    linear_terms_set.add((reagent, rate))
                    reagent_index = class_index_dict[reagent]
                    if rate.startswith('-'):
                        rate = rate[1:]
                        rate_index = params_index_dict[rate]
                        linear_terms_list.append([rate_index, reagent_index, -1])
                    else:
                        rate_index = params_index_dict[rate]
                        linear_terms_destination_dict[(rate_index, reagent_index)] = class_index_dict[k]

        # parse the infection terms into a list of [rate_index, reagent_index] and a dictionary for the product
        infection_terms_set = set() # used to check to duplicates
        infection_terms_list = [] # collect all infection terms
        infection_terms_destination_dict = {} # a dictionary for the product
        for (k, val) in infection_dict.items():
            for (reagent, rate) in val:
                if (reagent, rate) in infection_terms_set:
                    raise Exception('Duplicates infection terms: {}, {}'.format(reagent, rate))
                else:
                    infection_terms_set.add((reagent, rate))
                    reagent_index = class_index_dict[reagent]
                    if rate.startswith('-'):
                        rate = rate[1:]
                        if k != 'S':
                            raise Exception('A susceptible group that is not S: {}'.format(k))
                        else:
                            rate_index = params_index_dict[rate]
                            infection_terms_list.append([rate_index, reagent_index, -1])
                    else:
                        rate_index = params_index_dict[rate]
                        infection_terms_destination_dict[(rate_index, reagent_index)] = class_index_dict[k]

    except KeyError:
        raise Exception('No reactions for some classses. Please check model_spec again')

    # set the product index
    set_destination(linear_terms_list, linear_terms_destination_dict)
    set_destination(infection_terms_list, infection_terms_destination_dict)
    res = (nClass, class_index_dict, np.array(constant_term_list, dtype=np.intc, ndmin=2),
                                     np.array(linear_terms_list, dtype=np.intc, ndmin=2),
                                     np.array(infection_terms_list, dtype=np.intc, ndmin=2))
    return res

def set_destination(term_list, destination_dict):
    '''
    A function used by parse_model_spec that sets the product_index
    '''
    for term in term_list:
        rate_index = term[0]
        reagent_index = term[1]
        if (rate_index, reagent_index) in destination_dict.keys():
            product_index = destination_dict[(rate_index, reagent_index)]
            term[2] = product_index

def age_dep_rates(rate, int M, str name):
    if np.size(rate)==1:
        return rate*np.ones(M)
    elif np.size(rate)==M:
        return rate
    else:
        raise Exception('{} can be a number or an array of size M'.format(name))

def make_log_norm_dist(means, stds):
    var = stds**2
    means_sq = means**2
    scale = means_sq/np.sqrt(means_sq+var)
    s = np.sqrt(np.log(1+var/means_sq))
    return s, scale


DTYPE = np.float
ctypedef np.float_t DTYPE_t

cpdef forward_euler_integration(f, double [:] x, double t1, double t2, Py_ssize_t steps):
    cdef:
        double dt=(t2-t1)/(steps-1),t=t1
        double [:] fx
        Py_ssize_t i, j, size=x.shape[0]
        double [:, :] sol=np.empty((steps, size), dtype=DTYPE)

    for j in range(size):
        sol[0, j] = x[j]
    for i in range(1, steps):
        fx = f(t, x)
        for j in range(size):
            sol[i, j] = sol[i-1, j] + fx[j]*dt
        t += dt
    return sol

cpdef RK2_integration(f, double [:] x, double t1, double t2, Py_ssize_t steps):
    cdef:
        double dt=(t2-t1)/(steps-1),t=t1
        double [:] fx
        Py_ssize_t i, j, size=x.shape[0]
        double [:] k1=np.empty((size), dtype=DTYPE), temp=np.empty((size), dtype=DTYPE)
        double [:, :] sol=np.empty((steps, size), dtype=DTYPE)

    for j in range(size):
        sol[0, j] = x[j]
    for i in range(1, steps):
        fx = f(t, x)
        for j in range(size):
            k1[j] = dt*fx[j]
            temp[j] = sol[i-1, j] + k1[j]
        t += dt
        fx = f(t, temp)
        for j in range(size):
            sol[i, j] = sol[i-1, j] + 0.5*(k1[j] + dt*fx[j])
    return sol

cpdef nearest_positive_definite(double [:, :] B):
    """Find the nearest positive-definite matrix to input

    [1] https://gist.github.com/fasiha/fdb5cec2054e6f1c6ae35476045a0bbd

    [2] https://www.mathworks.com/matlabcentral/fileexchange/42885-nearestspd

    [3] N.J. Higham, "Computing a nearest symmetric positive semidefinite
    matrix" (1988): https://doi.org/10.1016/0024-3795(88)90223-6
    """
    cdef:
        np.ndarray[DTYPE_t, ndim=2] V, H, A2, A3, I
        np.ndarray[DTYPE_t, ndim=1] s
        double spacing, mineig
        int k

    _, s, V = np.linalg.svd(B)
    H = np.dot(V.T, np.dot(np.diag(s), V))
    A2 = np.add(B, H) / 2
    A3 = (A2 + A2.T) / 2

    if is_positive_definite(A3):
        return A3
    else:
        spacing = np.spacing(np.linalg.norm(B))
        I = np.eye(B.shape[0])
        k = 1
        while not is_positive_definite(A3):
            mineig = np.min(np.real(np.linalg.eigvals(A3)))
            A3 += I * (-mineig * k**2 + spacing)
            k += 1
        return A3

cpdef is_positive_definite(double [:, :] B):
    """Returns true when input is positive-definite, via Cholesky"""
    try:
        _ = np.linalg.cholesky(B)
        return True
    except np.linalg.LinAlgError:
        return False

def plotSIR(data, showPlot=True):
    t = data['t']
    X = data['X']
    M = data['M']
    Ni = data['Ni']
    N = Ni.sum()

    S = X[:, 0: M]
    Is = X[:, 2*M:3*M]
    R = Ni - X[:, 0:M] - X[:, M:2*M] - X[:, 2*M:3*M]


    sumS = S.sum(axis=1)
    sumI = Is.sum(axis=1)
    sumR = R.sum(axis=1)

    plt.fill_between(t, 0, sumS/N, color="#348ABD", alpha=0.3)
    plt.plot(t, sumS/N, '-', color="#348ABD", label='$S$', lw=4)


    plt.fill_between(t, 0, sumI/N, color='#A60628', alpha=0.3)
    plt.plot(t, sumI/N, '-', color='#A60628', label='$I$', lw=4)

    plt.fill_between(t, 0, sumR/N, color="dimgrey", alpha=0.3)
    plt.plot(t, sumR/N, '-', color="dimgrey", label='$R$', lw=4)

    plt.legend(fontsize=26); plt.grid()
    plt.autoscale(enable=True, axis='x', tight=True)

    plt.ylabel('Fraction of compartment value')
    plt.xlabel('Days')

    if True != showPlot:
        pass
    else:
        plt.show()
