# Godot Engine 4 Volume Viewer
![Screenshot](https://github.com/office-bsmx/Volume-Viewer/blob/main/screenshot.png?raw=true)

This project is an **adaptation** of the [Three.js webgl_texture3d example](https://threejs.org/examples/webgl_texture3d.html) for [Godot Engine 4](https://godotengine.org/): export **NRRD** (`.nrrd`) or **NIfTI** (`.nii`, `.nii.gz`) volumes to JSON, then view them with a 3D texture and volume-style shader.

## Export

```bash
pip install -r requirements.txt
python main.py path/to/volume.nrrd output_name.json
```

The file is written to `godot_project/volumes/<output_name.json>`. If you omit the second argument, it defaults to `volume.json`.

Other formats supported by [NiBabel](https://nipy.org/nibabel/) can be passed as the first argument; **`.nrrd`** is handled via **pynrrd**.

## Run in Godot

Open the **`godot_project`** folder in Godot **4.x**, select the **`volume_mesh`** node, set **`volume_json_path`** in the Inspector to your exported JSON, and run the main scene.

## Requirements

See [requirements.txt](requirements.txt): **numpy**, **nibabel**, **pynrrd**.
