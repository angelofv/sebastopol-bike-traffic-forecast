import mlflow
from prefect import flow, get_run_logger

from src.config import init_mlflow, load_catalog, load_config
from src.extract import load_raw_data, preprocess
from src.plot_metrics import plot_metrics
from src.train import train_model


@flow(name="ML Pipeline")
def run():
    logger = get_run_logger()
    logger.info("Load config and catalog")

    # 1) Chargement des configs et du catalog
    cfg = load_config()
    catalog = load_catalog()

    # Setup MLflow
    init_mlflow()

    with mlflow.start_run():
        # 2) Extraction
        df_raw = load_raw_data()
        catalog.save("raw_data", df_raw)

        # 3) Prétraitement
        df_clean = preprocess(
            df_raw,
            dropna_columns=cfg["preprocessing"]["dropna_columns"],
        )
        catalog.save("processed_data", df_clean)

        # 4) Entraînement
        model = train_model(
            df_clean,
            n_estimators=cfg["modeling"]["n_estimators"],
            target=cfg["modeling"]["target"],
        )
        catalog.save("model", model)

        # 5) Reporting
        fig = plot_metrics(
            model,
            df_clean,
            target=cfg["plotting"]["target"],
        )
        catalog.save("accuracy_plot", fig)

        logger.info("Pipeline completed successfully")


if __name__ == "__main__":
    run()
