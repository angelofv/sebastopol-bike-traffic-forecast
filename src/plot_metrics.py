import matplotlib.pyplot as plt
import mlflow
from prefect import flow, get_run_logger


@flow
def plot_metrics(
    model,
    df_clean,
    target: str,
) -> plt.Figure:
    logger = get_run_logger()
    logger.info("Plotting metrics")

    # TODO : Replace by your own plotting logic
    # Prédictions & accuracy
    X = df_clean.drop(columns=[target])
    y = df_clean[target]
    preds = model.predict(X)
    acc = (preds == y).mean()

    # Plot minimal
    fig, ax = plt.subplots()
    ax.bar(["accuracy"], [acc])
    ax.set_ylim(0, 1)
    ax.set_ylabel("score")
    fig.tight_layout()

    # Log de la figure
    mlflow.log_figure(fig, "plots/accuracy.png")
    return fig
