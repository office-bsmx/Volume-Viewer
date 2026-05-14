import json
import os
import sys

import nibabel as nib
import numpy as np
import nrrd


def _minmax_float01(vol: np.ndarray) -> np.ndarray:
    """Linearly scale volume to [0, 1] using global min/max (for JSON and Godot Image FORMAT_RF)."""
    lo, hi = float(vol.min()), float(vol.max())
    if hi <= lo:
        return np.zeros(vol.shape, dtype=np.float32)
    scaled = (vol.astype(np.float64, copy=False) - lo) / (hi - lo)
    return np.clip(scaled, 0.0, 1.0).astype(np.float32)


def _load_volume_3d(path: str) -> np.ndarray:
    """Load raw 3D volume: NRRD or anything nibabel can open (e.g. .nii, .nii.gz)."""
    lower = path.lower()
    if lower.endswith(".nrrd"):
        data, _header = nrrd.read(path)
    else:
        img = nib.load(path)
        data = np.asanyarray(img.dataobj)

    if np.iscomplexobj(data):
        data = np.real(data)
    data = np.asarray(data, dtype=np.float64)
    data = np.squeeze(data)
    if data.ndim == 4:
        data = data[..., 0]
    if data.ndim != 3:
        raise ValueError(
            f"Expected a 3D volume after squeeze (and optional 4th-axis drop); "
            f"got shape {data.shape}"
        )
    return data


def volume_to_json(
    input_path: str,
    output_json: str,
    downsample_factor: int = 1,
):
    """
    Write JSON with nested [z][y][x] floats in [0, 1] (for Godot ImageTexture3D FORMAT_RF).
    Supports .nrrd and nibabel-backed formats (e.g. .nii, .nii.gz).
    """
    if downsample_factor < 1:
        raise ValueError("downsample_factor must be >= 1")

    data = _load_volume_3d(input_path)

    if downsample_factor > 1:
        s = slice(None, None, downsample_factor)
        data = data[s, s, s]

    data = _minmax_float01(data)

    print(f"Output shape: {data.shape}, dtype={data.dtype}")

    payload = {"encoding": "float01", "volume": np.round(data.astype(np.float64, copy=False), 7).tolist()}
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(payload, f)

    size_mb = os.path.getsize(output_json) / (1024 * 1024)
    print(f"JSON written: {output_json} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    volume_to_json(
        sys.argv[1],
        f"./godot_project/volumes/{sys.argv[2] if len(sys.argv) > 2 else 'volume.json'}",
        downsample_factor=1,
    )
