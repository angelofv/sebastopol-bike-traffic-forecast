from __future__ import annotations

import os
from pathlib import Path

from kedro.config import OmegaConfigLoader
from kedro.io import DataCatalog
import mlflow
from omegaconf import OmegaConf

# Project root directory
_REPO_ROOT = Path(__file__).resolve().parent.parent


def _to_repo_path(path: str | Path) -> Path:
    """
    Convert a relative path to an absolute path anchored at the project root.
    If the provided path is already absolute, it is returned unchanged.
    """
    p = Path(path)
    return p if p.is_absolute() else _REPO_ROOT / p


def load_config(
    config_file: str | Path = "configs/params.yaml",
) -> dict:
    """
    Load a single YAML configuration file and return its contents
    as a native Python dictionary.
    """
    cfg_path = _to_repo_path(config_file)

    if not cfg_path.exists():
        raise FileNotFoundError(f"Configuration file not found: {cfg_path}")

    cfg = OmegaConf.load(cfg_path)
    return OmegaConf.to_container(cfg, resolve=True)


def load_catalog() -> DataCatalog:
    """
    Initialize and return a Kedro DataCatalog based on the
    YAML configurations in the 'configs' directory.
    """
    catalog_dir = _to_repo_path("configs")
    loader = OmegaConfigLoader(str(catalog_dir))
    raw_conf = loader.get("catalog")

    # Convert each dataset filepath to an absolute path
    fixed_conf: dict[str, dict] = {}
    for name, ds_conf in raw_conf.items():
        ds = dict(ds_conf)
        if "filepath" in ds:
            ds["filepath"] = str(_to_repo_path(ds["filepath"]))
        fixed_conf[name] = ds

    return DataCatalog.from_config(fixed_conf)


def init_mlflow(
    tracking_uri: str | None = None,
    experiment_name: str = "Default",
) -> None:
    if tracking_uri is None:
        tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "file:./mlruns")
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment(experiment_name)
