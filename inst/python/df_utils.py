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

import numpy as np


def _str_column(column: Any) -> Any:
    """Convert a string/object column to something reticulate maps to character.

    Elements become plain ``str`` (not ``np.str_`` or ``pathlib.Path``). An
    empty column becomes an empty numpy string array: an empty Python list
    would reach R as ``list()``, which ``as.data.frame()`` silently drops, so a
    result without detections would lose its ``input``/``species_name`` columns.
    """
    values = [str(v) for v in column.tolist()]
    return values if values else np.array([], dtype=str)


def encodings_to_dict(py_encodings: Any) -> dict[str, Any]:
    """Convert a birdnet encoding result to an R-friendly dict.

    Parameters
    ----------
    py_encodings
        A birdnet encoding result object (AcousticEncodingResultBase).

    Returns
    -------
    dict[str, Any]
        A dict mapping column names to numpy arrays or Python lists.
        The ``embedding`` column (2-d in the structured array) is
        converted to a list of lists so that reticulate maps it to an
        R list of numeric vectors.
    """
    structured = py_encodings.to_structured_array()
    result: dict[str, Any] = {}

    dtype_names = structured.dtype.names
    if dtype_names is None:
        return result

    for name in dtype_names:
        column = structured[name]
        if column.ndim > 1:
            # Multi-dimensional columns (e.g. embedding): materialize as
            # plain Python lists so reticulate converts element-wise.
            result[name] = column.tolist()
        elif column.dtype.kind in ("U", "O"):
            result[name] = _str_column(column)
        else:
            result[name] = column

    return result


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
            # Multi-dimensional columns: materialize as plain Python lists
            # so reticulate converts element-wise.
            result[name] = column.tolist()
        elif column.dtype.kind in ("U", "O"):
            # String / object dtypes: ensure every element is a plain str
            # (not np.str_ or pathlib.Path) so reticulate maps them to
            # R character vectors.
            result[name] = _str_column(column)
        else:
            result[name] = column

    return result


def official_model_rows() -> dict[str, list[str]]:
    """List birdnet's official model combinations as R-friendly columns.

    Reads the loader's own table (``birdnet.model_loader._OFFICIAL_MODELS``,
    keyed by ``(type, version, backend)``; each entry's ``backends`` dict is
    keyed by the supported precisions), so the list never drifts from what
    ``birdnet.load()`` accepts. The table is private: birdnetR's integration
    tests fail loudly if it disappears or changes shape.

    Returns
    -------
    dict[str, list[str]]
        Columns ``type``, ``version``, ``backend`` and ``precision``, one entry
        per model and precision.
    """
    from birdnet import model_loader

    table = getattr(model_loader, "_OFFICIAL_MODELS", None)
    if table is None:
        raise RuntimeError(
            "birdnetR cannot read the model list of this version of the birdnet "
            "Python package. Update birdnetR, or look the models up at "
            "https://birdnet-team.github.io/birdnet/models.html"
        )

    rows: dict[str, list[str]] = {
        "type": [],
        "version": [],
        "backend": [],
        "precision": [],
    }
    for (model_type, version, backend), spec in table.items():
        for precision in spec.backends:
            rows["type"].append(str(model_type))
            rows["version"].append(str(version))
            rows["backend"].append(str(backend))
            rows["precision"].append(str(precision))
    return rows
