import cython
from cython import Py_ssize_t

import numbers

import numpy as np
cimport numpy as cnp
from numpy cimport ndarray, int64_t, uint8_t, float64_t
cnp.import_array()

cimport pandas._libs.util as util

from pandas._libs.tslibs.np_datetime cimport (
    get_timedelta64_value, get_datetime64_value)
from pandas._libs.tslibs.nattype cimport (
    checknull_with_nat, c_NaT as NaT, is_null_datetimelike)


cdef:
    float64_t INF = <float64_t>np.inf
    float64_t NEGINF = -INF

    int64_t NPY_NAT = util.get_nat()


cpdef bint checknull(object val):
    """
    Return boolean describing of the input is NA-like, defined here as any
    of:
     - None
     - nan
     - NaT
     - np.datetime64 representation of NaT
     - np.timedelta64 representation of NaT

    Parameters
    ----------
    val : object

    Returns
    -------
    result : bool

    Notes
    -----
    The difference between `checknull` and `checknull_old` is that `checknull`
    does *not* consider INF or NEGINF to be NA.
    """
    return val is C_NA or is_null_datetimelike(val, inat_is_null=False)


cpdef bint checknull_old(object val):
    """
    Return boolean describing of the input is NA-like, defined here as any
    of:
     - None
     - nan
     - INF
     - NEGINF
     - NaT
     - np.datetime64 representation of NaT
     - np.timedelta64 representation of NaT

    Parameters
    ----------
    val : object

    Returns
    -------
    result : bool

    Notes
    -----
    The difference between `checknull` and `checknull_old` is that `checknull`
    does *not* consider INF or NEGINF to be NA.
    """
    if checknull(val):
        return True
    elif util.is_float_object(val) or util.is_complex_object(val):
        return val == INF or val == NEGINF
    return False


cdef inline bint _check_none_nan_inf_neginf(object val):
    return val is None or (isinstance(val, float) and
                           (val != val or val == INF or val == NEGINF))


@cython.wraparound(False)
@cython.boundscheck(False)
cpdef ndarray[uint8_t] isnaobj(ndarray arr):
    """
    Return boolean mask denoting which elements of a 1-D array are na-like,
    according to the criteria defined in `checknull`:
     - None
     - nan
     - NaT
     - np.datetime64 representation of NaT
     - np.timedelta64 representation of NaT

    Parameters
    ----------
    arr : ndarray

    Returns
    -------
    result : ndarray (dtype=np.bool_)
    """
    cdef:
        Py_ssize_t i, n
        object val
        ndarray[uint8_t] result

    assert arr.ndim == 1, "'arr' must be 1-D."

    n = len(arr)
    result = np.empty(n, dtype=np.uint8)
    for i in range(n):
        val = arr[i]
        result[i] = checknull(val)
    return result.view(np.bool_)


@cython.wraparound(False)
@cython.boundscheck(False)
def isnaobj_old(arr: ndarray) -> ndarray:
    """
    Return boolean mask denoting which elements of a 1-D array are na-like,
    defined as being any of:
     - None
     - nan
     - INF
     - NEGINF
     - NaT

    Parameters
    ----------
    arr : ndarray

    Returns
    -------
    result : ndarray (dtype=np.bool_)
    """
    cdef:
        Py_ssize_t i, n
        object val
        ndarray[uint8_t] result

    assert arr.ndim == 1, "'arr' must be 1-D."

    n = len(arr)
    result = np.zeros(n, dtype=np.uint8)
    for i in range(n):
        val = arr[i]
        result[i] = val is NaT or _check_none_nan_inf_neginf(val)
    return result.view(np.bool_)


@cython.wraparound(False)
@cython.boundscheck(False)
def isnaobj2d(arr: ndarray) -> ndarray:
    """
    Return boolean mask denoting which elements of a 2-D array are na-like,
    according to the criteria defined in `checknull`:
     - None
     - nan
     - NaT
     - np.datetime64 representation of NaT
     - np.timedelta64 representation of NaT

    Parameters
    ----------
    arr : ndarray

    Returns
    -------
    result : ndarray (dtype=np.bool_)

    Notes
    -----
    The difference between `isnaobj2d` and `isnaobj2d_old` is that `isnaobj2d`
    does *not* consider INF or NEGINF to be NA.
    """
    cdef:
        Py_ssize_t i, j, n, m
        object val
        ndarray[uint8_t, ndim=2] result

    assert arr.ndim == 2, "'arr' must be 2-D."

    n, m = (<object>arr).shape
    result = np.zeros((n, m), dtype=np.uint8)
    for i in range(n):
        for j in range(m):
            val = arr[i, j]
            if checknull(val):
                result[i, j] = 1
    return result.view(np.bool_)


