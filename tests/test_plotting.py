from src.plot_metrics import plot_metrics


def test_plot_metrics_task_is_callable() -> None:
    assert callable(plot_metrics), "plot_metrics n’est pas appelable"
