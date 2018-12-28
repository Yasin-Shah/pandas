import pytest

import pandas.util.testing as tm


@pytest.mark.filterwarnings(
    "error::pandas.errors.ExtensionArrayCastingWarning"
)
class BaseExtensionTests(object):
    assert_equal = staticmethod(tm.assert_equal)
    assert_series_equal = staticmethod(tm.assert_series_equal)
    assert_frame_equal = staticmethod(tm.assert_frame_equal)
    assert_extension_array_equal = staticmethod(
        tm.assert_extension_array_equal
    )
