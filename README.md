# Reproduce note

## data processing.

### test

```
blenderproc run blender_render.py     --data_dir ./mobility_dataset     --out_dir ./real2code_dataset_v0        --folder "47645"    --custom-blender-path ~/blender_download/blender-3.3.1-linux-x64/ --haven_path ./
```

```
xvfb-run python preprocess_data.py  --num_augs 3 --obj_type Box --data_dir ./real2code_dataset_v0 --shard_output_dir ./real2code_shards_v0
```

missing the reder of pointcloud. 
find the code in `shape_complete/datagen.py` and sucessifully debug and run it through. the generated data is shown as below photo.


### Loop

```
for FOLDER in 19855 20985 22241 22301 22433 25493 26387 26652; do blenderproc run blender_render.py  --data_dir ./mobility_dataset   --out_dir ./real2code_dataset_v0   --folder ${FOLDER}  --custom-blender-path ~/blender_download/blender-3.3.1-linux-x64/ --haven_path ./ -o; done

xvfb-run python preprocess_data.py  --num_augs 3 --obj_type Box --data_dir ./real2code_dataset_v0 --shard_output_dir ./real2code_shards_v0
```

## SAM fine-tuning.
missing the code of sam fine-tuning, which should be included in `image_seg/`


## Shape completion model training.

based on the generated data from datagen.py, we train the shape completion model with `./shape_complete/train.p`

with 4090s, 5000 eopchs, trining time around 16hours. the testing result is shown as below:

<img src="./shape_completion_testing\ _sample.jpg " alt="Shape Completion Testing Sample" width="800"/>


## LLM fine-tuning.

the author fork the Codellama and commit to provided more information further.

# Real2code: Reconstruct Articulated Objects via Code Generation
**[Mandi Zhao](https://mandizhao.github.io/), [Yijia Weng](https://yijiaweng.github.io/), [Dominik Bauer](https://dornik.github.io/), [Shuran Song](https://shurans.github.io/)**

[Arxiv](https://arxiv.org/abs/2406.08474) | [Website](https://real2code.github.io/)

<img src="real2code-teaser-pic.jpg" alt="teaser" width="800"/>

## Installation
Use conda environment with Python 3.9, and install packages from the provided `.yaml` file
```
conda create -n real2code python=3.9
conda activate real2code
conda env update --file environment.yml --prune
```


## Code Overview
### Data Generation & Processing  
1. Download the pre-processed version of PartNet-Mobility data from [UMPNet](https://github.com/real-stanford/umpnet) and from the [Sapien official website](https://sapien.ucsd.edu/browse) (this website has web-based interactive visualization for the objects). 
Note that the objects were manually inspected and de-duplicated: for Eyeglasses category, 11 objects from the original site was removed, and results in 54 objects in total, from which we selected 5 test objects.

2. Use `blender_render.py` to process and render RGBD images from [PartNet-Mobility](https://sapien.ucsd.edu/browse) data. 
  - If you see error `xcb_connection_has_error() returned true`, try unsetting `DISPLAY` variable (e.g. `export DISPLAY=`).

3. Use `preprocess_data.py` to generate OBB-relative MJCF code data from the raw URDFs for LLM fine-tuning.  

See `data_utils/` for detailed implementations of the helper functions. 

### Kinematics-Aware SAM Fine-tuning 
See `image_seg/`
Example commands to start fine-tuning:
```
cd image_seg 
DATADIR=xxx # your data path
python tune_sam.py --blender --run_name sam_v2 --wandb --data_dir $DATADIR --points --prompts_per_mask 16 --lr 1e-3 --wandb --fc_weight 1
```

### Shape Completion 
See `shape_complete/`, we use Blender-rendered RGBD images to generate partially-observable point clouds inputs; `kaolin` for processing ground-truth mesh to generate occupancy label grids. 

### LLM fine-tuning
We use a custom fork of Open-Flamingo: https://github.com/mlfoundations/open_flamingo. More details avaliable soon.

### Real World Evaluation
See `real_obj/`. We use [DUSt3R](https://github.com/naver/dust3r) to achieve reconstruction from multi-view pose-free RGB images, the DUSt3R-generated 3D pointmaps are provided in the real world dataset below. 

## Dataset 
### Synthetic Data
Our dataset is built on top of PartNet-Mobilty assets, and the same set of objects are used for training and testing throughout our SAM fine-tuning, shape completion model training, and LLM fine-tuning modules. The full dataset will be released here: https://drive.google.com/drive/folders/1rkUP7NBRQX5h6ixJr9SvX0Vh3fhj1YqO?usp=drive_link 

### Real-world Objects
We have released the real objects data used for evaluating Real2Code. These are objects found in the common lab/household settings around Stanford campus. Raw data is captured using a LiDAR-equipped iPhone camera and the [3dScanner App](https://apps.apple.com/us/app/3d-scanner-app/id1419913995)
- Download: [Google Drive Link](https://drive.google.com/drive/folders/1LSjpatlAzTXxOUcwbGjZR_ST7aeUEjn2?usp=drive_link)
- Structure: each object folder is structured as follows:
  ```
  ls obj_id/
  - raw/
  - sam/
  - a list of (id.jpg, id_mask.png, id_scene.npz),
  ```
  Each `id` corresponds to one 512x512 RGB image selected from the raw dataset, e.g. `00000.jpg`; `id_mask.png` is the foreground object mask obtained from prompting the SAM model with randomly sampled query points in the image margin area; `id_scene.npz` is the globally-aligned 3D point-cloud obtained from [DUSt3R](https://github.com/naver/dust3r). 