@cython.wraparound(False)
@cython.boundscheck(False)
def isnaobj2d_old(arr: ndarray) -> ndarray:
    """
    Return boolean mask denoting which elements of a 2-D array are na-like,
    according to the criteria defined in `checknull_old`:
     - None
     - nan
     - INF
     - NEGINF
     - NaT
     - np.datetime64 representation of NaT
     - np.timedelta64 representation of NaT

    Parameters
    ----------
    arr : ndarray

    Returns
    -------
    result : ndarray (dtype=np.bool_)

    Notes
    -----
    The difference between `isnaobj2d` and `isnaobj2d_old` is that `isnaobj2d`
    does *not* consider INF or NEGINF to be NA.
    """
    cdef:
        Py_ssize_t i, j, n, m
        object val
        ndarray[uint8_t, ndim=2] result

    assert arr.ndim == 2, "'arr' must be 2-D."

    n, m = (<object>arr).shape
    result = np.zeros((n, m), dtype=np.uint8)
    for i in range(n):
        for j in range(m):
            val = arr[i, j]
            if checknull_old(val):
                result[i, j] = 1
    return result.view(np.bool_)


def isposinf_scalar(val: object) -> bool:
    if util.is_float_object(val) and val == INF:
        return True
    else:
        return False


def isneginf_scalar(val: object) -> bool:
    if util.is_float_object(val) and val == NEGINF:
        return True
    else:
        return False


cdef inline bint is_null_datetime64(v):
    # determine if we have a null for a datetime (or integer versions),
    # excluding np.timedelta64('nat')
    if checknull_with_nat(v):
        return True
    elif util.is_datetime64_object(v):
        return get_datetime64_value(v) == NPY_NAT
    return False


cdef inline bint is_null_timedelta64(v):
    # determine if we have a null for a timedelta (or integer versions),
    # excluding np.datetime64('nat')
    if checknull_with_nat(v):
        return True
    elif util.is_timedelta64_object(v):
        return get_timedelta64_value(v) == NPY_NAT
    return False


cdef inline bint is_null_period(v):
    # determine if we have a null for a Period (or integer versions),
    # excluding np.datetime64('nat') and np.timedelta64('nat')
    return checknull_with_nat(v)


# -----------------------------------------------------------------------------
# Implementation of NA singleton


def _create_binary_propagating_op(name, divmod=False):

    def method(self, other):
        print("binop", other, type(other))
        if (other is C_NA or isinstance(other, str)
                or isinstance(other, (numbers.Number, np.bool_, np.int64, np.int_))
                or isinstance(other, np.ndarray) and not other.shape):
            if divmod:
                return NA, NA
            else:
                return NA

        elif isinstance(other, np.ndarray):
            out = np.empty(other.shape, dtype=object)
            out[:] = NA

            if divmod:
                return out, out.copy()
            else:
                return out

        return NotImplemented

    method.__name__ = name
    return method


def _create_unary_propagating_op(name):
    def method(self):
        return NA

    method.__name__ = name
    return method


def maybe_dispatch_ufunc_to_dunder_op(
    object self, object ufunc, str method, *inputs, **kwargs
):
    """
    Dispatch a ufunc to the equivalent dunder method.

    Parameters
    ----------
    self : ArrayLike
        The array whose dunder method we dispatch to
    ufunc : Callable
        A NumPy ufunc
    method : {'reduce', 'accumulate', 'reduceat', 'outer', 'at', '__call__'}
    inputs : ArrayLike
        The input arrays.
    kwargs : Any
        The additional keyword arguments, e.g. ``out``.

    Returns
    -------
    result : Any
        The result of applying the ufunc
    """
    # special has the ufuncs we dispatch to the dunder op on
    special = {
        "add",
        "sub",
        "mul",
        "pow",
        "mod",
        "floordiv",
        "truediv",
        "divmod",
        "eq",
        "ne",
        "lt",
        "gt",
        "le",
        "ge",
        "remainder",
        "matmul",
        "or",
        "xor",
        "and",
    }
    aliases = {
        "subtract": "sub",
        "multiply": "mul",
        "floor_divide": "floordiv",
        "true_divide": "truediv",
        "power": "pow",
        "remainder": "mod",
        "divide": "div",
        "equal": "eq",
        "not_equal": "ne",
        "less": "lt",
        "less_equal": "le",
        "greater": "gt",
        "greater_equal": "ge",
        "bitwise_or": "or",
        "bitwise_and": "and",
        "bitwise_xor": "xor",
    }

    # For op(., Array) -> Array.__r{op}__
    flipped = {
        "lt": "__gt__",
        "le": "__ge__",
        "gt": "__lt__",
        "ge": "__le__",
        "eq": "__eq__",
        "ne": "__ne__",
    }

    op_name = ufunc.__name__
    op_name = aliases.get(op_name, op_name)

    def not_implemented(*args, **kwargs):
        return NotImplemented

    if method == "__call__" and op_name in special and kwargs.get("out") is None:
        if isinstance(inputs[0], type(self)):
            name = "__{}__".format(op_name)
            return getattr(self, name, not_implemented)(inputs[1])
        else:
            name = flipped.get(op_name, "__r{}__".format(op_name))
            result =  getattr(self, name, not_implemented)(inputs[0])
            return result
    else:
        return NotImplemented


