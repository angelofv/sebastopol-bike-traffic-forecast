from src.extract import load_raw_data, preprocess


def test_preprocessing_tasks_are_callable() -> None:
    for task in (load_raw_data, preprocess):
        assert callable(task), f"{task.__name__} n’est pas appelable"
