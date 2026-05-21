"""Utility for converting birdnet prediction results to R-friendly dicts.

Bypasses pandas entirely to avoid Arrow-backed StringDtype issues with
reticulate.  Calls ``to_structured_array()`` directly and builds a plain
Python dict whose values are numpy arrays or Python lists — both of which
reticulate converts to R vectors correctly.

Background: On pandas >= 3.0 (where ``future.infer_string`` defaults to
``True``), ``pd.DataFrame()`` infers string columns as Arrow-backed
``StringDtype`` when pyarrow is installed.  Since birdnet requires pyarrow,
this always triggers.  reticulate cannot convert ``StringDtype`` Series to R
vectors, causing ``"names() applied to a non-vector"`` errors.

Tracking upstream fix: https://github.com/rstudio/reticulate/issues/1889
Once reticulate handles pandas ``StringDtype``, this module can be replaced
with a direct call to ``predictions.to_dataframe()``.
"""

from __future__ import annotations

from typing import Any


def predictions_to_dict(py_predictions: Any, **kwargs: Any) -> dict[str, Any]:
    """Convert a birdnet prediction result to an R-friendly dict.

    Parameters
    ----------
    py_predictions
        A birdnet prediction result object (acoustic or geo).
    **kwargs
        Forwarded to ``to_structured_array()`` (e.g. ``sort_by``).

    Returns
    -------
    dict[str, Any]
        A dict mapping column names to numpy arrays or Python lists.
        String columns are converted to ``list[str]`` via ``.tolist()``;
        numeric columns are kept as numpy arrays.
    """
    structured = py_predictions.to_structured_array(**kwargs)
    result: dict[str, Any] = {}

    dtype_names = structured.dtype.names
    if dtype_names is None:
        return result

    for name in dtype_names:
        column = structured[name]
        if column.ndim > 1:
            # Multi-dimensional columns: materialise as plain Python lists
            # so reticulate converts element-wise.
            result[name] = column.tolist()
        elif column.dtype.kind in ("U", "O"):
            # String / object dtypes: ensure every element is a plain str
            # (not np.str_ or pathlib.Path) so reticulate maps them to
            # R character vectors.
            result[name] = [str(v) for v in column.tolist()]
        else:
            result[name] = column

    return result
