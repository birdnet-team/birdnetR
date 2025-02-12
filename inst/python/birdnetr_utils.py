try:
    from collections import OrderedDict

    import pyarrow as pa
    import pyarrow.compute as pc
    from birdnet.types import SpeciesPredictions
except ModuleNotFoundError as e:
    raise RuntimeError(f"Failed to import required modules: {str(e)}")


def convert_species_predictions_to_arrow_table(
    nested_od: OrderedDict, keep_empty: bool = True
) -> pa.Table:
    """
    Convert a nested OrderedDict of species predictions to a flattened Apache Arrow Table.
    Each species prediction gets its own row, with scientific and common names split.

    Args:
        nested_od: OrderedDict with structure ((start, end), OrderedDict[(species_name, confidence)])
        keep_empty: Whether to include empty predictions in the output

    Returns:
        pa.Table with columns:
            - start (float64): Start time of the interval
            - end (float64): End time of the interval
            - scientific_name (string): Scientific name of the species
            - common_name (string): Common name of the species
            - confidence (float64): Confidence score
    """
    starts = []
    ends = []
    species = []
    confidences = []

    for (start, end), inner_od in nested_od.items():
        if len(inner_od) == 0:
            if keep_empty:
                # For empty predictions, add a row with null values
                starts.append(start)
                ends.append(end)
                species.append(None)
                confidences.append(None)
        else:
            # Add a row for each species prediction
            for species_name, confidence in inner_od.items():
                starts.append(start)
                ends.append(end)
                species.append(species_name)
                confidences.append(confidence)

    # Create initial arrow table
    data = {
        "start": pa.array(starts, type=pa.float64()),
        "end": pa.array(ends, type=pa.float64()),
        "species": pa.array(species, type=pa.string()),
        "confidence": pa.array(confidences, type=pa.float64()),
    }

    table = pa.Table.from_pydict(data)

    # Split species column into scientific_name and common_name using Arrow compute functions
    if len(table) > 0:
        # Split on underscore
        split_result = pc.split_pattern(table["species"], "_")
        # Extract scientific and common names
        scientific_names = pc.list_element(split_result, 0)
        common_names = pc.list_element(split_result, 1)

        # Create new table with split columns
        table = table.append_column("scientific_name", scientific_names)
        table = table.append_column("common_name", common_names)
        table = table.remove_column(table.schema.get_field_index("species"))

        # Reorder columns
        table = table.select(
            ["start", "end", "scientific_name", "common_name", "confidence"]
        )

    return table


def process_predictions_to_arrow_table(
    predictions_gen, keep_empty: bool = True
) -> pa.Table:
    """
    Process a predictions generator directly into an Arrow table.
    This combines the SpeciesPredictions creation and table conversion into a single step,
    reducing data transfers between R and Python.

    Args:
        predictions_gen: Generator of predictions from BirdNET
        keep_empty: Whether to include empty predictions in the output

    Returns:
        pa.Table with columns:
            - start (float64): Start time of the interval
            - end (float64): End time of the interval
            - scientific_name (string): Scientific name of the species
            - common_name (string): Common name of the species
            - confidence (float64): Confidence score

    Raises:
        RuntimeError: If there's an error processing the predictions or creating the Arrow table
    """
    try:
        predictions = SpeciesPredictions(predictions_gen)
        return convert_species_predictions_to_arrow_table(predictions, keep_empty)

    except Exception as e:
        raise RuntimeError(f"Error processing predictions: {str(e)}") from e