cdef class C_NAType:
    pass


class NAType(C_NAType):
    """
    NA ("not available") missing value indicator.

    .. warning::

       Experimental: the behaviour of NA can still change without warning.

    .. versionadded:: 1.0.0

    The NA singleton is a missing value indicator defined by pandas. It is
    used in certain new extension dtypes (currently the "string" dtype).
    """

    _instance = None

    def __new__(cls, *args, **kwargs):
        if NAType._instance is None:
            NAType._instance = C_NAType.__new__(cls, *args, **kwargs)
        return NAType._instance

    def __repr__(self) -> str:
        return "NA"

    def __str__(self) -> str:
        return "NA"

    def __bool__(self):
        raise TypeError("boolean value of NA is ambiguous")

    def __hash__(self):
        return id(self)

    # Binary arithmetic and comparison ops -> propagate

    __add__ = _create_binary_propagating_op("__add__")
    __radd__ = _create_binary_propagating_op("__radd__")
    __sub__ = _create_binary_propagating_op("__sub__")
    __rsub__ = _create_binary_propagating_op("__rsub__")
    __mul__ = _create_binary_propagating_op("__mul__")
    __rmul__ = _create_binary_propagating_op("__rmul__")
    __matmul__ = _create_binary_propagating_op("__matmul__")
    __rmatmul__ = _create_binary_propagating_op("__rmatmul__")
    __truediv__ = _create_binary_propagating_op("__truediv__")
    __rtruediv__ = _create_binary_propagating_op("__rtruediv__")
    __floordiv__ = _create_binary_propagating_op("__floordiv__")
    __rfloordiv__ = _create_binary_propagating_op("__rfloordiv__")
    __mod__ = _create_binary_propagating_op("__mod__")
    __rmod__ = _create_binary_propagating_op("__rmod__")
    __divmod__ = _create_binary_propagating_op("__divmod__", divmod=True)
    __rdivmod__ = _create_binary_propagating_op("__rdivmod__", divmod=True)
    # __lshift__ and __rshift__ are not implemented

    __eq__ = _create_binary_propagating_op("__eq__")
    __ne__ = _create_binary_propagating_op("__ne__")
    __le__ = _create_binary_propagating_op("__le__")
    __lt__ = _create_binary_propagating_op("__lt__")
    __gt__ = _create_binary_propagating_op("__gt__")
    __ge__ = _create_binary_propagating_op("__ge__")

    # Unary ops

    __neg__ = _create_unary_propagating_op("__neg__")
    __pos__ = _create_unary_propagating_op("__pos__")
    __abs__ = _create_unary_propagating_op("__abs__")
    __invert__ = _create_unary_propagating_op("__invert__")

    # pow has special
    def __pow__(self, other):
        if other is C_NA:
            return NA
        elif isinstance(other, (numbers.Number, np.bool_)):
            if other == 0:
                # returning positive is correct for +/- 0.
                return type(other)(1)
            else:
                return NA
        elif isinstance(other, np.ndarray):
            return np.where(other == 0, other.dtype.type(1), NA)

        return NotImplemented

    def __rpow__(self, other):
        if other is C_NA:
            return NA
        elif isinstance(other, (numbers.Number, np.bool_)):
            if other == 1 or other == -1:
                return other
            else:
                return NA
        elif isinstance(other, np.ndarray):
            return np.where((other == 1) | (other == -1), other, NA)

        return NotImplemented

    # Logical ops using Kleene logic

    def __and__(self, other):
        if other is False:
            return False
        elif other is True or other is C_NA:
            return NA
        else:
            return NotImplemented

    __rand__ = __and__

    def __or__(self, other):
        if other is True:
            return True
        elif other is False or other is C_NA:
            return NA
        else:
            return NotImplemented

    __ror__ = __or__

    def __xor__(self, other):
        if other is False or other is True or other is C_NA:
            return NA
        return NotImplemented

    __rxor__ = __xor__

    # What else to add here? datetime / Timestamp? Period? Interval?
    # Note: we only handle 0-d ndarrays.
    __array_priority__ = 1000
    _HANDLED_TYPES = (np.ndarray, numbers.Number, str, np.bool_, np.int64)

    def __array_ufunc__(self, ufunc, method, *inputs, **kwargs):
        types = self._HANDLED_TYPES + (NAType,)
        print('array_ufunc', 'inputs', inputs)
        for x in inputs:
            if not isinstance(x, types):
                print('defer', x)
                return NotImplemented

        if method != "__call__":
            raise ValueError(f"ufunc method '{method}' not supported for NA")
        result = maybe_dispatch_ufunc_to_dunder_op(self, ufunc, method, *inputs, **kwargs)
        print("dispatch result", result)
        if result is NotImplemented:
            # TODO: this is wrong for binary, ternary ufuncs. Should handle shape stuff.
            if ufunc.nout == 1:
                result = NA
            else:
                result = (NA,) * ufunc.nout

        return result


C_NA = NAType()   # C-visible
NA = C_NA         # Python-visible
