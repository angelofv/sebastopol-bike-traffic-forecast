from src.train import train_model


def test_train_model_task_is_callable() -> None:
    assert callable(train_model), "train_model n’est pas appelable"
